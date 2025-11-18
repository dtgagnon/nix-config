{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types mapAttrs' nameValuePair concatStringsSep optionalString;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.caddy;

  # Submodule type for defining reverse proxy services
  proxyServiceType = types.submodule {
    options = {
      backend = mkOpt types.str "" "Backend URL (e.g., http://localhost:8096)";

      domain = mkOpt (types.nullOr types.str) null "Domain name for this service (e.g., jellyfin.example.com)";

      useTailscale = mkBoolOpt false "Use Tailscale HTTPS certificates and hostname (e.g., jellyfin.tailnet-name.ts.net)";

      tailscaleHostname = mkOpt (types.nullOr types.str) null "Tailscale hostname (if different from service name). If null, uses the service name.";

      subdomain = mkOpt (types.nullOr types.str) null "Subdomain to use with baseDomain (e.g., 'jellyfin' -> jellyfin.example.com)";

      extraConfig = mkOpt types.lines "" "Additional Caddy configuration for this service";

      enableBasicAuth = mkBoolOpt false "Enable HTTP basic authentication (requires users to be defined)";

      allowedIPs = mkOpt (types.listOf types.str) [] "List of IP addresses/ranges to allow (empty = allow all)";
    };
  };

  # Generate Caddyfile configuration for a service
  mkServiceConfig = name: svcCfg:
    let
      # Determine the hostname to use
      hostname =
        if svcCfg.useTailscale then
          if svcCfg.tailscaleHostname != null then
            svcCfg.tailscaleHostname
          else
            "${name}.${cfg.tailnetName}.ts.net"
        else if svcCfg.domain != null then
          svcCfg.domain
        else if svcCfg.subdomain != null then
          "${svcCfg.subdomain}.${cfg.baseDomain}"
        else
          throw "Service ${name} must specify either domain, subdomain, or useTailscale";

      # Build auth/security directives
      securityDirectives = concatStringsSep "\n" (
        (lib.optional (svcCfg.enableBasicAuth && cfg.basicAuthUsers != {})
          "basicauth {\n${concatStringsSep "\n" (lib.mapAttrsToList (user: hash: "  ${user} ${hash}") cfg.basicAuthUsers)}\n}")
        ++ (lib.optional (svcCfg.allowedIPs != [])
          "@allowed_ips remote_ip ${concatStringsSep " " svcCfg.allowedIPs}\nhandle @allowed_ips {\n  reverse_proxy ${svcCfg.backend}\n}\nhandle {\n  abort\n}")
      );

      # Main reverse proxy directive (if no IP restrictions)
      proxyDirective = optionalString (svcCfg.allowedIPs == []) ''
        reverse_proxy ${svcCfg.backend}
      '';
    in
    ''
      ${hostname} {
        encode gzip
        ${securityDirectives}
        ${proxyDirective}
        ${svcCfg.extraConfig}
      }
    '';

  # Build virtualHosts from proxiedServices
  mkVirtualHosts = mapAttrs' (name: svcCfg:
    nameValuePair
      (if svcCfg.domain != null then svcCfg.domain
       else if svcCfg.subdomain != null then "${svcCfg.subdomain}.${cfg.baseDomain}"
       else "${name}.${cfg.tailnetName}.ts.net")
      { extraConfig = mkServiceConfig name svcCfg; }
  ) cfg.proxiedServices;
in
{
  options.${namespace}.services.caddy = {
    enable = mkBoolOpt false "Enable Caddy reverse proxy server";

    email = mkOpt (types.nullOr types.str) null "Email address for ACME account (highly recommended for Let's Encrypt)";

    baseDomain = mkOpt (types.nullOr types.str) null "Base domain for services using subdomain option (e.g., example.com)";

    tailnetName = mkOpt types.str "tailnet" "Your Tailscale tailnet name (without .ts.net suffix)";

    useTailscaleGlobally = mkBoolOpt false "Use Tailscale HTTPS for all services by default";

    proxiedServices = mkOpt (types.attrsOf proxyServiceType) {} ''
      Attribute set of services to reverse proxy.

      Example:
        proxiedServices = {
          jellyfin = {
            backend = "http://localhost:8096";
            subdomain = "jellyfin";  # Creates jellyfin.baseDomain
          };
          sonarr = {
            backend = "http://localhost:8989";
            useTailscale = true;  # Accessible only via Tailscale
          };
        };
    '';

    basicAuthUsers = mkOpt (types.attrsOf types.str) {} ''
      Basic auth users in bcrypt hash format.
      Generate with: caddy hash-password --plaintext 'yourpassword'

      Example:
        basicAuthUsers = {
          admin = "$2a$14$...bcrypt_hash...";
        };
    '';

    extraGlobalConfig = mkOpt types.lines "" "Additional global Caddy configuration";

    extraVirtualHosts = mkOpt (types.attrsOf (types.submodule {
      options = {
        serverAliases = mkOpt (types.listOf types.str) [] "Alternative hostnames";
        extraConfig = mkOpt types.lines "" "Caddyfile configuration for this vhost";
      };
    })) {} "Additional virtual hosts not defined in proxiedServices";
  };

  config = mkIf cfg.enable {
    services.caddy = {
      enable = true;
      package = pkgs.caddy;  # Use plugins via caddy.withPlugins if needed

      acmeCA = null;  # Use Let's Encrypt production by default
      inherit (cfg) email;

      globalConfig = optionalString (cfg.extraGlobalConfig != "") cfg.extraGlobalConfig;

      virtualHosts = mkVirtualHosts // cfg.extraVirtualHosts;
    };

    # Open firewall ports
    networking.firewall = {
      allowedTCPPorts = [ 80 443 ];
    };

    # Ensure Tailscale is available if any service uses it
    assertions = [
      {
        assertion = !cfg.useTailscaleGlobally || config.services.tailscale.enable;
        message = "Tailscale must be enabled to use useTailscaleGlobally";
      }
    ];
  };
}
