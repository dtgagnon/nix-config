{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.mako;
in
{
  options.${namespace}.desktop.addons.mako = {
    enable = mkBoolOpt false "Whether to enable Mako in Sway.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      mako
      libnotify
    ];

    systemd.user.services.mako = {
      description = "Mako notification daemon";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";

        ExecCondition = ''
          ${pkgs.bash}/bin/bash -c '[ -n "$WAYLAND_DISPLAY" ]'
        '';

        ExecStart = ''
          ${pkgs.mako}/bin/mako
        '';

        ExecReload = ''
          ${pkgs.mako}/bin/makoctl reload
        '';

        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    xdg.configFile."mako/config".source = ./config;
  };
}
