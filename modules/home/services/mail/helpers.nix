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
  # Generate mbsync config for a single account
  mkMbsyncAccount =
    name: accRaw:
    let
      acc = withDefaults accRaw;
      sslType =
        if acc.provider == "protonmail" then
          "STARTTLS"
        else if acc.useTls then
          "IMAPS"
        else
          "None";
      certLine =
        if acc.provider == "protonmail" then
          "CertificateFile ${config.sops.secrets."mail-${name}-password".path or "/run/secrets-d/protonmail-bridge-cert"}"
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
      Patterns ${concatStringsSep " " (map (f: ''"${f}"'') acc.folders)}
      Create Both
      Expunge Both
      SyncState *
    '';

  # Generate full mbsync config
  mkMbsyncConfig = accounts: concatStringsSep "\n\n" (mapAttrsToList mkMbsyncAccount accounts);

  # Generate notmuch config
  mkNotmuchConfig =
    accounts:
    let
      accountList = map withDefaults (attrValues accounts);
      primaryAccount = findFirst (acc: acc.primary) (head accountList) accountList;
      allEmails = map (acc: acc.email) accountList;
      otherEmails = filter (e: e != primaryAccount.email) allEmails;
    in
    ''
      [database]
      path=${mailDir}

      [user]
      name=${primaryAccount.realName}
      primary_email=${primaryAccount.email}
      other_email=${concatStringsSep ";" otherEmails}

      [new]
      tags=unread;inbox
      ignore=.mbsyncstate;.strstrec;.isstrstrec

      [search]
      exclude_tags=deleted;spam

      [maildir]
      synchronize_flags=true
    '';
}
