{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.looking-glass-client;
  user = config.${namespace}.user;
in
{
  options.${namespace}.apps.looking-glass-client = {
    enable = mkBoolOpt false "Whether or not to enable the Looking Glass client.";
  };

  config = mkIf cfg.enable {
    programs.looking-glass-client = {
      enable = true;
      package = pkgs.looking-glass-client;
      settings = {
        app = {
          allowDMA = true;
          shmFile = "/dev/kvmfr0";
        };
        win = {
          size = "1920x1080";
          autoResive = "yes";
          quickSpace = "yes";
        };
        input = {
          escapeKey = 56;
          rawMouse = "yes";
          mouseSens = 6;
        };
      };
    };
  };
}
