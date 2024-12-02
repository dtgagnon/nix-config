{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  inherit (config.lib.stylix) colors;
  cfg = config.modules.desktop.addons.fuzzel;
in {
  options.modules.desktop.addons.fuzzel = {
    enable = mkEnableOption "fuzzel";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      fuzzel
    ];

    # Fuzzel configuration
    xdg.configFile."fuzzel/fuzzel.ini".text = ''
      [main]
      font=monospace:size=14
      dpi-aware=yes
      icon-theme=Papirus-Dark
      terminal=$TERM

      [colors]
      background=${colors.base00}dd
      text=${colors.base05}ff
      match=${colors.base0D}ff
      selection=${colors.base02}dd
      selection-text=${colors.base05}ff
      border=${colors.base0D}ff

      [border]
      width=2
      radius=8
    '';
  };
}
