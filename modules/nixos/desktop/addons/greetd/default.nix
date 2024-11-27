{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf concatStringsSep getExe;
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
            "${getExe pkgs.greetd.tuigreet}"
            "--remember"
            "--remember-user-session"
            "--user-menu"
            ''--power-shutdown systemctl poweroff"''
            ''--power-reboot "systemctl reboot"''
            "--asterisks"
            "--time"
            # Commenting out auto-start of Hyprland to allow manual session selection
            # "--cmd Hyprland"
          ];
          user = "greeter";
        };
        initial_session = {
          command = "--cmd Hyprland";
          user = "dtgagnon";
        };
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
