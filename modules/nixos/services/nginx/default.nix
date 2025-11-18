{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types mapAttrsToList mapAttrs mapAttrs' nameValuePair optionalString optionalAttrs;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.nginx;

  # Submodule type for defining reverse proxy services
  proxyServiceType = types.submodule {
    options = {
      backend = mkOpt types.str "" "Backend URL (e.g., http://localhost:8096)";
      domain = mkOpt (types.nullOr types.str) null "Domain name for this service (e.g., jellyfin.example.com)";
      subdomain = mkOpt (types.nullOr types.str) null "Subdomain to use with baseDomain (e.g., 'jellyfin' -> jellyfin.example.com)";
      enableSSL = mkBoolOpt true "Enable SSL/TLS for this service";
      forceSSL = mkBoolOpt true "Force HTTPS by redirecting HTTP to HTTPS";
      enableACME = mkBoolOpt true "Use Let's Encrypt ACME certificates";
      sslCertificate = mkOpt (types.nullOr types.path) null "Path to SSL certificate (if not using ACME)";
      sslCertificateKey = mkOpt (types.nullOr types.path) null "Path to SSL certificate key (if not using ACME)";
      enableBasicAuth = mkBoolOpt false "Enable HTTP basic authentication";
      basicAuthFile = mkOpt (types.nullOpt types.path) null "Path to htpasswd file for basic authentication";
      allowedIPs = mkOpt (types.listOf types.str) [ ] "List of IP addresses/ranges to allow (empty = allow all)";
      deniedIPs = mkOpt (types.listOf types.str) [ ] "List of IP addresses/ranges to deny";
      enableWebSocket = mkBoolOpt false "Enable WebSocket support for this service";
      clientMaxBodySize = mkOpt types.str "100M" "Maximum upload size (e.g., '100M', '1G')";
      proxyTimeout = mkOpt types.int 60 "Proxy timeout in seconds";
      customHeaders = mkOpt (types.attrsOf types.str) { } "Custom HTTP headers to add";
      locations = mkOpt
        (types.attrsOf (types.submodule {
          options = {
            proxyPass = mkOpt (types.nullOr types.str) null "Proxy pass URL for this location";
            extraConfig = mkOpt types.lines "" "Extra nginx configuration for this location";
            priority = mkOpt types.int 1000 "Location priority (lower = higher priority)";
          };
        }))
        { } "Additional location blocks for this service";
      extraConfig = mkOpt types.lines "" "Additional nginx configuration for this virtual host";
      enableRatelimit = mkBoolOpt false "Enable rate limiting for this service";
      ratelimitZone = mkOpt types.str "default" "Rate limit zone name";
      ratelimitRate = mkOpt types.str "10r/s" "Rate limit (e.g., '10r/s', '100r/m')";
    };
  };

  # Submodule for upstream configuration
  upstreamType = types.submodule {
    options = {
      servers = mkOpt (types.listOf types.str) [ ] "List of upstream servers (e.g., 'localhost:8080')";

      extraConfig = mkOpt types.lines "" "Additional upstream configuration";

      strategy = mkOpt (types.enum [ "round_robin" "least_conn" "ip_hash" "hash" ]) "round_robin" "Load balancing strategy";

      hashKey = mkOpt (types.nullOr types.str) null "Hash key for 'hash' strategy (e.g., '$request_uri')";
    };
  };

  # Generate nginx virtual host configuration
  mkVirtualHost = name: svcCfg:
    let
      hostname =
        if svcCfg.domain != null then
          svcCfg.domain
        else if svcCfg.subdomain != null then
          "${svcCfg.subdomain}.${cfg.baseDomain}"
        else
          throw "Service ${name} must specify either domain or subdomain";

      # Build location blocks
      mkLocation = path: locCfg:
        optionalAttrs (locCfg.proxyPass != null || locCfg.extraConfig != "") {
          proxyPass = locCfg.proxyPass;
          extraConfig = locCfg.extraConfig;
          priority = locCfg.priority;
        };

      locations = (mapAttrs mkLocation svcCfg.locations) // {
        "/" = {
          proxyPass = svcCfg.backend;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Port $server_port;

            ${optionalString svcCfg.enableWebSocket ''
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            ''}

            proxy_connect_timeout ${toString svcCfg.proxyTimeout}s;
            proxy_send_timeout ${toString svcCfg.proxyTimeout}s;
            proxy_read_timeout ${toString svcCfg.proxyTimeout}s;

            client_max_body_size ${svcCfg.clientMaxBodySize};

            ${lib.concatStringsSep "\n" (mapAttrsToList (k: v: "add_header ${k} \"${v}\";") svcCfg.customHeaders)}

            ${optionalString (svcCfg.allowedIPs != [ ]) ''
              ${lib.concatStringsSep "\n" (map (ip: "allow ${ip};") svcCfg.allowedIPs)}
              deny all;
            ''}

            ${optionalString (svcCfg.deniedIPs != [ ]) ''
              ${lib.concatStringsSep "\n" (map (ip: "deny ${ip};") svcCfg.deniedIPs)}
            ''}

            ${optionalString svcCfg.enableRatelimit ''
              limit_req zone=${svcCfg.ratelimitZone} burst=20 nodelay;
            ''}
          '';
        };
      };
    in
    {
      inherit locations;

      serverName = hostname;

      enableSSL = svcCfg.enableSSL;
      forceSSL = svcCfg.forceSSL;
      enableACME = svcCfg.enableACME && svcCfg.enableSSL;

      sslCertificate = if svcCfg.sslCertificate != null then svcCfg.sslCertificate else null;
      sslCertificateKey = if svcCfg.sslCertificateKey != null then svcCfg.sslCertificateKey else null;

      basicAuthFile = if svcCfg.enableBasicAuth then svcCfg.basicAuthFile else null;

      extraConfig = svcCfg.extraConfig;

      kTLS = cfg.enableKTLS;
    };

  # Build virtual hosts from proxiedServices
  mkVirtualHosts = mapAttrs'
    (name: svcCfg:
      nameValuePair
        (if svcCfg.domain != null then svcCfg.domain
        else "${svcCfg.subdomain}.${cfg.baseDomain}")
        (mkVirtualHost name svcCfg)
    )
    cfg.proxiedServices;

  # Build upstream blocks
  mkUpstream = name: upstreamCfg:
    let
      strategyDirective =
        if upstreamCfg.strategy == "least_conn" then "least_conn;"
        else if upstreamCfg.strategy == "ip_hash" then "ip_hash;"
        else if upstreamCfg.strategy == "hash" then "hash ${upstreamCfg.hashKey};"
        else ""; # round_robin is default, no directive needed
    in
    ''
      upstream ${name} {
        ${strategyDirective}
        ${lib.concatStringsSep "\n" (map (server: "server ${server};") upstreamCfg.servers)}
        ${upstreamCfg.extraConfig}
      }
    '';

  # Rate limit zones
  mkRateLimitZone = name: rate: ''
    limit_req_zone $binary_remote_addr zone=${name}:10m rate=${rate};
  '';
in
{
  options.${namespace}.services.nginx = {
    enable = mkBoolOpt false "Enable nginx reverse proxy and web server";

    email = mkOpt (types.nullOr types.str) null "Email address for ACME account (required for Let's Encrypt)";

    baseDomain = mkOpt (types.nullOr types.str) null "Base domain for services using subdomain option (e.g., example.com)";

    proxiedServices = mkOpt (types.attrsOf proxyServiceType) { } ''
      Attribute set of services to reverse proxy.

      Example:
        proxiedServices = {
          jellyfin = {
            backend = "http://localhost:8096";
            subdomain = "jellyfin";
            enableWebSocket = true;
          };
          nextcloud = {
            backend = "http://localhost:8080";
            domain = "cloud.example.com";
            clientMaxBodySize = "10G";
          };
        };
    '';

    upstreams = mkOpt (types.attrsOf upstreamType) { } ''
      Upstream server groups for load balancing.

      Example:
        upstreams = {
          backend_pool = {
            servers = [ "localhost:8080" "localhost:8081" ];
            strategy = "least_conn";
          };
        };
    '';

    rateLimitZones = mkOpt (types.attrsOf types.str)
      {
        default = "10r/s";
      } "Rate limit zones and their rates";

    enableKTLS = mkBoolOpt false "Enable kernel TLS offloading (requires kernel 4.13+)";

    enableHTTP2 = mkBoolOpt true "Enable HTTP/2 support";

    enableHTTP3 = mkBoolOpt false "Enable HTTP/3 (QUIC) support";

    recommendedSettings = mkBoolOpt true "Enable recommended security and performance settings";

    extraHttpConfig = mkOpt types.lines "" "Additional http block configuration";

    extraVirtualHosts = mkOpt
      (types.attrsOf (types.submodule {
        options = {
          root = mkOpt (types.nullOr types.path) null "Document root directory";
          locations = mkOpt (types.attrsOf types.attrs) { } "Location blocks";
          enableSSL = mkBoolOpt false "Enable SSL";
          enableACME = mkBoolOpt false "Enable ACME certificates";
          extraConfig = mkOpt types.lines "" "Extra configuration";
        };
      }))
      { } "Additional virtual hosts not defined in proxiedServices";

    package = mkOpt types.package pkgs.nginx "nginx package to use";
  };

  config = mkIf cfg.enable {
    services.nginx = {
      enable = true;
      package = cfg.package;

      recommendedGzipSettings = cfg.recommendedSettings;
      recommendedOptimisation = cfg.recommendedSettings;
      recommendedProxySettings = cfg.recommendedSettings;
      recommendedTlsSettings = cfg.recommendedSettings;

      enableReload = true;

      virtualHosts = mkVirtualHosts // (mapAttrs
        (name: vhostCfg: {
          inherit (vhostCfg) root locations enableSSL enableACME extraConfig;
        })
        cfg.extraVirtualHosts);

      appendHttpConfig = ''
        ${optionalString cfg.enableHTTP2 "http2 on;"}
        ${optionalString cfg.enableHTTP3 "http3 on;"}

        # Rate limiting zones
        ${lib.concatStringsSep "\n" (mapAttrsToList mkRateLimitZone cfg.rateLimitZones)}

        ${cfg.extraHttpConfig}
      '';

      appendConfig = ''
        # Upstream definitions
        ${lib.concatStringsSep "\n" (mapAttrsToList mkUpstream cfg.upstreams)}
      '';
    };

    # ACME configuration
    security.acme = mkIf (cfg.email != null) {
      acceptTerms = true;
      defaults.email = cfg.email;
    };

    # Open firewall ports
    networking.firewall = {
      allowedTCPPorts = [ 80 443 ];
      allowedUDPPorts = lib.optionals cfg.enableHTTP3 [ 443 ]; # QUIC uses UDP
    };

    # Assertions
    assertions = [
      {
        assertion = (builtins.any (svc: svc.enableACME) (builtins.attrValues cfg.proxiedServices)) -> cfg.email != null;
        message = "nginx: email must be set when using ACME certificates";
      }
      {
        assertion = cfg.baseDomain != null || (builtins.all (svc: svc.domain != null) (builtins.attrValues cfg.proxiedServices));
        message = "nginx: baseDomain must be set when using subdomain option in proxiedServices";
      }
      {
        assertion = builtins.all
          (svc: svc.enableBasicAuth -> svc.basicAuthFile != null)
          (builtins.attrValues cfg.proxiedServices);
        message = "nginx: basicAuthFile must be set when enableBasicAuth is true";
      }
    ];
  };
}
