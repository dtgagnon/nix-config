{
  lib,
  pkgs,
  config,
  inputs,
  system,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types genAttrs;
  inherit (lib.${namespace}) mkBoolOpt mkOpt enabled;
  cfg = config.spirenix.desktop.hyprland;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.spirenix.desktop.hyprland = {
    enable = mkBoolOpt false "Whether or not to use the hyprland desktop manager";
    extraConfig = mkOpt types.str "" "Additional hyprland configuration in string format";
    hyprModifier = mkOpt types.str "SUPER" "The main hyprland modifier key.";
    extraKeybinds =
      mkOpt (types.attrsOf types.anything) { }
        "Additional keybinds to add to the Hyprland config";
    extraSettings =
      mkOpt (types.attrsOf types.anything) { }
        "Additional settings to add to the Hyprland config";
    extraWinRules = mkOpt (types.attrsOf types.anything) { } "Window rules for Hyprland";

    extraAddons = mkOpt (types.attrsOf types.anything) { } "Additional addons to enable";
  };

  config = mkIf cfg.enable {
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
        mako = enabled;     # notifications
        rofi = enabled;     # launcher
        fuzzel = enabled;   # app launcher
        wlsunset = enabled; # color temperature manager

        # Basic functionality
        hypridle = enabled;
				hyprlock = enabled;
        waybar = enabled;
        wlogout = enabled;
      };
      styling = {
        gtk = enabled;      # GTK theme
        qt = enabled;       # Qt theme
      };
    };

    home.packages = with pkgs; [
      # core dependencies
      libinput
      glib
      gtk3.out
      wayland

      # basic features
      grim            # Screenshot utility for Wayland
      swww            # Efficient animated wallpaper daemon for Wayland
      slurp           # Select a region in Wayland compositors
      swappy          # A screenshot editing tool for Wayland
      playerctl       # Command-line utility to control media players
      brightnessctl   # Brightness control for Linux
      wl-clipboard    # Command-line clipboard utilities for Wayland
      kitty           # GPU-accelerated terminal emulator
    ];
  };
}
