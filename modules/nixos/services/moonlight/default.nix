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
  cfg = config.${namespace}.services.moonlight;
in
{
  options.${namespace}.services.moonlight = {
    enable = mkBoolOpt false "Enable Moonlight game streaming client";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      moonlight-qt
    ];
  };
}
