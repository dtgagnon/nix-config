# modules/nixos/security/sops-nix/options.nix
#
# Option type definitions and helper functions for the sops-nix secret injection module.
# This file is imported by default.nix and provides all submodule types and computation helpers.
{
  lib,
  pkgs,
  namespace,
}:
let
  inherit (lib)
    mkOption
    types
    mapAttrsToList
    filterAttrs
    concatMapStringsSep
    attrNames
    attrValues
    optionalString
    escapeShellArg
    toUpper
    replaceStrings
    ;

  # Convert a name to uppercase with underscores (for placeholder generation)
  toPlaceholderName = name: toUpper (replaceStrings [ "-" "/" "." ] [ "_" "_" "_" ] name);

  # Generate a unique placeholder string for a secret
  makePlaceholder =
    injectName: varName: "__${toPlaceholderName injectName}_${toPlaceholderName varName}__";

  # Secret submodule - defines a single secret within an injection
  secretSubmodule =
    injectName:
    types.submodule (
      { name, config, ... }:
      {
        options = {
          sopsPath = mkOption {
            type = types.str;
            description = "Path to the secret in the sops yaml file (e.g., 'my-service/api-key')";
          };

          envVar = mkOption {
            type = types.str;
            default = toPlaceholderName name;
            description = "Environment variable name for this secret. Defaults to uppercase version of the secret name.";
          };

          # Read-only computed attributes
          placeholder = mkOption {
            type = types.str;
            readOnly = true;
            default = makePlaceholder injectName name;
            description = "Auto-generated placeholder string to use in config files. Use this in your NixOS config.";
          };

          secretPath = mkOption {
            type = types.str;
            readOnly = true;
            default = "/run/secrets/${replaceStrings [ "/" ] [ "-" ] config.sopsPath}";
            description = "Runtime path where sops-nix will place the decrypted secret.";
          };
        };
      }
    );

  # File target submodule - defines a file to patch
  fileSubmodule = types.submodule {
    options = {
      owner = mkOption {
        type = types.str;
        default = "root";
        description = "Owner of the patched file.";
      };

      group = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Group of the patched file. Defaults to owner's primary group.";
      };

      mode = mkOption {
        type = types.str;
        default = "0400";
        description = "Permissions mode of the patched file.";
      };
    };
  };

  # Env file submodule
  envFileSubmodule = types.submodule (
    { name, ... }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to generate an environment file for this injection.";
        };

        path = mkOption {
          type = types.str;
          default = "/run/secrets-env/${name}.env";
          description = "Path where the environment file will be written.";
        };

        owner = mkOption {
          type = types.str;
          default = "root";
          description = "Owner of the environment file.";
        };

        group = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Group of the environment file. Defaults to owner's primary group.";
        };

        mode = mkOption {
          type = types.str;
          default = "0400";
          description = "Permissions mode of the environment file.";
        };
      };
    }
  );

  # Main injection submodule
  injectSubmodule = types.submodule (
    { name, config, ... }:
    {
      options = {
        secrets = mkOption {
          type = types.attrsOf (secretSubmodule name);
          default = { };
          description = ''
            Secrets to inject. Each secret is a submodule with:
            - sopsPath: Path in the sops yaml file
            - envVar: Environment variable name (auto-generated from secret name)
            - placeholder: (read-only) Auto-generated placeholder string
            - secretPath: (read-only) Runtime path to decrypted secret
          '';
          example = {
            API_KEY.sopsPath = "my-service/api-key";
            DB_PASS.sopsPath = "my-service/db-password";
          };
        };

        includeEnvFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Optional: sops path to an existing environment file to include.
            This file will be sourced in addition to generated env vars.
          '';
          example = "my-service/extra-env";
        };

        files = mkOption {
          type = types.attrsOf fileSubmodule;
          default = { };
          description = ''
            Files to patch with secret values. The keys are file paths.
            Placeholders in these files will be replaced with actual secret values.
          '';
          example = {
            "/etc/my-service/config.yaml" = {
              owner = "my-service";
              mode = "0400";
            };
          };
        };

        envFile = mkOption {
          type = envFileSubmodule;
          default = { };
          description = ''
            Configuration for generating an environment file with all secrets as VAR=value lines.
          '';
        };

        before = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = ''
            Systemd units that should wait for secret injection to complete.
          '';
          example = [ "my-service.service" ];
        };

        # Read-only computed attributes
        envFilePath = mkOption {
          type = types.str;
          readOnly = true;
          default = config.envFile.path;
          description = "Path to the generated environment file.";
        };

        wrapperArgs = mkOption {
          type = types.str;
          readOnly = true;
          default =
            let
              secretExports = concatMapStringsSep " " (
                varName:
                let
                  secret = config.secrets.${varName};
                in
                "--run 'export ${secret.envVar}=$(cat ${escapeShellArg secret.secretPath})'"
              ) (attrNames config.secrets);
              includeSource =
                optionalString (config.includeEnvFile != null)
                  "--run 'set -a; source /run/secrets/${
                    replaceStrings [ "/" ] [ "-" ] config.includeEnvFile
                  }; set +a'";
            in
            "${secretExports}${optionalString (config.includeEnvFile != null) " ${includeSource}"}";
          description = ''
            Pre-generated arguments for wrapProgram to export all secrets.
            Use in wrapper scripts like: wrapProgram $out/bin/app ''${config...wrapperArgs}
          '';
        };

        exportScript = mkOption {
          type = types.str;
          readOnly = true;
          default =
            let
              secretExports = concatMapStringsSep "\n" (
                varName:
                let
                  secret = config.secrets.${varName};
                in
                "export ${secret.envVar}=$(cat ${escapeShellArg secret.secretPath})"
              ) (attrNames config.secrets);
              includeSource = optionalString (config.includeEnvFile != null) ''
                set -a
                source /run/secrets/${replaceStrings [ "/" ] [ "-" ] config.includeEnvFile}
                set +a
              '';
            in
            "${secretExports}${optionalString (config.includeEnvFile != null) "\n${includeSource}"}";
          description = ''
            Shell snippet to export all secrets as environment variables.
            Useful for activation scripts or systemd ExecStartPre.
          '';
        };
      };
    }
  );

  # Collect all secrets from all injections to declare to sops-nix
  collectSopsSecrets =
    injectConfigs:
    let
      injectSecrets = mapAttrsToList (
        _injectName: injectCfg:
        mapAttrsToList (_varName: secretCfg: {
          name = replaceStrings [ "/" ] [ "-" ] secretCfg.sopsPath;
          value = {
            key = secretCfg.sopsPath;
          };
        }) injectCfg.secrets
      ) (filterAttrs (_: v: v.secrets != { }) injectConfigs);

      # Include env files if specified
      envFileSecrets = mapAttrsToList (
        _injectName: injectCfg:
        if injectCfg.includeEnvFile != null then
          [
            {
              name = replaceStrings [ "/" ] [ "-" ] injectCfg.includeEnvFile;
              value = {
                key = injectCfg.includeEnvFile;
              };
            }
          ]
        else
          [ ]
      ) injectConfigs;
    in
    builtins.listToAttrs (builtins.concatLists (injectSecrets ++ envFileSecrets));

  # Collect all before dependencies from all injections
  collectBeforeDeps =
    injectConfigs: builtins.concatLists (mapAttrsToList (_: injectCfg: injectCfg.before) injectConfigs);

  # Check if any injections need the injector service
  needsInjectorService =
    injectConfigs:
    let
      hasFileInjections = builtins.any (injectCfg: injectCfg.files != { }) (attrValues injectConfigs);
      hasEnvFileGeneration = builtins.any (
        injectCfg: injectCfg.envFile.enable && injectCfg.secrets != { }
      ) (attrValues injectConfigs);
    in
    hasFileInjections || hasEnvFileGeneration;

  # Generate the injection script
  mkInjectorScript =
    injectConfigs:
    pkgs.writeShellScript "secret-injector" ''
      set -euo pipefail

      # Helper function to safely replace placeholders in files
      # Uses a temp file and atomic move for safety
      patch_file() {
        local src="$1"
        local dest="$2"
        local owner="$3"
        local group="$4"
        local mode="$5"
        shift 5

        # Copy source to temp file
        local tmpfile
        tmpfile=$(mktemp)
        cp "$src" "$tmpfile"

        # Apply all sed replacements (pairs of placeholder, secret_file)
        while [ $# -ge 2 ]; do
          local placeholder="$1"
          local secret_file="$2"
          shift 2

          if [ -f "$secret_file" ]; then
            local secret_value
            # Read secret, escape special sed characters
            secret_value=$(cat "$secret_file" | sed 's/[&/\]/\\&/g' | tr -d '\n')
            sed -i "s|$placeholder|$secret_value|g" "$tmpfile"
          else
            echo "Warning: Secret file $secret_file not found" >&2
          fi
        done

        # Set ownership and permissions
        chown "$owner:$group" "$tmpfile"
        chmod "$mode" "$tmpfile"

        # Atomic move to destination
        mv "$tmpfile" "$dest"
      }

      # Helper function to generate env file
      generate_env_file() {
        local dest="$1"
        local owner="$2"
        local group="$3"
        local mode="$4"
        shift 4

        local tmpfile
        tmpfile=$(mktemp)

        # Write VAR=value pairs (pairs of envvar, secret_file)
        while [ $# -ge 2 ]; do
          local envvar="$1"
          local secret_file="$2"
          shift 2

          if [ -f "$secret_file" ]; then
            local secret_value
            secret_value=$(cat "$secret_file" | tr -d '\n')
            echo "$envvar=$secret_value" >> "$tmpfile"
          else
            echo "Warning: Secret file $secret_file not found" >&2
          fi
        done

        # Set ownership and permissions
        chown "$owner:$group" "$tmpfile"
        chmod "$mode" "$tmpfile"

        # Create parent directory if needed
        mkdir -p "$(dirname "$dest")"

        # Atomic move
        mv "$tmpfile" "$dest"
      }

      ${concatMapStringsSep "\n" (
        injectName:
        let
          injectCfg = injectConfigs.${injectName};
          secretsList = attrValues injectCfg.secrets;

          # Generate file patching commands
          filePatches = concatMapStringsSep "\n" (
            filePath:
            let
              fileCfg = injectCfg.files.${filePath};
              group = if fileCfg.group != null then fileCfg.group else fileCfg.owner;
              # Build pairs of placeholder and secret path
              patchArgs = concatMapStringsSep " " (
                secret: "${escapeShellArg secret.placeholder} ${escapeShellArg secret.secretPath}"
              ) secretsList;
            in
            ''
              echo "Patching ${filePath} for ${injectName}..."
              patch_file ${escapeShellArg filePath} ${escapeShellArg filePath} \
                ${escapeShellArg fileCfg.owner} ${escapeShellArg group} ${escapeShellArg fileCfg.mode} \
                ${patchArgs}
            ''
          ) (attrNames injectCfg.files);

          # Generate env file command
          envFileCmd =
            if injectCfg.envFile.enable && injectCfg.secrets != { } then
              let
                envCfg = injectCfg.envFile;
                group = if envCfg.group != null then envCfg.group else envCfg.owner;
                # Build pairs of envvar and secret path
                envArgs = concatMapStringsSep " " (
                  secret: "${escapeShellArg secret.envVar} ${escapeShellArg secret.secretPath}"
                ) secretsList;
              in
              ''
                echo "Generating env file ${envCfg.path} for ${injectName}..."
                generate_env_file ${escapeShellArg envCfg.path} \
                  ${escapeShellArg envCfg.owner} ${escapeShellArg group} ${escapeShellArg envCfg.mode} \
                  ${envArgs}
              ''
            else
              "";
        in
        ''
          # === Injection: ${injectName} ===
          ${filePatches}
          ${envFileCmd}
        ''
      ) (attrNames injectConfigs)}

      echo "Secret injection complete."
    '';
in
{
  # Export the main injection submodule type
  inherit injectSubmodule;

  # Export collection/computation helpers (as functions taking inject configs)
  inherit
    collectSopsSecrets
    collectBeforeDeps
    needsInjectorService
    mkInjectorScript
    ;
}
