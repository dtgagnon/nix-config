# modules/nixos/services/mail-server/default.nix
#
# Local IMAP server for phone access via Tailscale.
# Serves user's Maildir over IMAP, bound to Tailscale interface only.
{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.services.mail-server;
  userHome = config.users.users.${cfg.user}.home;
  mailLocation = "${userHome}/${cfg.mailDir}";
in
{
  options.${namespace}.services.mail-server = import ./options.nix {
    inherit lib namespace;
  };

  config = mkIf cfg.enable {
    # Declare sops secret for IMAP password
    sops.secrets."${cfg.passwordSecret}" = {
      mode = "0400";
      owner = "dovecot2";
    };

    services.dovecot2 = {
      enable = true;
      enableImap = true;
      enablePop3 = false;
      enableLmtp = false;

      mailGroup = "users";
      mailLocation = "maildir:${mailLocation}:LAYOUT=fs";

      extraConfig = ''
        # Only listen on Tailscale interface
        listen = ${cfg.tailscaleIP}

        # Protocols
        protocols = imap

        # No TLS - Tailscale provides encryption
        ssl = no

        # Authentication
        auth_mechanisms = plain login
        disable_plaintext_auth = no

        # Password database - sops secret
        passdb {
          driver = passwd-file
          args = ${config.sops.secrets."${cfg.passwordSecret}".path}
        }

        # User database - static, single user
        userdb {
          driver = static
          args = uid=${cfg.user} gid=users home=${userHome}
        }

        # Mailbox configuration
        namespace inbox {
          inbox = yes
          separator = /

          mailbox Drafts {
            auto = subscribe
            special_use = \Drafts
          }
          mailbox Sent {
            auto = subscribe
            special_use = \Sent
          }
          mailbox Trash {
            auto = subscribe
            special_use = \Trash
          }
          mailbox Archive {
            auto = subscribe
            special_use = \Archive
          }
          mailbox Junk {
            auto = subscribe
            special_use = \Junk
          }
        }

        # Logging
        log_path = /var/log/dovecot.log
        info_log_path = /var/log/dovecot-info.log
      '';
    };

    # Firewall - allow IMAP on Tailscale interface
    networking.firewall.interfaces."tailscale0" = {
      allowedTCPPorts = [ cfg.imapPort ];
    };
  };
}
