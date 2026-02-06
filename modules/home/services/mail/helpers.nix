# modules/home/services/mail/helpers.nix
#
# Config generation helpers for mail module.
{
  lib,
  config,
  cfg,
}:
let
  inherit (lib) mapAttrsToList concatStringsSep attrValues findFirst head filter;
  homeDir = config.home.homeDirectory;
  mailDir = "${homeDir}/${cfg.mailDir}";

  # Common defaults for all accounts
  commonDefaults = {
    realName = "";
    primary = false;
    folders = [ "INBOX" "Sent" "Drafts" "Trash" "Archive" ];
  };

  # Provider-specific defaults (for accounts imported without submodule processing)
  providerDefaults = {
    gmail = {
      imapHost = "imap.gmail.com";
      imapPort = 993;
      useTls = true;
    };
    protonmail = {
      imapHost = "127.0.0.1";
      imapPort = 1143;
      useTls = false;
    };
    mxroute = {
      imapHost = "ireland.mxrouting.net";
      imapPort = 993;
      useTls = true;
    };
    imap = {
      imapHost = "";
      imapPort = 993;
      useTls = true;
    };
  };

  # Apply provider defaults to an account
  withDefaults = acc:
    let
      providerDefs = providerDefaults.${acc.provider or "imap"};
    in
    commonDefaults // providerDefs // acc;
in
rec {
  # Get primary account field value
  getPrimaryAccount =
    accounts: field:
    let
      accountList = map withDefaults (attrValues accounts);
      primaryAccount = findFirst (acc: acc.primary) (head accountList) accountList;
    in
    primaryAccount.${field} or "";

  # Get semicolon-separated list of non-primary emails
  getOtherEmails =
    accounts:
    let
      accountList = map withDefaults (attrValues accounts);
      primaryEmail = getPrimaryAccount accounts "email";
      otherEmails = filter (e: e != primaryEmail) (map (acc: acc.email) accountList);
    in
    concatStringsSep ";" otherEmails;

  # Generate mbsync config for a single account
  mkMbsyncAccount =
    name: accRaw:
    let
      acc = withDefaults accRaw;
      # Include spam folder if defined
      allFolders = acc.folders ++ (lib.optional (acc.spamFolder or null != null) acc.spamFolder);
      tlsType =
        if acc.provider == "protonmail" then
          "STARTTLS"
        else if acc.useTls then
          "IMAPS"
        else
          "None";
      certLine =
        if acc.provider == "protonmail" && acc.certificateSecret or null != null then
          "CertificateFile ${config.sops.secrets."mail-${name}-certificate".path}"
        else
          "";
      passPath = config.sops.secrets."mail-${name}-password".path or "/run/secrets-d/mail-${name}-password";
    in
    ''
      IMAPAccount ${name}
      Host ${acc.imapHost}
      Port ${toString acc.imapPort}
      User ${acc.email}
      PassCmd "cat ${passPath}"
      SSLType ${sslType}
      ${certLine}

      IMAPStore ${name}-remote
      Account ${name}

      MaildirStore ${name}-local
      SubFolders Verbatim
      Path ${mailDir}/${acc.email}/
      Inbox ${mailDir}/${acc.email}/INBOX

      Channel ${name}
      Far :${name}-remote:
      Near :${name}-local:
      Patterns ${concatStringsSep " " (map (f: ''"${f}"'') allFolders)}
      Create Both
      Expunge Both
      SyncState *
    '';

  # Generate full mbsync config
  mkMbsyncConfig = accounts: concatStringsSep "\n\n" (mapAttrsToList mkMbsyncAccount accounts);
}
