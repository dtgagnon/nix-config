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
        sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
        keyFile = "/persist/var/lib/sops-nix/key.txt";
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

    # Keep age keys safe when using impermanence on the root filesystem.
    ${namespace}.system.preservation = {
      # Ensure the sops-nix state directory persists across rebuilds.
      extraSysDirs = [ "var/lib/sops-nix" ];
      # Symlink the user's age key into the persistence layer.
      extraSysFiles = [
        { file = "/home/dtgagnon/.config/sops/age/keys.txt"; how = "symlink"; mode = "0600"; }
      ];
      # extraHomeFiles = [
      #   { file = ".config/sops/age/keys.txt"; how = "symlink"; mode = "0600"; }
      # ];
    };
  };
}
