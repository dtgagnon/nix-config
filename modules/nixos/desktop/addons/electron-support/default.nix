{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.electron-support;
in
{
  options.${namespace}.desktop.addons.electron-support = {
    enable = mkBoolOpt false "Whether to enable electron support in the desktop environment.";
  };

  config = mkIf cfg.enable {
    spirenix.user.home.configFile."electron-flags.conf".text = ''
      --enable-features=UseOzonePlatform
      --ozone-platform=wayland
    '';

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}
