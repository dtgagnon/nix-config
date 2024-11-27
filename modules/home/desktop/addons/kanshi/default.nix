{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.kanshi;
in {
  options.${namespace}.desktop.addons.kanshi = {
    enable = mkBoolOpt false "Whether to enable Kanshi in the desktop environment.";
  };

  config = mkIf cfg.enable {
    services.kanshi = {
      enable = true;
      package = pkgs.kanshi;
      systemdTarget = "";
      settings = [
        {
          profile.name = "main_workstation";
          profile.outputs = [
            {
              criteria = "AOC CU34G2X";
              mode = "3440x1440@144Hz";
              position = "0,0";
            }
          ];
        }
      ];
    };
  };
}
