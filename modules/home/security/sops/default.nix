{ lib
, inputs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.security.sops;
  user = config.${namespace}.user.name;
  secretsPath = builtins.toString inputs.nix-secrets;
in
{
  options.${namespace}.security.sops = {
    enable = mkBoolOpt true "Enable sops for home-manager users";
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = "${secretsPath}/secrets.yaml";
      validateSopsFiles = false;

      age.keyFile = "/persist/home/${user}/.config/sops/age/keys.txt";

      secrets = {
        "ssh-keys/${user}-key".path = "/persist/home/${user}/.ssh/${user}-key";
        "ssh-keys/${user}-key.pub".path = "/persist/home/${user}/.ssh/${user}-key.pub";
      };
    };
  };
}
