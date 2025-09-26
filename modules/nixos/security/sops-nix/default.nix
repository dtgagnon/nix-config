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
    mkOption
    types
    mapAttrs
    mapAttrsToList
    filterAttrs
    recursiveUpdate
    mkMerge
    ;
  inherit (lib.${namespace}) mkBoolOpt mkOpt mkDeepAttrsOpt;
  cfg = config.${namespace}.security.sops-nix;
  secretsPath = builtins.toString inputs.nix-secrets;
in
{
  options.${namespace}.security.sops-nix = {
    enable = mkBoolOpt true "Enable sops secrets management";
    targetHost = mkOpt types.str "${host}" "Define the configuration's target host";
    # Collect plain-text consumers of sops secrets.
    plainTextSecrets =
      mkOpt
        # Enforce an attribute set keyed by alias names.
        (types.attrsOf (
          # Each alias becomes a submodule describing how the secret is used.
          types.submodule (
            { name, ... }:
            {
              options = {
                # Specify the source secret key inside the inventory.
                secret = mkOpt types.str name "Secret key in the sops inventory to expose as plaintext at runtime.";
                # Record who needs the secret for traceability.
                usedBy = mkOpt types.str name "Identifier for the consumer or option that requires this secret.";
                owner = mkOpt (types.nullOr types.str) null "Runtime owner applied to the rendered secret file.";
                group = mkOpt (types.nullOr types.str) null "Runtime group applied to the rendered secret file.";
                mode = mkOpt (types.nullOr types.str) null "Filesystem permissions for the rendered secret file.";
                # Allow writing the secret to a custom location.
                path = mkOpt (types.nullOr types.str) null "Override the default /run/secrets/<name> output path.";
                # Allow indicating how sops-nix should decode the secret.
                format =
                  mkOpt (types.nullOr types.str) null
                    "Optional sops-nix format hint (e.g. binary, json, yaml).";
                # Allow using a different sops file than the host default.
                sopsFile = mkOpt (types.nullOr types.str) null "Alternative sops file to read this secret from.";
                # Restart these systemd units when the secret changes.
                restartUnits =
                  mkOpt (types.listOf types.str) [ ]
                    "Systemd units to restart when this secret changes.";
                # Only reload these systemd units when the secret changes.
                reloadUnits =
                  mkOpt (types.listOf types.str) [ ]
                    "Systemd units to reload when this secret changes.";
                # Restart these user units when the secret refreshes.
                restartUserUnits =
                  mkOpt (types.listOf types.str) [ ]
                    "User units to restart when this secret changes.";
                # Delay activation until these users can read the secret.
                neededForUsers =
                  mkOpt (types.listOf types.str) [ ]
                    "Users that require this secret before activation completes.";
                # Allow passing arbitrary config to sops.secrets.<name>.
                extraConfig = mkDeepAttrsOpt { } "Additional attributes forwarded to config.sops.secrets.<name>.";
              };
            }
          )
        ))
        { }
        "Register plaintext secret consumers that still need sops-backed storage outside of the Nix store.";

    # Provide evaluated placeholder strings keyed by alias.
    secretStrings = mkOption {
      # Each entry is a plain string placeholder.
      type = types.attrsOf types.str;
      # Default to no entries until callers populate the registry.
      default = { };
      # Mark as internal to signal callers they shouldn't override it directly.
      internal = true;
      # Explain the intent in module documentation.
      description = ''
        Derived map of plainTextSecrets aliases to sops placeholder strings that resolve at activation time.
      '';
    };

    # Publish a diagnostic view of all registered secrets.
    plainTextSecretRegistry = mkOption {
      # Represent entries as attribute sets for readability.
      type = types.listOf types.attrs;
      # Default to an empty list when nothing is registered.
      default = [ ];
      # Mark as internal to deter manual overrides.
      internal = true;
      # Document how to use the diagnostic data.
      description = ''
        Diagnostic list of all registered plainTextSecrets entries, including their aliases and resolved placeholders.
      '';
    };
  };

  config = mkIf cfg.enable (
    let
      # Convert each registration into an entry for config.sops.secrets.
      plainTextSecretDeclarations = builtins.listToAttrs (
        # Walk every alias and entry pair.
        mapAttrsToList (
          _alias: entry:
          # Build a base attribute set with optional fields.
          let
            base = {
              owner = entry.owner;
              group = entry.group;
              mode = entry.mode;
              path = entry.path;
              format = entry.format;
              sopsFile = entry.sopsFile;
              restartUnits = entry.restartUnits;
              reloadUnits = entry.reloadUnits;
              restartUserUnits = entry.restartUserUnits;
              neededForUsers = entry.neededForUsers;
            };
            # Remove unset or empty values before passing to sops-nix.
            sanitized = filterAttrs (
              _: value: value != null && value != [ ] && value != "" && value != { }
            ) base;
          in
          {
            # Emit the real sops secret name as the attribute key.
            name = entry.secret;
            # Merge sanitized overrides with any extra configuration.
            value = recursiveUpdate sanitized entry.extraConfig;
          }
        ) cfg.plainTextSecrets
      );

      # Compute a map of aliases to sops placeholder references.
      secretStrings = mapAttrs (
        _alias: entry: config.sops.placeholder.${entry.secret}
      ) cfg.plainTextSecrets;

      # Build a list of entries with resolved placeholders for debugging.
      secretRegistry = mapAttrsToList (
        alias: entry:
        recursiveUpdate entry {
          inherit alias;
          placeholder = secretStrings.${alias};
        }
      ) cfg.plainTextSecrets;
    in
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
        # v General secrets declarations. Most will/should be in their respective modules.
        secrets = mkMerge [
          {
            # "syncthing/webui-password" = { owner = "dtgagnon"; };
            # "syncthing/key" = { };
            tailscale-authKey = { };
          }
          # Append generated secrets sourced from the registration option.
          plainTextSecretDeclarations
        ];
      };

      # Re-expose helper values and persistence settings under the namespace.
      ${namespace} = {
        security.sops-nix = {
          # Provide direct access to placeholder strings.
          secretStrings = secretStrings;
          # Provide a full diagnostic registry.
          plainTextSecretRegistry = secretRegistry;
        };

        # Keep age keys safe when using impermanence on the root filesystem.
        system.preservation = {
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
          # extraHomeFiles = [
          #   { file = ".config/sops/age/keys.txt"; how = "symlink"; mode = "0600"; }
          # ];
        };
      };
    }
  );
}
