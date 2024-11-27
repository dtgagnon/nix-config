{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.pyprland;
in
{
  options.${namespace}.desktop.addons.pyprland = {
    enable = mkBoolOpt false "Whether to enable pyprland.";
    extraConfig = mkOpt types.str "" "Extra configuration for pyprland plugins.";
  };

  config = mkIf cfg.enable {
    services.pyprland.enable = true;
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
      command = "foot --class kitty-dropterm -e yazi"
      class = "kitty-dropterm"
      size = "75% 60%"
    '' + cfg.extraConfig;
  };
}
