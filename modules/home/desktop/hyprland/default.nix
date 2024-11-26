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
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;
  options.${namespace}.desktop.hyprland = 
  let inherit (types) oneOf package path str listOf;
  in {
    enable = mkBoolOpt false "Whether or not to use the hyprland desktop manager";
    # wallpaper = mkOpt (oneOf [ package path str ]) pkgs.spirenix.wallpapers.nord-rainbow-dark-nix "The wallpaper to use.";
    plugins = mkOpt (listOf package) [ ] "Additional hyprland plugins to enable";
    addons = mkOpt (listOf str) [ ] "List of spirenix hyprland addons to enable";

    extraConfig = mkOpt str "" "Additional hyprland configuration";
    extraMonitorSettings = mkOpt str "" "Additional monitor configurations";
  };

  config = mkIf cfg.enable {
    spirenix.desktop.addons = {
      hyprlock = enabled;
			waybar = enabled;
      wallpapers = enabled;
    } // genAttrs cfg.addons (name: enabled);
    
    home.packages = with pkgs; [
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
      swaybg
      grim
      grimblast
      slurp
      wl-clip-persist
      wf-recorder
    ];

    home.sessionVariables = {
      # User-specific application settings
      ANKI_WAYLAND = "1";
      MOZ_ENABLE_WAYLAND = "1";
      _JAVA_AWT_WM_NONEREPARENTING = "1";
      
      # Graphics and display settings
      __GL_GSYNC_ALLOWED = "0";
      __GL_VRR_ALLOWED = "0";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_QPA_PLATFORM = "xcb";
      
      # User interface preferences
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      QT_STYLE_OVERRIDE = "kvantum";
      GTK_THEME = "Dracula";
      DISABLE_QT5_COMPAT = "0";
      
      # User-specific paths and settings
      SSH_AUTH_SOCK = "/run/user/1000/keyring/ssh";
      DIRENV_LOG_FORMAT = "";
    };

    systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];

    xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${system}.hyprland;

      # reloadConfig = true;
      systemdIntegration = true;
      systemd.variables = [ "--all" ];
      recommendedEnvironment = true;
      xwayland.enable = true;

      plugins = with inputs.hyprland-plugins.packages.${pkgs}; [
        # list of hyprland packages from hyprland-plugins repo
      ] ++ cfg.plugins;

      extraConfig = ''
        ${cfg.extraConfig}
      '';
    };



  };
}
