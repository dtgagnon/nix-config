{
  lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;
  cfg = config.${namespace}.apps.proton-cloud;
in
{
  options.${namespace}.apps.proton-cloud = {
    enable = mkBoolOpt false "Enable Proton Cloud Suite";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      proton-pass
      protonmail-desktop
    ];

    services.protonmail-bridge = {
      enable = false;
      package = pkgs.protonmail-bridge;
      # path = [ ];
    };
  };
}
