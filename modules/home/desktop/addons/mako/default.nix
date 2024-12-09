{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (config.lib.stylix) colors;
  cfg = config.${namespace}.desktop.addons.mako;
in
{
  options.${namespace}.desktop.addons.mako = {
    enable = mkBoolOpt false "Whether to enable Mako for wayland notification management";
  };

  config = mkIf cfg.enable {
    # home.packages = [ pkgs.libnotify pkgs.jq ];

    services.mako = {
      enable = true;
      layer = "overlay";
      width = 500;
      height = 160;
      defaultTimeout = 5000;
      maxVisible = 3;

## Already handled by stylix
      # backgroundColor = "${colors.base00}";
      # textColor = "${colors.base05}";
      # borderColor = "${colors.base03}";
      # progressColor = "over ${colors.base0E}";
      iconPath = "${pkgs.breeze-icons}/share/icons/breeze-dark";
      maxIconSize = 24;

      borderRadius = 12;
      borderSize = 2;
      margin = "12px";
      padding = "12px";
    };
  };
}
