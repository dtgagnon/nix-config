{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.proton-cloud;
in
{
  options.${namespace}.apps.proton-cloud = {
    enable = mkBoolOpt false "Enable Proton Cloud Suite";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      proton-pass
    ];

    services.protonmail-bridge = {
      enable = true;
      package = pkgs.protonmail-bridge;
      extraPackages = [ pkgs.gnome-keyring ];
    };
  };
}
