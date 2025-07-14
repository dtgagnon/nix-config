{ lib
, pkgs
, config
, inputs
, system
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt enabled mkLinesOpt mkDeepAttrsOpt;
  cfg = config.spirenix.desktop.hyprland;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.spirenix.desktop.hyprland = {
    enable = mkBoolOpt false "Whether or not to use the hyprland desktop manager";
    terminal = {
      name = mkOpt types.str "ghostty" "The terminal for hyprland to use";
      package = mkOpt types.package inputs.ghostty.packages.${system}.${cfg.terminal.name} "The terminal for hyprland to use";
    };
    monitors = mkOpt (types.listOf types.str) [ ] "Configure any additional monitors";

    extraConfig = mkLinesOpt "" "Additional hyprland configuration in string format";
    hyprModifier = mkOpt types.str "SUPER" "The main hyprland modifier key.";
    extraKeybinds = mkDeepAttrsOpt { } "Additional keybinds to add to the Hyprland config";
    extraSettings = mkDeepAttrsOpt { } "Additional settings to add to the Hyprland config";
    extraWinRules = mkDeepAttrsOpt { } "Window rules for Hyprland";
    extraAddons = mkDeepAttrsOpt { } "Additional addons to enable";
    extraExec = mkOpt (types.listOf types.str) [ ] "Use for conditional exec-once additions in other modules";
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      AQ_DRM_DEVICES = "/home/dtgagnon/.config/hypr/intel-iGPU";
      WLR_DRM_DEVICES = "/home/dtgagnon/.config/hypr/intel-iGPU";
    };
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${system}.hyprland;
      systemd.enable = true;
      xwayland.enable = true;
      inherit (cfg) extraConfig;
      settings = cfg.extraSettings // cfg.extraKeybinds // cfg.extraWinRules;
    };

    spirenix.desktop = {
      addons = {
        # Utilities
        mako = enabled; # notifications
        rofi = enabled; # launcher
        fuzzel = enabled; # app launcher
        wlsunset = enabled; # color temperature manager

        # Basic functionality
        # ags.bar = enabled;
        hypridle = enabled;
        hyprlock = enabled;
        waybar = enabled;
        wlogout = enabled;
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
      linuxKernel.packages.linux_6_6.ddcci-driver
      brightnessctl

      # misc
      wl-clipboard
      swww
      playerctl
    ];
  };
}
