{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.mako;

  inherit (config.lib.stylix) colors;
  fontSize = toString config.stylix.fonts.sizes.desktop;
in
{
  options.${namespace}.desktop.addons.mako = {
    enable = mkBoolOpt false "Whether to enable Mako for wayland notification management";
  };

  config = mkIf cfg.enable {
    # home.packages = [ pkgs.libnotify ];

    services.mako = {
      enable = true;
      # font = "${config.stylix.fonts.sansSerif.name} ${fontSize}";
      borderRadius = 4;
      # textColor = "${colors.base07}ff";
      # backgroundColor = "${colors.base00}f4";
      # borderColor = "${colors.base03}ff";
      borderSize = 2;
      margin = "12,12,6";
      padding = "12,12,12,12";
      defaultTimeout = 5000;
      maxVisible = 3;
    };
  };
}
