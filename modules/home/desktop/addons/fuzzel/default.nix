{
  lib,
  pkgs,
  config,
  namespace,
  ...
}: let
  inherit (lib) mkIf optionalString;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.fuzzel;

  stylixEnabled = config.stylix.enable or false;
  colors = if stylixEnabled then config.lib.stylix.colors else {};
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

      ${optionalString stylixEnabled ''
      [colors]
      background=${colors.base00}dd
      text=${colors.base05}ff
      match=${colors.base0D}ff
      selection=${colors.base02}dd
      selection-text=${colors.base05}ff
      border=${colors.base0D}ff
      ''}
      [border]
      width=2
      radius=8
    '';
  };
}
