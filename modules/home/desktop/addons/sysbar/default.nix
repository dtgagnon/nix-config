{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types attrByPath;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.sysbar;
in
{
  imports = [ ./waybar ./ags ];

  options.${namespace}.desktop.addons.sysbar = {
    enable = mkBoolOpt false "Enable system bar (waybar or ags)";
    backend = mkOpt (types.enum [ "waybar" "ags" ]) "waybar" "Which system bar backend to use";

    sysTrayApps = mkOpt (types.listOf (types.either types.str (types.submodule {
      options = {
        name = mkOpt types.str null "Service name";
        package = mkOpt types.package null "Package to use";
        binary = mkOpt (types.nullOr types.str) null "Binary name override";
      };
    }))) [ ] "System tray applications";
  };

  config = mkIf cfg.enable {
    spirenix.desktop.addons.sysbar = {
      waybar.enable = mkIf (cfg.backend == "waybar") true;
      ags.enable = mkIf (cfg.backend == "ags") true;
    };

    # Dynamically create systemd services for system tray apps
    systemd.user.services = builtins.listToAttrs (
      map
        (appCfg:
          let
            # Resolve app configuration dynamically
            app =
              if builtins.isString appCfg then
                # Simple string case - auto-resolve package and binary
                let
                  pkg = if builtins.hasAttr appCfg pkgs
                        then pkgs.${appCfg}
                        else throw "Package '${appCfg}' not found in pkgs";
                in {
                  name = appCfg;
                  package = pkg;
                  exe = lib.getExe pkg;
                }
              else
                # Explicit configuration
                {
                  name = appCfg.name;
                  package = appCfg.package;
                  exe = if appCfg ? binary && appCfg.binary != null
                        then "${appCfg.package}/bin/${appCfg.binary}"
                        else lib.getExe appCfg.package;
                };
          in
          {
            name = app.name;
            value = {
              Unit = {
                Description = "${app.name} System Tray";
                After = [ "${cfg.backend}.service" "graphical-session.target" ];
                Wants = [ "${cfg.backend}.service" ];
                PartOf = [ "graphical-session.target" ];
              };
              Service = {
                ExecStart = app.exe;
                Restart = "on-failure";
              };
              Install = {
                WantedBy =
                  [ "graphical-session.target" ]
                  ++ lib.optionals (attrByPath [ "wayland" "windowManager" "hyprland" "systemd" "enable" ] false config) [ "wayland-session@Hyprland.target" ];
              };
            };
          })
        cfg.sysTrayApps
    );
  };
}
