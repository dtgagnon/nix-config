# modules/nixos/services/mail-server/options.nix
#
# Option definitions for local IMAP server (dovecot).
{
  lib,
  namespace,
}:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  enable = mkEnableOption "Enable local IMAP server (dovecot) for Tailscale access";

  user = mkOption {
    type = types.str;
    description = "System user whose mail to serve";
    example = "dtgagnon";
  };

  mailDir = mkOption {
    type = types.str;
    default = "Mail";
    description = "Mail directory relative to user's home (e.g., 'Mail' for ~/Mail)";
  };

  tailscaleIP = mkOption {
    type = types.str;
    description = "Tailscale IP address to bind to (e.g., 100.x.x.x)";
    example = "100.64.0.1";
  };

  imapPort = mkOption {
    type = types.port;
    default = 143;
    description = "IMAP port to listen on";
  };

  passwordSecret = mkOption {
    type = types.str;
    default = "mail/imap";
    description = "Sops secret key for IMAP password file (format: user:{PLAIN}password)";
  };
}
