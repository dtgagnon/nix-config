{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.discord;
in
{
  options.${namespace}.apps.discord = {
    enable = mkBoolOpt false "Enable Discord module";
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.discord.override {
        withOpenASAR = true;
        withVencord = true;
      })
    ];
  };
}