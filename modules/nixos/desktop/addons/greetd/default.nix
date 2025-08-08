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
      settings = {
        default_session = {
          command = concatStringsSep " " [
            "${getExe pkgs.greetd.tuigreet}"
            "--remember"
            "--remember-user-session"
            "--user-menu"
            ''--power-shutdown "systemctl poweroff"''
            ''--power-reboot "systemctl reboot"''
            "--asterisks"
            "--time"
            # Commenting out auto-start of Hyprland to allow manual session selection
            # "--cmd Hyprland"
          ];
          user = "greeter";
        };
        initial_session = {
          command = "--cmd hyprland-uwsm";
          user = "dtgagnon";
        };
      };
    };

    #NOTE Prevent log rendering from overlaying with tuigreet.
    # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";

      #NOTE The below prevent bootlogs from rendering on screen.
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };

    # boot.kernelParams = [ "console=tty1" ];

    # Create a symlink for tuigreet sessions
    environment.etc."greetd/environments".text = ''
      hyprland-uwsm
      Hyprland
      GNOME
      nushell
      bash
    '';
  };
}
