{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.hyprpanel;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files-recursive ./.;

  options.${namespace}.desktop.addons.hyprpanel = {
    enable = mkBoolOpt false "Whether to enable hyprpanel.";
    layout = mkOpt (types.enum [ "style1" ]) "style1" "The hyprpanel layout to use";
  };

  config = mkIf cfg.enable {
    programs.hyprpanel = {
      enable = true;
      hyprland.enable = true;
      overwrite.enable = true;
    };
  };
}