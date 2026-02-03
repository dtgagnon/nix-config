{ lib
, pkgs
, config
, inputs
, system
, osConfig ? { }
, namespace
, ...
}:
let
  inherit (lib) mkMerge mkIf types;
  inherit (lib.${namespace})
    mkBoolOpt
    mkOpt
    enabled
    disabled
    mkDeepAttrsOpt
    ;
  cfg = config.${namespace}.desktop.hyprland;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.${namespace}.desktop.hyprland = {
    enable = mkBoolOpt false "Whether or not to use the hyprland desktop manager";
    terminal = {
      name = mkOpt types.str "ghostty" "The terminal for hyprland to use";
      package = mkOpt types.package pkgs.${cfg.terminal.name} "The terminal for hyprland to use";
    };
    monitors = mkOpt (types.listOf types.str) [ ] "Configure any additional monitors";

    extraConfig = mkOpt types.lines "" "Additional hyprland configuration in string format";
    hyprModifier = mkOpt types.str "SUPER" "The main hyprland modifier key.";
    extraKeybinds = mkDeepAttrsOpt { } "Additional keybinds to add to the Hyprland config";
    extraSettings = mkDeepAttrsOpt { } "Additional settings to add to the Hyprland config";
    extraWinRules = mkDeepAttrsOpt { } "Window rules for Hyprland";
    extraAddons = mkDeepAttrsOpt { } "Additional addons to enable";
    extraExec =
      mkOpt (types.listOf types.str) [ ]
        "Use for conditional exec-once additions in other modules";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      wayland.windowManager.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${system}.hyprland;
        systemd.enable = if (osConfig.programs.hyprland.withUWSM or false) then false else true;
        xwayland.enable = false;
        inherit (cfg) extraConfig;
        settings = cfg.extraSettings // cfg.extraKeybinds // cfg.extraWinRules;
      };

      spirenix.desktop = {
        addons = {
          # Utilities
          # Only enable mako when using waybar sysbar (quickshell provides its own notification server)
          mako = mkIf (config.${namespace}.desktop.addons.sysbar.backend == "waybar") enabled;
          rofi = enabled; # launcher
          fuzzel = disabled; # app launcher, disabled in favor of rofi
          wlsunset = enabled; # color temperature manager

          # Basic functionality
          # sysbar.ags = enabled;
          hypridle = enabled;
          hyprlock = enabled;
          sysbar = enabled;
          wlogout = enabled;
          xdg = enabled;

          # Media
          mpv = enabled; # video player with Jellyfin support
        };
        styling = {
          gtk = enabled; # GTK theme
          qt = enabled; # Qt theme
        };
      };

      home.packages =
        with pkgs;
        [
          # core dependencies
          libinput
          glib
          gtk3.out
          wayland

          # basic features
          ## terminal
          cfg.terminal.package
          ## screen shots
          grim
          slurp
          hyprshot
          swappy
          ## image viewer
          nsxiv
          ## monitor controls
          ddcutil
          brightnessctl

          # misc
          wl-clipboard
          playerctl
        ]
        ++
        lib.optional (osConfig.${namespace}.virtualisation.kvm.vfio.enable or false)
          pkgs.spirenix.hyprland-gpu-tools;

      xdg.mimeApps.defaultApplications = {
        "image/*" = "nsxiv.desktop";
        "image/png" = "nsxiv.desktop";
        "image/jpg" = "nsxiv.desktop";
        "image/jpeg" = "nsxiv.desktop";
      };

      spirenix.preservation.directories = [
        ".config/hypr"
      ];
    })

    # Configure Hyprland GPU selection when VFIO is enabled
    # GPU env vars (AQ_DRM_DEVICES, __EGL_VENDOR_LIBRARY_FILENAMES) are now set by
    # launcher scripts (hyprland-uwsm, hyprland-uwsm-dgpu, hyprland-uwsm-igpu)
    #
    # Session selection:
    # - hyprland-uwsm-dgpu → Forces NVIDIA RTX 4090 (high performance)
    # - hyprland-uwsm-igpu → Forces Intel iGPU (VM-compatible)
    # - hyprland-uwsm → Auto-detects based on VFIO state
    #
    # See: https://github.com/hyprwm/Hyprland/issues/8679
    # (upstream bug - AQ_DRM_DEVICES doesn't fully restrict EGL layer, hence __EGL_VENDOR_LIBRARY_FILENAMES)
    (mkIf (cfg.enable && (osConfig.${namespace}.virtualisation.kvm.vfio.enable or false)) {
      # Override hyprland.desktop when using UWSM to use start-hyprland wrapper
      # UWSM will source ~/.config/uwsm/env-hyprland (created by launcher scripts) before starting
      xdg.dataFile."wayland-sessions/hyprland.desktop" = mkIf (osConfig.programs.hyprland.withUWSM or false) {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=Hyprland
          Comment=Hyprland compositor managed by UWSM
          Exec=${inputs.hyprland.packages.${system}.hyprland}/bin/start-hyprland
          X-GDM-SessionRegisters=true
        '';
      };

      home.sessionVariables = mkIf (!(osConfig.programs.hyprland.withUWSM or false)) {
        # Fallback for non-UWSM sessions (legacy - prefer UWSM)
        AQ_DRM_DEVICES = "${config.home.homeDirectory}/.config/hypr/intel-iGPU";
        __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";
      };

      # Ensure GPU device symlinks exist
      home.activation.hyprlandGpuSymlinks = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/hypr

        # Intel iGPU symlink (busId format: 0000:00:02.0 → pci-0000:00:02.0)
        $DRY_RUN_CMD ln -sf /dev/dri/by-path/pci-${osConfig.${namespace}.hardware.gpu.iGPU.busId}-card \
          ${config.home.homeDirectory}/.config/hypr/intel-iGPU

        # NVIDIA dGPU symlink (busId format: 0000:01:00.0 → pci-0000:01:00.0)
        $DRY_RUN_CMD ln -sf /dev/dri/by-path/pci-${osConfig.${namespace}.hardware.gpu.dGPU.busId}-card \
          ${config.home.homeDirectory}/.config/hypr/nvidia-dGPU
      '';
    })
  ];
}
