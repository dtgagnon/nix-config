{
  options,
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let cfg = config.${namespace}.security.sudo;
in {
  options.${namespace}.security.sudo = {
    enable = mkBoolOpt true "Whether or not to enable sudo.";
  };

  config = mkIf cfg.enable {
    # Enable and configure `sudo`.
    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
      extraRules = [{
        users = [ "dtgagnon" ];
        groups = [ "wheel" ];
        commands = [{
          command = "ALL";
          options = [ "NOPASSWD" ];
        }];
      }];
      extraConfig = ''
        Defaults env_keep += "*"
      '';
    };
  };
}
