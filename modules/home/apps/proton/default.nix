{ 
  lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.proton;
in
{
  options.${namespace}.apps.proton = {
    enable = mkBoolOpt false "Enable Proton Cloud Suite";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      proton-pass
      protonvpn-gui
      protonmail-desktop
    ];

    services.protonmail-bridge = {
      enable = false;
      package = pkgs.protonmail-bridge;
      # path = [ ];
    };
  };
}
