{ lib
, host
, pkgs
, inputs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.security.sops-nix;
  secretsPath = builtins.toString inputs.nix-secrets;
in
{
  options.${namespace}.security.sops-nix = {
    enable = mkBoolOpt true "Enable sops secrets management";
    targetHost = mkOpt types.str "${host}" "Define the configuration's target host";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.sops ];

    sops = {
      defaultSopsFile = "${secretsPath}/sops/${cfg.targetHost}.yaml";
      validateSopsFiles = false;

      age = {
        # automatically import host SSH keys as age keys
        sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
        # this will use an age key that is expected to already be in the filesystem
        keyFile = "/persist/var/lib/sops-nix/key.txt";
        # generate a new key if the key specified above does not exist
        generateKey = true;
      };

      #NOTE Secrets will be output to /run/secrets.
      #NOTE See modules/nixos/users/default.nix for user secrets.
      # v General secrets declarations. Most will/should be in their respective modules.
      secrets = {
        # "syncthing/webui-password" = { owner = "dtgagnon"; };
        # "syncthing/key" = { };
        tailscale-authKey = { };
      };
    };

    spirenix.system.preservation = {
      extraSysDirs = [ "var/lib/sops-nix" ];
      extraSysFiles = [
        { file = "/home/dtgagnon/.config/sops/age/keys.txt"; how = "symlink"; mode = "0600"; }
      ];
      # extraHomeFiles = [
      #   { file = ".config/sops/age/keys.txt"; how = "symlink"; mode = "0600"; }
      # ];
    };
  };
}
