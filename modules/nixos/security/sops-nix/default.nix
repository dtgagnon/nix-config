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
  username = config.${namespace}.user.name;
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

      # NOTE: Secrets will be output to /run/secrets (e.g. /run/secrets/dtgagnon-password)
      # Secrets required for user creation are handled in respective ./users/<username>.nix files because they will be output to /run/secrets-for-users and only when the user is assigned to a host.
      secrets = {
        "ssh-keys/${username}-key" = {
          owner = "${username}";
          path = "/persist/home/${username}/.ssh/${username}-key";
        };
        "ssh-keys/${username}-key.pub" = {
          owner = "${username}";
          path = "/persist/home/${username}/.ssh/${username}-key.pub";
        };
        # "syncthing/webui-password" = { owner = "dtgagnon"; };
        # "syncthing/key" = { };
        tailscale-authKey = { };
        openai_api = { };
        anthropic_api = { };
      };
    };
  };
}
