{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.hardware.laptop;
in
{
  options.${namespace}.hardware.laptop = {
    enable = mkBoolOpt false "Enable laptop specific configurations";
  };

  config = mkIf cfg.enable {
    services.logind = {
      lidSwitch = "ignore";
      lidSwitchExternalPower = "ignore";
      extraConfig = ''
        HandleLidSwitchDocked=ignore
        LidSwitchIgnoreInhibited=no
      '';
    };
  };
}
