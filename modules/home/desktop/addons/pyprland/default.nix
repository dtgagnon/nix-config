{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.pyprland;
in
{
  options.${namespace}.desktop.addons.pyprland = {
    enable = mkBoolOpt false "Whether to enable pyprland.";
    extraConfig = mkOpt types.str "" "Extra configuration for pyprland plugins.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.pyprland ];

    xdg.configFile."hypr/pyprland.toml".text = ''
      [pyprland]
      plugins = ["scratchpads"]

      [scratchpads.pwvucontrol]
      animation = "fromTop"
      command = "pwvucontrol"
      class = "pwvucontrol"
      size = "50% 80%"

      [scratchpads.term]
      animation = "fromTop"
      command = "ghostty --class ghostty-dropterm -e yazi"
      class = "ghostty-dropterm"
      size = "75% 60%"
    '' + cfg.extraConfig;
  };
}
