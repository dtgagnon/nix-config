{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.greetd;
in
{
  options.${namespace}.desktop.addons.greetd = {
    enable = mkBoolOpt false "Whether or not to enable the greetd display manager.";
  };

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = rec {
        default_session = {
          command = concatStringsSep " " [
            ${lib.getExe pkgs.greetd.tuigreet}
            "--sessions /run/current-system/sw/share/wayland-sessions/:/run/current-system/sw/share/xsession/"
            "--remember"
            "--remember-user-session"
            "--user-menu"
            "--power-shutdown /run/current-system/systemd/bin/systemctl poweroff"
            "--power-reboot /run/current-system/systemd/bin/systemctl reboot"
            "--asterisks"
            "--time"
            "--cmd Hyprland"
          ];
          user = "greeter";
        };
        initial_session = default_session;
      };
      vt = 2;
    };

    boot.kernelParams = [ "console=tty1" ];

    # Create a symlink for tuigreet sessions
    environment.etc."greetd/environments".text = ''
      Hyprland
      GNOME
      nushell
      bash
    '';
  };
}
