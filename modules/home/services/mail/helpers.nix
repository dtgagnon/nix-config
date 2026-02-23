# modules/home/services/mail/helpers.nix
#
# Config generation helpers for mail module.
{
  lib,
  config,
  cfg,
  pkgs,
}:
let
  inherit (lib) mapAttrsToList findFirst;
  homeDir = config.home.homeDirectory;
  mailDir = "${homeDir}/${cfg.mailDir}";

  # Common defaults for all accounts
  commonDefaults = {
    realName = "";
    primary = false;
    folders = [
      "INBOX"
      "Sent"
      "Drafts"
      "Trash"
      "Archive"
    ];
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
      imapHost = "fusion.mxrouting.net";
      imapPort = 993;
      useTls = true;
    };
    imap = {
      imapHost = "";
      imapPort = 993;
      useTls = true;
    };
  };

  # Map logical folder names to Gmail's actual IMAP folder names.
  # Gmail uses [Gmail]/... prefixed special folders instead of standard names.
  gmailFolderMap = {
    "Sent" = "[Gmail]/Sent Mail";
    "Drafts" = "[Gmail]/Drafts";
    "Trash" = "[Gmail]/Trash";
    "Archive" = "[Gmail]/All Mail";
    "Starred" = "[Gmail]/Starred";
  };

  # Translate a logical folder name to the provider's actual IMAP folder name
  translateFolder =
    provider: folder: if provider == "gmail" then gmailFolderMap.${folder} or folder else folder;

  # Apply provider defaults to an account
  withDefaults =
    acc:
    let
      providerDefs = providerDefaults.${acc.provider or "imap"};
    in
    commonDefaults // providerDefs // acc;
in
rec {
  inherit translateFolder;

  # Generate notification script for new mail
  mkNotificationScript =
    accounts:
    let
      notmuch = "${pkgs.notmuch}/bin/notmuch";
      notifySend = "${pkgs.libnotify}/bin/notify-send";
      jq = "${pkgs.jq}/bin/jq";

      accountBlocks = mapAttrsToList (name: acc: ''
                _count=$(${notmuch} count "tag:notify-pending AND path:${acc.email}/**" 2>/dev/null || echo 0)
                if [ "$_count" -gt 0 ]; then
                  _senders=$(${notmuch} address --format=json --output=sender --deduplicate=no \
                    "tag:notify-pending AND path:${acc.email}/**" 2>/dev/null \
                    | ${jq} -r '.[] | if .name != "" and .name != null then .name else .address end' \
                    | sort | uniq -c | sort -rn \
                    | sed 's/^ *\([0-9]*\) \(.*\)/\2: \1/')
                  BODY="$BODY## ${name}
        $_senders
        ---
        "
                  HAS_NEW=1
                fi
      '') accounts;
    in
    ''
      trap '${notmuch} tag -notify-pending -- tag:notify-pending 2>/dev/null || true' EXIT
      BODY=""
      HAS_NEW=0
      ${builtins.concatStringsSep "\n" accountBlocks}
      if [ "$HAS_NEW" = "1" ]; then
        ${notifySend} -u normal "New Messages" "$BODY" 2>/dev/null || true
      fi
    '';

  # Get primary account field value
  getPrimaryAccount =
    accounts: field:
    let
      accountList = map withDefaults (builtins.attrValues accounts);
      primaryAccount = findFirst (acc: acc.primary) (builtins.head accountList) accountList;
    in
    primaryAccount.${field} or "";

  # Get semicolon-separated list of non-primary emails
  getOtherEmails =
    accounts:
    let
      accountList = map withDefaults (builtins.attrValues accounts);
      primaryEmail = getPrimaryAccount accounts "email";
      otherEmails = builtins.filter (e: e != primaryEmail) (map (acc: acc.email) accountList);
    in
    builtins.concatStringsSep ";" otherEmails;

  # Generate mbsync config for a single account
  mkMbsyncAccount =
    name: accRaw:
    let
      acc = withDefaults accRaw;
      # Include spam folder if defined, then translate to provider-specific IMAP names
      rawFolders = acc.folders ++ (lib.optional (acc.spamFolder or null != null) acc.spamFolder);
      allFolders = map (translateFolder acc.provider) rawFolders;
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
      passPath =
        config.sops.secrets."mail-${name}-password".path or "/run/secrets-d/mail-${name}-password";
    in
    ''
      IMAPAccount ${name}
      Host ${acc.imapHost}
      Port ${toString acc.imapPort}
      User ${acc.email}
      PassCmd "cat ${passPath}"
      TLSType ${tlsType}
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
      Patterns ${builtins.concatStringsSep " " (map (f: ''"${f}"'') allFolders)}
      Create Both
      Expunge Both
      SyncState *
    '';

  # Generate full mbsync config
  mkMbsyncConfig =
    accounts: builtins.concatStringsSep "\n\n" (mapAttrsToList mkMbsyncAccount accounts);
}
