{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.sysbar.waybar;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files-recursive ./.;

  options.${namespace}.desktop.addons.sysbar.waybar = {
    enable = mkBoolOpt false "Enable waybar";
    settings = mkOpt (types.listOf types.attrs) [ ] "Configuration for the layout of waybar";
    presetLayout = mkOpt (types.nullOr types.str) "top-isolated-islands-centeredWorkspaces" "The waybar layout to use";
    presetStyle = mkOpt (types.nullOr types.str) "top-isolated-islands-centeredWorkspaces" "The waybar style to use";
    extraStyle = mkOpt types.str "" "Additional style to add to waybar";
    weatherLocation = mkOpt types.str "" "Location for weather display in waybar";
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      inherit (cfg) settings;
    };

    home.packages = [
      # Weather module support
      pkgs.wttrbar
    ];

    spirenix.desktop.hyprland.extraWinRules.layerrule = [
      {
        name = "waybar-blur";
        "match:namespace" = "waybar";
        blur_popups = true;
      }
    ];
  };
}
