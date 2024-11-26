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
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;
  options.${namespace}.desktop.hyprland =
    let
      inherit (types) package str listOf;
    in
    {
      enable = mkBoolOpt false "Whether or not to use the hyprland desktop manager";
      plugins = mkOpt (listOf package) [ ] "Additional hyprland plugins to enable";
      addons = mkOpt (listOf str) [ ] "List of desktop addons to enable";
      extraConfig = mkOpt str "" "Additional hyprland configuration";
      extraMonitorSettings = mkOpt str "" "Additional monitor configurations";
    };

  config = mkIf cfg.enable {
    spirenix.desktop.addons = {
      hyprlock = enabled;
      waybar = enabled;
      wallpapers = enabled;
    } // genAttrs cfg.addons (name: enabled);

    home.packages =
      with pkgs;
      [
        # media
        volumectl
        playerctl
        brightnessctl

        # desktop env
        ags
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
        qt5ct
        qt6ct

        # cursors
        bibata-cursors
        nordzy-cursor-theme
      ]
      ++ cfg.plugins;

    home.sessionVariables = {
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";

      QT_AUTO_SCREEN_SCALE_FACTOR = 1;
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
      QT_QPA_PLATFORMTHEME = "qt5ct";

      GDK_BACKEND = "wayland,x11";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";

      MOZ_ENABLE_WAYLAND = 1;
      NIXOS_OZONE_WL = 1;
      _JAVA_AWT_WM_NONREPARENTING = 1;

      XCURSOR_SIZE = 22;
      XCURSOR_THEME = "Nordzy-cursors";
    };

    systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];

    # xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${system}.hyprland;

      # reloadConfig = true;
      systemdIntegration = true;
      systemd.variables = [ "--all" ];
      xwayland.enable = true;

      plugins =
        with inputs.hyprland-plugins.packages.${pkgs};
        [
          # list of hyprland packages from hyprland-plugins repo
        ]
        ++ cfg.plugins;

      extraConfig = ''
        ${cfg.extraConfig}
      '';
    };
  };
}
