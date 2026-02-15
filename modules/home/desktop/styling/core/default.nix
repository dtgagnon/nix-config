{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.styling.core;
in
{
  options.${namespace}.desktop.styling.core = {
    enable = mkBoolOpt false "Whether to enable core styling configuration.";
    wallpaper = mkOpt (types.package) pkgs.spirenix.wallpapers.wallpapers.nord.rainbow-dark-nix "The wallpaper to use.";
    theme = mkOpt (types.nullOr types.str) null "The theme to use.";

    cursor = {
      package = mkOpt (types.package) pkgs.bibata-cursors "The cursor theme package to use.";
      name = mkOpt types.str "Bibata-Modern-Ice" "The name of the cursor theme.";
      size = mkOpt types.int 24 "The size of the cursor.";
    };

    fonts = {
      sizes = {
        applications = mkOpt types.int 12 "The font size for applications.";
        terminal = mkOpt types.int 14 "The font size for terminal.";
        desktop = mkOpt types.int 10 "The font size for desktop.";
        popups = mkOpt types.int 10 "The font size for popups.";
      };
      monospace = {
        package = mkOpt types.package pkgs.nerd-fonts.jetbrains-mono "The monospace font package to use.";
        name = mkOpt types.str "JetBrainsMono Nerd Font Mono" "The name of the monospace font.";
      };
      sansSerif = {
        package = mkOpt types.package pkgs.dejavu_fonts "The name of the sans-serif font.";
        name = mkOpt types.str "DejaVu Sans" "The name of the sans-serif font.";
      };
      serif = {
        package = mkOpt types.package pkgs.dejavu_fonts "The name of the serif font.";
        name = mkOpt types.str "DejaVu Serif" "The name of the serif font.";
      };
      interface = {
        package = mkOpt (lib.types.package) pkgs.noto-fonts "The interface font package to use.";
        name = mkOpt lib.types.str "Noto Sans" "The name of the interface font.";
      };
    };

    gtk = {
      theme = {
        package = mkOpt (types.package) pkgs.adw-gtk3 "The GTK theme package to use.";
        name = mkOpt types.str "adw-gtk3-dark" "The name of the GTK theme.";
      };
      iconTheme = {
        # package = mkOpt (types.package)
        #   (pkgs.catppuccin-papirus-folders.override {
        #     flavor = "mocha";
        #     accent = "lavender";
        #   }) "The icon theme package to use.";
        package = mkOpt (types.package) pkgs.catppuccin-papirus-folders "The icon theme package to use.";
        name = mkOpt types.str "Papirus-Dark" "The name of the icon theme.";
      };
    };

    qt = {
      style = {
        package = mkOpt (types.nullOr types.package) null "The Qt style package to use.";
        name = mkOpt (types.nullOr types.str) "lxqt" "The name of the Qt style.";
      };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = [
        cfg.cursor.package
        cfg.fonts.monospace.package
        cfg.fonts.sansSerif.package
        cfg.fonts.serif.package
        cfg.fonts.interface.package
      ];

      pointerCursor = lib.mkForce {
        name = cfg.cursor.name;
        size = cfg.cursor.size;
        package = cfg.cursor.package;
        hyprcursor = {
          enable = true;
          size = cfg.cursor.size;
        };
        gtk.enable = true;
        x11.enable = true;
      };

      sessionVariables = {
        XCURSOR_THEME = cfg.cursor.name;
        XCURSOR_SIZE = toString cfg.cursor.size;
      };
    };

    spirenix.preservation.directories = [
      ".icons"
    ];
  };
}
