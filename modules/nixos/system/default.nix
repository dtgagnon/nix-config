{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkDefault mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  inherit (lib)
    concatMapStringsSep
    concatStringsSep
    isList
    mapAttrsToList
    ;

  cfg = config.${namespace}.system;
in
{
  options.${namespace}.system = {
    enable = mkBoolOpt true "Whether to enable system configuration.";

    # Network configuration
    network = {
      enable = mkBoolOpt true "Whether to enable networking support.";
      hosts = mkOpt types.attrs { } "An attribute set to merge with networking.hosts.";
      firewall = {
        enable = mkBoolOpt true "Whether to enable the firewall.";
        allowedTCPPorts = mkOpt (types.listOf types.port) [ ] "List of allowed TCP ports.";
        allowedUDPPorts = mkOpt (types.listOf types.port) [ ] "List of allowed UDP ports.";
      };
    };

    # Locale and timezone settings
    locale = {
      enable = mkBoolOpt true "Whether to enable locale settings.";
      default = mkOpt types.str "en_US.UTF-8" "The default system locale.";
      timeZone = mkOpt types.str "America/Detroit" "The system timezone.";
      keyMap = mkOpt types.str "us" "The system keyboard layout.";
    };

    # Environment configuration
    environment = {
      enable = mkBoolOpt true "Whether to enable environment configuration.";
      variables = mkOpt (types.attrsOf (
        types.oneOf [
          types.str
          types.path
          (types.listOf (types.either types.str types.path))
        ]
      )) { } "System-wide environment variables.";
      sessionVariables = mkOpt (types.attrsOf types.str) { } "Session-specific environment variables.";
    };
  };

  config = mkIf cfg.enable {
    # Network configuration
    networking = mkIf cfg.network.enable {
      firewall = {
        enable = cfg.network.firewall.enable;
        allowedTCPPorts = cfg.network.firewall.allowedTCPPorts;
        allowedUDPPorts = cfg.network.firewall.allowedUDPPorts;
      };

      hosts = {
        "127.0.0.1" = [ "local.test" ] ++ (cfg.network.hosts."127.0.0.1" or [ ]);
      } // cfg.network.hosts;

      networkmanager = {
        enable = true;
        dhcp = "internal";
      };
    };

    # Add user to networkmanager group if networking is enabled
    ${namespace}.user.extraGroups = mkIf cfg.network.enable [ "networkmanager" ];

    # Disable NetworkManager-wait-online to prevent nixos-rebuild issues
    systemd.services.NetworkManager-wait-online.enable = false;

    # Locale and timezone configuration
    i18n = mkIf cfg.locale.enable {
      defaultLocale = cfg.locale.default;
    };

    time = mkIf cfg.locale.enable {
      timeZone = cfg.locale.timeZone;
    };

    console = mkIf cfg.locale.enable {
      keyMap = mkDefault cfg.locale.keyMap;
    };

    # Environment configuration
    environment = mkIf cfg.environment.enable {
      variables = {
        EDITOR = "nvim";
        SHELL = "nu";
        TERMINAL = "ghostty";
        LESSHISTFILE = "$HOME/.cache/less.history";
        WGETRC = "$HOME/.config/wgetrc";
      } // cfg.environment.variables;
      sessionVariables = {
        XDG_CACHE_HOME = "$HOME/.cache";
        XDG_CONFIG_HOME = "$HOME/.config";
        XDG_DATA_HOME = "$HOME/.local/share";
        XDG_BIN_HOME = "$HOME/.local/bin";
        XDG_DESKTOP_DIR = "$HOME";
      } // cfg.environment.sessionVariables;
      extraInit = concatStringsSep "\n" (
        mapAttrsToList (
          n: v: ''export ${n}="${if isList v then concatMapStringsSep ":" toString v else toString v}"''
        ) cfg.environment.variables
      );
    };
  };
}
