{ lib
, host
, config
, inputs
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.security.sops-nix;
  secretsPath = toString inputs.nix-secrets;
  user = config.${namespace}.user;
in
{
  options.${namespace}.security.sops-nix = {
    enable = mkBoolOpt false "Enable sops-nix secrets management for users";
  };

  config = mkIf cfg.enable {
    sops = {
      age.keyFile = "/home/${user.name}/.config/sops/age/keys.txt";
      defaultSopsFile = "${secretsPath}/sops/${host}.yaml";
      validateSopsFiles = false;
    };
  };
}
