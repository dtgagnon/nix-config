{ lib
, pkgs
, inputs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.security.sops-nix;
  secretsPath = builtins.toString inputs.nix-secrets;
in
{
  options.${namespace}.security.sops-nix = {
    enable = mkBoolOpt true "Enable sops secrets management";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.sops ];

    sops = {
      defaultSopsFile = "${secretsPath}/secrets.yaml";
      validateSopsFiles = false;

      age = {
        # automatically import host SSH keys as age keys
        sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
        # this will use an age key that is expected to already be in the filesystem
        keyFile = "/persist/var/lib/sops-nix/key.txt";
        # generate a new key if the key specified above does not exist
        generateKey = true;
      };

      #NOTE See modules/nixos/users/default.nix for user secrets.
      secrets = {
        #NOTE Secrets will be output to /run/secrets.
        # General secrets declarations. Most will/should be in their respective modules.

        # "syncthing/webui-password" = { owner = "dtgagnon"; };
        # "syncthing/key" = { };
        tailscale-authKey = { };
        openai_api = { };
        anthropic_api = { };
      };
    };
  };
}
