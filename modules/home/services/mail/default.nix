# modules/home/services/mail/default.nix
#
# User-scoped mail infrastructure:
#   External providers ←─ mbsync ─→ ~/Mail/ ←─ notmuch ─→ emma
{
  lib,
  pkgs,
  config,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkMerge mkDefault filterAttrs mapAttrs' nameValuePair optionalAttrs;

  cfg = config.${namespace}.services.mail;
  emmaCfg = config.${namespace}.services.emma;
  secretsPath = toString inputs.nix-secrets;

  # Derive account name from email domain (matches emma's Python logic)
  deriveAccountName = email:
    let
      domain = lib.last (lib.splitString "@" email);
    in
    builtins.head (lib.splitString "." domain);

  # Import accounts from private nix-secrets repo
  accountsFile = "${secretsPath}/mail-accounts.nix";
  importedAccounts =
    if builtins.pathExists accountsFile
    then import accountsFile
    else { };

  # Filter enabled accounts (now properly processed through submodule)
  enabledAccounts = filterAttrs (_: acc: acc.enable) cfg.accounts;

  # Import helper functions
  helpers = import ./helpers.nix { inherit lib config cfg; };

  homeDir = config.home.homeDirectory;
  mailDir = "${homeDir}/${cfg.mailDir}";
in
{
  options.${namespace}.services.mail = import ./options.nix {
    inherit lib namespace;
  };

  config = mkIf cfg.enable (mkMerge [
    # Import accounts from secrets as defaults (goes through submodule for proper typing)
    {
      ${namespace}.services.mail.accounts = lib.mapAttrs (_: mkDefault) importedAccounts;
    }

    # Base packages
    {
      home.packages = with pkgs; [ isync notmuch mblaze ];

      # Ensure mail directory exists
      home.activation.createMailDir = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${mailDir}"
      '';
    }

    # mbsync
    (mkIf cfg.mbsync.enable {
      # Declare sops secrets for each account
      sops.secrets = lib.mapAttrs' (
        name: acc:
        lib.nameValuePair "mail-${name}-password" {
          key = acc.passwordSecret;
        }
      ) enabledAccounts;

      # mbsync config file
      home.file.".mbsyncrc".text = helpers.mkMbsyncConfig enabledAccounts;

      # Systemd user service for mbsync
      systemd.user.services.mbsync = {
        Unit = {
          Description = "Mailbox synchronization";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.isync}/bin/mbsync -a";
          ExecStartPost = mkIf cfg.notmuch.enable "${pkgs.notmuch}/bin/notmuch new";
          TimeoutStartSec = "5min";
        };
      };

      # Systemd user timer for periodic sync
      systemd.user.timers.mbsync = {
        Unit.Description = "Mailbox sync timer";
        Timer = {
          OnCalendar = cfg.mbsync.frequency;
          Persistent = true;
          RandomizedDelaySec = "30s";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    })

    # notmuch
    (mkIf cfg.notmuch.enable {
      home.file.".notmuch-config".text = helpers.mkNotmuchConfig enabledAccounts;

      # Initialize notmuch on activation if needed
      home.activation.notmuchInit = config.lib.dag.entryAfter [ "createMailDir" ] ''
        if [ ! -d "${mailDir}/.notmuch" ]; then
          ${pkgs.notmuch}/bin/notmuch --config="$HOME/.notmuch-config" new || true
        fi
      '';
    })

    # protonmail-bridge (uses home-manager native service)
    (mkIf cfg.protonmail-bridge.enable {
      services.protonmail-bridge = {
        enable = true;
        package = pkgs.protonmail-bridge;
        extraPackages = [ pkgs.gnome-keyring ];
      };

      ${namespace}.preservation.directories = [
        ".config/protonmail"
        ".local/share/protonmail"
      ];
    })

    # Emma integration - pass mail accounts to emma
    # Only include fields that differ from emma's defaults
    (mkIf emmaCfg.enable {
      programs.emma.settings.maildirAccounts = mapAttrs' (
        name: acc:
        let
          derivedName = deriveAccountName acc.email;
          # Only include accountName if it differs from what emma would derive
          needsAccountName = name != derivedName;
        in
        nameValuePair acc.email (
          optionalAttrs needsAccountName { accountName = name; }
          // optionalAttrs acc.primary { default = true; }
        )
      ) enabledAccounts;
    })
  ]);
}
