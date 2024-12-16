{
  lib,
  pkgs,
  config,
  namespace,
  ...
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
      defaultTimeout = 5000;
      ignoreTimeout = true; # ignore timeout set by application, uses default instead
      maxVisible = 3;

      layer = "overlay";
      anchor = "top-center";
      width = 400;
      height = 82;
      margin = "2";
      padding = "12";

      borderRadius = 12;
      borderSize = 1;

      maxIconSize = 12;

      ## Already handled by stylix
      # backgroundColor = "${colors.base00}80";
      # textColor = "${colors.base05}";
      # borderColor = "${colors.base03}";
      # progressColor = "over ${colors.base0E}";
      # iconPath = "${pkgs.catppuccin-papirus}/share/icons/Papirus-Dark";

      extraConfig = ''
        text-alignment=center
      '';
    };
  };
}
