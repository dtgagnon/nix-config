{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.greetd;
in
{
  options.${namespace}.desktop.addons.greetd = {
    enable = mkBoolOpt false "Whether or not to enable the greetd display manager.";
  };

  config = mkIf cfg.enable {
    # Add session wrapper scripts for GPU selection
    environment.systemPackages = mkIf config.spirenix.virtualisation.kvm.vfio.enable [
      pkgs.spirenix.hyprland-gpu-tools
    ];

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = lib.concatStringsSep " " [
            "${getExe pkgs.tuigreet}"
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
        # NOTE: initial_session removed to allow GPU session selection at login
        # The previous command was malformed anyway (--cmd is a tuigreet flag, not a command)
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
      ${lib.optionalString config.${namespace}.virtualisation.kvm.vfio.enable "hyprland-uwsm-dgpu"}
      ${lib.optionalString config.${namespace}.virtualisation.kvm.vfio.enable "hyprland-uwsm-igpu"}
      hyprland-uwsm
      Hyprland
      GNOME
      nushell
      bash
    '';
  };
}
