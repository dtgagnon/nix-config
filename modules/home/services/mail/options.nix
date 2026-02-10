# modules/home/services/mail/options.nix
#
# Option definitions for the mail module.
{
  lib,
  namespace,
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;
  inherit (lib.${namespace}) mkBoolOpt;

  # Account type submodule
  accountModule = types.submodule (
    { name, config, ... }:
    {
      options = {
        enable = mkBoolOpt true "Enable this email account";

        email = mkOption {
          type = types.str;
          description = "Email address for this account";
          example = "user@example.com";
        };

        realName = mkOption {
          type = types.str;
          default = "";
          description = "Real name for this account";
        };

        provider = mkOption {
          type = types.enum [
            "gmail"
            "protonmail"
            "mxroute"
            "imap"
          ];
          description = "Email provider type";
        };

        imapHost = mkOption {
          type = types.str;
          default =
            {
              gmail = "imap.gmail.com";
              protonmail = "127.0.0.1";
              mxroute = "fusion.mxrouting.net";
              imap = "";
            }
            .${config.provider};
          description = "IMAP server hostname";
        };

        imapPort = mkOption {
          type = types.int;
          default =
            {
              gmail = 993;
              protonmail = 1143;
              mxroute = 993;
              imap = 993;
            }
            .${config.provider};
          description = "IMAP server port";
        };

        useTls = mkOption {
          type = types.bool;
          default = config.provider != "protonmail";
          description = "Use TLS/SSL for IMAP connection";
        };

        passwordSecret = mkOption {
          type = types.str;
          description = "sops secret path for password";
          example = "mail/gmail-app-password";
        };

        certificateSecret = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "sops secret path for certificate (protonmail-bridge only)";
          example = "mail/protonmail-bridge-cert";
        };

        folders = mkOption {
          type = types.listOf types.str;
          default = [
            "INBOX"
            "Sent"
            "Drafts"
            "Trash"
            "Archive"
          ];
          description = "Folders to sync";
        };

        spamFolder = mkOption {
          type = types.nullOr types.str;
          default =
            {
              gmail = "[Gmail]/Spam";
              protonmail = "Spam";
              mxroute = "Junk";
              imap = "Junk";
            }
            .${config.provider};
          description = "Spam/Junk folder name (provider-specific default)";
        };

        primary = mkBoolOpt false "Mark as primary account";
      };
    }
  );
in
{
  enable = mkEnableOption "Enable unified mail infrastructure";

  accounts = mkOption {
    type = types.attrsOf accountModule;
    default = { };
    description = "Email accounts to configure";
  };

  mailDir = mkOption {
    type = types.str;
    default = "Mail";
    description = "Mail directory relative to home (e.g., 'Mail' for ~/Mail)";
  };

  mbsync = {
    enable = mkBoolOpt true "Enable mbsync for IMAP sync";
    frequency = mkOption {
      type = types.str;
      default = "*:0/5";
      description = "Systemd calendar expression for sync frequency";
    };
  };

  notmuch = {
    enable = mkBoolOpt true "Enable notmuch for indexing";
    synchronizeFlags = mkBoolOpt false ''
      Sync notmuch tags to/from maildir flags.
      WARNING: Enable only if you understand the implications.
      When true, notmuch tag changes modify maildir filenames,
      which can cause sync conflicts with mbsync.
    '';
    postNewHook = mkOption {
      type = types.lines;
      default = "";
      description = "Script to run after notmuch indexes new mail (account tagging, etc.)";
      example = ''
        notmuch tag +gmail -- path:user@gmail.com/** and tag:unread
        notmuch tag -unread -- tag:unread
      '';
    };
  };

  protonmail-bridge = {
    enable = mkBoolOpt false "Enable protonmail-bridge";
  };
}
