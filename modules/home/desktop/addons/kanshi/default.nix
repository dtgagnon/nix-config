{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.kanshi;

  user = config.${namespace}.user;
  home = config.users.users.${user.name}.home;
in
{
  options.${namespace}.desktop.addons.kanshi = {
    enable = mkBoolOpt false "Whether to enable Kanshi in the desktop environment.";
  };

  config = mkIf cfg.enable {
    xdg.configFile."kanshi/config".source = ./config;
    services.kanshi.enable = true;

    # configuring kanshi
    systemd.user.services.kanshi = {
      description = "Kanshi output autoconfig";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      environment = {
        XDG_CONFIG_HOME = "${home}/.config";
      };
      serviceConfig = {
        ExecCondition = ''
          ${pkgs.bash}/bin/bash -c '[ -n "$WAYLAND_DISPLAY" ]'
        '';

        ExecStart = ''
          ${pkgs.kanshi}/bin/kanshi
        '';

        RestartSec = 5;
        Restart = "always";
      };
    };
  };
}
