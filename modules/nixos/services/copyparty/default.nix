{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.copyparty;

  extraArgs = lib.concatStringsSep " " cfg.extraArgs;
  globalSettings =
    {
      i = cfg.address;
      p = cfg.port;
    }
    // cfg.settings;
  cfgEtcPath = lib.removePrefix "/etc/" cfg.cfgFile;
  renderList = items: lib.concatStringsSep ", " (map toString items);
  renderGlobalLine = key: value:
    if lib.isBool value then
      lib.optional (value) key
    else if lib.isList value then
      [ "${key}: ${renderList value}" ]
    else
      [ "${key}: ${toString value}" ];
  renderGlobal =
    lib.flatten (lib.mapAttrsToList renderGlobalLine globalSettings);
  renderAccsValue = value:
    if lib.isList value then
      renderList value
    else
      toString value;
  renderAccs = accs:
    let
      accLines = lib.mapAttrsToList (perm: value: "${perm}: ${renderAccsValue value}") accs;
    in
    if accLines == [ ] then
      [ ]
    else
      [ "accs:" ] ++ map (line: "  ${line}") accLines;
  renderFlags = volume:
    let
      flagLines =
        volume.flags
        ++ lib.mapAttrsToList (flag: value: "${flag}: ${toString value}") volume.flagArgs;
    in
    if flagLines == [ ] then
      [ ]
    else
      [ "flags:" ] ++ map (line: "  ${line}") flagLines;
  renderVolume = volume:
    let
      volumePath = if volume.path != null then volume.path else cfg.dataDir;
      header = [ "[${volume.urlPath}]" ];
      body =
        [ "  ${volumePath}" ]
        ++ map (line: "  ${line}") (renderAccs volume.accs)
        ++ map (line: "  ${line}") (renderFlags volume);
    in
    header ++ body;
  effectiveVolumes =
    if cfg.volumes == [ ] then
      [
        {
          urlPath = "/";
          path = cfg.dataDir;
          accs = { rw = "*"; };
          flags = [ ];
          flagArgs = { };
        }
      ]
    else
      cfg.volumes;
  renderVolumes = lib.concatMap renderVolume effectiveVolumes;
  renderAccounts =
    let
      accountLines = lib.mapAttrsToList (user: password: "${user}: ${password}") cfg.accounts;
    in
    if accountLines == [ ] then
      [ ]
    else
      [ "[accounts]" ] ++ map (line: "  ${line}") accountLines;
  renderIncludes = map (path: "% ${path}") cfg.includes;
  configText =
    if cfg.cfgText != null then
      cfg.cfgText
    else
      lib.concatStringsSep "\n"
        (
          [ "[global]" ]
          ++ map (line: "  ${line}") renderGlobal
          ++ renderAccounts
          ++ renderVolumes
          ++ renderIncludes
          ++ cfg.extraConfig
        ) + "\n";
in
{
  options.${namespace}.services.copyparty = {
    enable = mkBoolOpt false "Enable the copyparty file sharing service.";
    package = mkOpt types.package pkgs.copyparty-most "Package providing the copyparty binary.";
    dataDir = mkOpt types.str "/var/lib/copyparty" "Directory for uploaded files and state.";
    address = mkOpt types.str "0.0.0.0" "Address the service listens on.";
    port = mkOpt types.port 3923 "Port the service listens on.";
    cfgFile = mkOpt types.str "/etc/copyparty/copyparty.conf" "Copyparty configuration file path.";
    cfgText = mkOpt (types.nullOr types.lines) null "Raw copyparty configuration file contents. Overrides generated config.";
    settings = mkOpt
      (types.attrsOf (types.oneOf [
        types.bool
        types.int
        types.str
        (types.listOf (types.oneOf [ types.int types.str ]))
      ]))
      { } "Values written to the [global] section; booleans become flags, lists are comma-separated.";
    accounts = mkOpt (types.attrsOf types.str) { } "Accounts written to the [accounts] section (plaintext passwords).";
    volumes = mkOpt
      (types.listOf (types.submodule ({ ... }: {
        options = {
          urlPath = mkOpt types.str "/" "URL path for the volume.";
          path = mkOpt (types.nullOr types.str) null "Filesystem path for the volume.";
          accs = mkOpt (types.attrsOf (types.oneOf [ types.str (types.listOf types.str) ])) { }
            "Permission map for the volume (e.g. { r = \"*\"; rw = [ \"user\" ]; }).";
          flags = mkOpt (types.listOf types.str) [ ] "Volflags without arguments.";
          flagArgs = mkOpt (types.attrsOf (types.oneOf [ types.str types.int ])) { } "Volflags with arguments.";
        };
      }))) [ ] "Volumes written to the config file.";
    extraConfig = mkOpt (types.listOf types.str) [ ] "Additional raw lines appended to the config file.";
    includes = mkOpt (types.listOf types.str) [ ] "Include paths appended as % directives.";
    extraArgs = mkOpt (types.listOf types.str) [ ] "Additional command-line arguments passed to copyparty.";
    user = mkOpt types.str "copyparty" "User account running the service.";
    group = mkOpt types.str "copyparty" "Group owning service files.";
    openFirewall = mkBoolOpt false "Open the firewall for the configured port.";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/etc/" cfg.cfgFile;
        message = "${namespace}.services.copyparty.cfgFile must be under /etc so it can be managed declaratively.";
      }
    ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      home = cfg.dataDir;
      group = cfg.group;
    };

    users.groups.${cfg.group} = { };

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0750 ${cfg.user} ${cfg.group} - -"
    ];

    environment.etc."${cfgEtcPath}".text = configText;

    systemd.services.copyparty = {
      description = "Copyparty file sharing service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/copyparty -c ${cfg.cfgFile}" +
          lib.optionalString (extraArgs != "") " ${extraArgs}";
        Restart = "on-failure";
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}
