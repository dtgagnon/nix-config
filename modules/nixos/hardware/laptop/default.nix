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
      settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
        LidSwitchIgnoreInhibited = "no";
      };
    };
  };
}
