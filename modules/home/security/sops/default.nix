{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.security.sops;
  user = config.${namespace}.user.name;
in
{
  options.${namespace}.security.sops = {
    enable = mkBoolOpt true "Enable sops for home-manager users";
  };

  config = mkIf cfg.enable {
    sops = {
      age.keyFile = "/home/${user}/.config/sops/age/keys.txt";
    };

    defaultSopsFile = ../../../../secrets.yaml;
    validateSopsFiles = false;

    secrets = {
      "ssh-keys/dtgagnon-key".path = "/home/${user}/.ssh/${user}-key";
      "ssh-keys/dtgagnon-key.pub".path = "/home/${user}/.ssh/${user}-key.pub";
    };
  };
}
