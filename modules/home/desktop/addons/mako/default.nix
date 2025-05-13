{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (config.lib.stylix) colors;
  cfg = config.${namespace}.desktop.addons.mako;
in
{
  options.${namespace}.desktop.addons.mako = {
    enable = mkBoolOpt false "Whether to enable Mako for wayland notification management";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.libnotify
      pkgs.jq
    ];

    services.mako = mkForce {
      enable = true;
      settings = {
        "default-timeout" = 5000;
        "ignore-timeout" = true; # ignore timeout set by application, uses default instead
        "max-visible" = 3;

        layer = "overlay";
        anchor = "top-center";
        width = 400;
        height = 82;
        margin = "2";
        padding = "12";

        "border-radius" = 12;
        "border-size" = 1;

        "max-icon-size" = 12;

        ## Already handled by stylix
        # background-color = "${colors.base00}80";
        # text-color = "${colors.base05}";
        # border-color = "${colors.base03}";
        # progress-color = "over ${colors.base0E}";
        # icon-path = "${pkgs.catppuccin-papirus}/share/icons/Papirus-Dark";
      };
    };
  };
}
