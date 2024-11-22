{ lib
, pkgs
, config
, inputs
, system
, namespace
, ...
}:
let
  inherit (lib) mkForce mkIf types genAttrs;
  inherit (lib.${namespace}) mkBoolOpt mkOpt enabled;
  cfg = config.${namespace}.desktop.hyprland;
in
{
  options.${namespace}.desktop.hyprland = let inherit (types) oneOf package path str listOf; in {
    enable = mkBoolOpt false "Whether or not to use the hyprland desktop manager";
    # wallpaper = mkOpt (oneOf [ package path str ]) pkgs.spirenix.wallpapers.nord-rainbow-dark-nix "The wallpaper to use.";
    plugins = mkOpt (listOf package) [ ] "Additional hyprland plugins to enable";
    addons = mkOpt (listOf str) [ ] "List of spirenix hyprland addons to enable";

    extraConfig = mkOpt str "" "Additional hyprland configuration";
    extraMonitorSettings = mkOpt str "" "Additional monitor configurations";
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      __GL_GSYNC_ALLOWED = "0";
      __GL_VRR_ALLOWED = "0";
      _JAVA_AWT_WM_NONEREPARENTING = "1";
      SSH_AUTH_SOCK = "/run/user/1000/keyring/ssh";
      DISABLE_QT5_COMPAT = "0";
      GDK_BACKEND = "wayland";
      ANKI_WAYLAND = "1";
      DIRENV_LOG_FORMAT = "";
      WLR_DRM_NO_ATOMIC = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_QPA_PLATFORM = "xcb";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      QT_STYLE_OVERRIDE = "kvantum";
      MOZ_ENABLE_WAYLAND = "1";
      WLR_BACKEND = "vulkan";
      WLR_RENDERER = "vulkan";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_SESSION_TYPE = "wayland";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
      GTK_THEME = "Dracula";
    };

    home.packages = with pkgs; [
      hyprpicker
      # swww
      swaybg
      glib
      grim
      slurp
      wl-clip-persist
      wf-recorder
      wayland
    ];

    systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];

    xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${system}.hyprland;
      systemd.variables = [ "--all" ];

      plugins = with inputs.hyprland-plugins.packages.${pkgs}; [
        # list of hyprland packages from hyprland-plugins repo
      ] ++ cfg.plugins;

      extraConfig = ''
        ${cfg.extraConfig}
      '';
    };

    spirenix.desktop.addons = {
      hyprlock = enabled;
			waybar = enabled;
      wallpapers = enabled;
			xdg-portal = enabled;
    } // genAttrs cfg.addons (name: enabled);

  };
}
