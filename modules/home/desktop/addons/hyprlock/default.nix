{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.hyprlock;
in
{
  options.${namespace}.desktop.addons.hyprlock = {
    enable = mkBoolOpt false "Enable Hyprlock configuration";
  };

  config = mkIf cfg.enable {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          hide_cursor = true;
        };
        
        background = {
          monitor = "";
          path = "${pkgs.spirenix.wallpapers.nord-rainbow-dark-nix-ultrawide}";
        };

        label = [
          {
            text = ''cmd[update:43200000] echo "$(date +"%A, %d %B %Y")"'';
            font_size = 25;
            position = {
              x = -30;
              y = -150;
            };
            halign = "right";
            valign = "top";
          }
          {
            text = ''cmd[update:30000] echo "$(date +"%R")"'';
            font_size = 90;
            position = {
              x = -30;
              y = 0;
            };
            halign = "right";
            valign = "top";
          }
        ];
      };
    };
  };
}