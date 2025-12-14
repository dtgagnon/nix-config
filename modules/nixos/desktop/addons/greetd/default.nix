{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.greetd;

  # Create desktop entries for GPU session variants (for session menu in tuigreet)
  gpuSessionEntries = pkgs.runCommand "gpu-session-entries" { } ''
    mkdir -p $out/share/wayland-sessions

    cat > $out/share/wayland-sessions/hyprland-gpu-auto.desktop << EOF
    [Desktop Entry]
    Name=Hyprland (GPU Auto)
    Comment=Hyprland with UWSM - auto GPU detection
    Exec=${pkgs.spirenix.hyprland-gpu-tools}/bin/hyprland-uwsm
    Type=Application
    EOF

    ${lib.optionalString config.${namespace}.virtualisation.kvm.vfio.enable ''
      cat > $out/share/wayland-sessions/hyprland-gpu-dgpu.desktop << EOF
      [Desktop Entry]
      Name=Hyprland (GPU dGPU)
      Comment=Hyprland with UWSM - force NVIDIA dGPU
      Exec=${pkgs.spirenix.hyprland-gpu-tools}/bin/hyprland-uwsm-dgpu
      Type=Application
      EOF

      cat > $out/share/wayland-sessions/hyprland-gpu-igpu.desktop << EOF
      [Desktop Entry]
      Name=Hyprland (GPU iGPU)
      Comment=Hyprland with UWSM - force Intel iGPU
      Exec=${pkgs.spirenix.hyprland-gpu-tools}/bin/hyprland-uwsm-igpu
      Type=Application
      EOF
    ''}
  '';

  # Combine with system session entries for --sessions flag
  # Note: tuigreet requires explicit paths to directories containing .desktop files
  sessionPath = lib.concatStringsSep ":" [
    "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
    "${config.services.displayManager.sessionData.desktops}/share/xsessions"
    "${gpuSessionEntries}/share/wayland-sessions"
  ];

  # Session commands for /etc/greetd/environments (fallback for tuigreet)
  sessionCommands = lib.concatStringsSep "\n" (
    [
      "hyprland-uwsm"
    ]
    ++ lib.optionals config.${namespace}.virtualisation.kvm.vfio.enable [
      "hyprland-uwsm-dgpu"
      "hyprland-uwsm-igpu"
    ]
  );
in
{
  options.${namespace}.desktop.addons.greetd = {
    enable = mkBoolOpt false "Whether or not to enable the greetd display manager.";
  };

  config = mkIf cfg.enable {
    # Add session wrapper scripts (hyprland-uwsm, hyprland-uwsm-dgpu, hyprland-uwsm-igpu)
    environment.systemPackages = [
      pkgs.spirenix.hyprland-gpu-tools
    ];

    # Create /etc/greetd/environments file for session discovery
    environment.etc."greetd/environments".text = sessionCommands;

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
            # Point to session desktop entries for session discovery
            "--sessions '${sessionPath}'"
          ];
          user = "greeter";
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
  };
}
