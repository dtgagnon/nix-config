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
  cfg = config.${namespace}.desktop.hyprland;

  hyprPlugs = inputs.hyprland-plugins.packages.${pkgs};
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;
  options.${namespace}.desktop.hyprland =
    let
      inherit (types) package str listOf;
    in
    {
      enable = mkBoolOpt false "Whether or not to use the hyprland desktop manager";
      plugins = mkOpt (listOf package) (with hyprPlugs; [ ]) "Additional hyprland plugins to enable";
      addons = mkOpt (listOf str) [ ] "List of desktop addons to enable";
      extraConfig = mkOpt str "" "Additional hyprland configuration";
      extraMonitorSettings = mkOpt str "" "Additional monitor configurations";
      primaryModifier = mkOpt str "SUPER" "The primary modifier key.";
      execOnceExtras = mkOpt (listOf str) [ ] "List of commands to execute once";
    };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${system}.hyprland;
      systemd.enable = true;
      xwayland.enable = true;
      extraConfig = cfg.extraConfig;

      plugins =
        with hyprPlugs;
        [
          # list of hyprland packages from hyprland-plugins repo
        ]
        ++ cfg.plugins;
    };

    spirenix.desktop.addons = {
      hyprlock = enabled;
      hypridle = enabled;
      hyprpaper = enabled;
      pyprland = enabled;

      gtk = enabled;
      rofi = enabled;
      term = enabled;
      waybar = enabled;
      wlogout = enabled;
      wlsunset = enabled;
      wallpapers = enabled;
    } // genAttrs cfg.addons (name: enabled);

    home.packages =
      with pkgs;
      [
        # media
        pamixer
        playerctl
        brightnessctl

        # desktop env
        libdbusmenu-gtk3
        gnome-control-center

        # core dependencies
        libinput
        glib
        gtk3.out
        wayland

        # wayland tools
        hyprpicker
        swww

        # screenshots
        grim
        slurp

        # clipboard
        wl-clipboard
        cliphist
        wl-clip-persist

        # utils
        libnotify
        poweralertd

        # theming
        bibata-cursors
        nordzy-cursor-theme

        # cursors
      ]
      ++ cfg.plugins;

    home.sessionVariables = {
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";
      # GDK_BACKEND = "wayland,x11";
      # SDL_VIDEODRIVER = "wayland";
      # CLUTTER_BACKEND = "wayland";

      # MOZ_ENABLE_WAYLAND = 1;
      # _JAVA_AWT_WM_NONREPARENTING = 1;

      # XCURSOR_SIZE = 22;
      # XCURSOR_THEME = "Nordzy-cursors";
    };

    systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
  };
}