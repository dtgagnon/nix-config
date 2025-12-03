{ lib
, pkgs
, config
, inputs
, system
, osConfig
, namespace
, ...
}:
let
  inherit (lib) mkMerge mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt enabled disabled mkDeepAttrsOpt;
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
    extraExec = mkOpt (types.listOf types.str) [ ] "Use for conditional exec-once additions in other modules";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      wayland.windowManager.hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${system}.hyprland;
        systemd.enable = if osConfig.programs.hyprland.withUWSM then false else true;
        xwayland.enable = false;
        inherit (cfg) extraConfig;
        settings = cfg.extraSettings // cfg.extraKeybinds // cfg.extraWinRules;
      };

      spirenix.desktop = {
        addons = {
          # Utilities
          mako = enabled; # notifications
          rofi = enabled; # launcher
          fuzzel = disabled; # app launcher, disabled in favor of rofi
          wlsunset = enabled; # color temperature manager

          # Basic functionality
          # sysbar.ags = enabled;
          hypridle = enabled;
          hyprlock = enabled;
          sysbar = enabled;
          wlogout = enabled;

          # Media
          mpv = enabled; # video player with Jellyfin support
        };
        styling = {
          gtk = enabled; # GTK theme
          qt = enabled; # Qt theme
        };
      };

      home.packages = with pkgs; [
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
      ];

      xdg.mimeApps.defaultApplications = {
        "image/*" = "nsxiv.desktop";
        "image/png" = "nsxiv.desktop";
        "image/jpg" = "nsxiv.desktop";
        "image/jpeg" = "nsxiv.desktop";
      };
    })

    # Configure Hyprland to use Intel iGPU when VFIO is enabled
    # This prevents Hyprland from holding file descriptors to the NVIDIA dGPU
    (mkIf (cfg.enable && osConfig.${namespace}.virtualisation.kvm.vfio.enable) {
      xdg.configFile."uwsm/env-hyprland" = mkIf osConfig.programs.hyprland.withUWSM {
        text = ''
          export AQ_DRM_DEVICES=${config.home.homeDirectory}/.config/hypr/intel-iGPU

          #NOTE: Restrict EGL to Mesa only, preventing NVIDIA's libEGL from opening the dGPU render node.
          #NOTE: This prevents Hyprland from holding file descriptors to /dev/dri/renderD129 (NVIDIA).
          #NOTE: Allows dynamic GPU unbinding for VFIO passthrough without crashing Hyprland
          #NOTE: See: https://github.com/hyprwm/Hyprland/issues/8679 (upstream bug - AQ_DRM_DEVICES doesn't restrict EGL layer)
          export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
        '';
      };

      home.sessionVariables = mkIf (!osConfig.programs.hyprland.withUWSM) {
        AQ_DRM_DEVICES = "${config.home.homeDirectory}/.config/hypr/intel-iGPU";
        __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";
      };
    })
  ];
}
