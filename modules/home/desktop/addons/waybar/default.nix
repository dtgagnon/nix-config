{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.waybar;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files-recursive ./.;

  options.${namespace}.desktop.addons.waybar = {
    enable = mkBoolOpt false "Enable waybar";
    presetLayout = mkOpt (types.nullOr types.str) "top-isolated-islands-centeredWorkspaces" "The waybar layout to use";
    presetStyle = mkOpt (types.nullOr types.str) "top-isolated-islands-centeredWorkspaces" "The waybar style to use";
    extraStyle = mkOpt types.str "" "Additional style to add to waybar";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      hyprpanel
      ags
    ];
  };
}
