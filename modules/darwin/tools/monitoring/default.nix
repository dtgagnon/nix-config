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
  cfg = config.${namespace}.tools.monitoring;
in
{
  options.${namespace}.tools.monitoring = {
    enable = mkBoolOpt false "Enable monitoring utilities";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      btop
      htop
      glances
      hwinfo
    ];
  };
}
