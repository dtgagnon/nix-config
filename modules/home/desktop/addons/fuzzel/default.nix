{
  lib,
  pkgs,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (config.lib.stylix) colors;
  cfg = config.${namespace}.desktop.addons.fuzzel;
in {
  options.${namespace}.desktop.addons.fuzzel = {
    enable = mkBoolOpt false "Enable fuzzel app launcher for wayland";
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
