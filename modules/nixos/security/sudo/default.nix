{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.security.sudo;
in
{
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
        				Defaults env_keep -= "HOME"
      '';
    };
  };
}
