{
  lib,
  host,
  pkgs,
  inputs,
  config,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    attrNames
    attrValues
    ;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.security.sops-nix;
  secretsPath = builtins.toString inputs.nix-secrets;

  # Import option types and helpers
  opts = import ./options.nix { inherit lib pkgs namespace; };
in
{
  options.${namespace}.security.sops-nix = {
    enable = mkBoolOpt true "Enable sops secrets management";
    targetHost = mkOpt types.str "${host}" "Define the configuration's target host";

    inject = mkOption {
      type = types.attrsOf opts.injectSubmodule;
      default = { };
      description = ''
        Secret injection definitions. Each injection groups related secrets together
        and can generate environment files, patch config files, or provide wrapper arguments.

        Example:
        ```nix
        spirenix.security.sops-nix.inject.my-service = {
          secrets.API_KEY.sopsPath = "my-service/api-key";
          secrets.DB_PASS.sopsPath = "my-service/db-password";
          files."/etc/my-service/config.yaml".owner = "my-service";
          envFile.owner = "my-service";
          before = [ "my-service.service" ];
        };

        # Then use placeholders in your config:
        services.my-service.settings.apiKey =
          config.spirenix.security.sops-nix.inject.my-service.secrets.API_KEY.placeholder;
        ```
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Base sops-nix configuration
    {
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
        # Service-specific secrets should be declared in their respective modules.
      };

      # Keep age keys safe when using impermanence on the root filesystem.
      ${namespace}.system.preservation = {
        # Ensure the sops-nix state directory persists across rebuilds.
        extraSysDirs = [ "var/lib/sops-nix" ];
        # Symlink the user's age key into the persistence layer.
        extraSysFiles = [
          {
            file = "/home/dtgagnon/.config/sops/age/keys.txt";
            how = "symlink";
            mode = "0600";
          }
        ];
      };
    }

    # Auto-declare sops.secrets for all injections
    (mkIf (cfg.inject != { }) {
      sops.secrets = opts.collectSopsSecrets cfg.inject;
    })

    # Secret injector systemd service
    (mkIf (cfg.inject != { } && opts.needsInjectorService cfg.inject) {
      # Create the /run/secrets-env directory
      systemd.tmpfiles.rules = [ "d /run/secrets-env 0755 root root -" ];

      systemd.services.secret-injector = {
        description = "Inject secrets into config files and generate env files";
        wantedBy = [ "multi-user.target" ];

        # Run after sops-nix has decrypted secrets
        # sops-nix uses either activation scripts or sops-install-secrets.service
        after = [
          "sops-install-secrets.service"
          "network.target"
        ];
        wants = [ "sops-install-secrets.service" ];

        # Run before services that need the injected secrets
        before = opts.collectBeforeDeps cfg.inject;

        path = [
          pkgs.coreutils
          pkgs.gnused
        ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = opts.mkInjectorScript cfg.inject;

          # Security hardening
          ProtectSystem = "strict";
          ReadWritePaths = [
            "/run/secrets-env"
          ]
          ++ (attrNames (builtins.foldl' (acc: inj: acc // inj.files) { } (attrValues cfg.inject)));
          PrivateTmp = true;
          NoNewPrivileges = true;
        };
      };
    })
  ]);
}
