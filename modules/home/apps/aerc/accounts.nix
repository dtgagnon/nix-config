# Account configuration generators for aerc
# Provides mkAercAccount and mkQueryMap functions
{
  lib,
  config,
  namespace,
}:
let
  inherit (lib) optionalString;

  mailCfg = config.${namespace}.services.mail;
  homeDir = config.home.homeDirectory;
  mailDir = "${homeDir}/${mailCfg.mailDir}";

  # Import mail helpers for provider-aware folder name translation
  mailHelpers = import ../../services/mail/helpers.nix {
    inherit lib config;
    cfg = mailCfg;
  };
in
{
  # Generate aerc account config for a single account
  mkAercAccount =
    name: acc:
    let
      # Use notmuch backend if enabled, otherwise maildir
      source =
        if mailCfg.notmuch.enable then "notmuch://${mailDir}" else "maildir://${mailDir}/${acc.email}";

      # For notmuch, filter to this account's mail
      queryMap =
        if mailCfg.notmuch.enable then "query-map = ${mailDir}/.notmuch/querymap-${name}" else "";

      passPath = config.sops.secrets."mail-${name}-password".path;

      # SMTP configuration based on provider
      smtpConfig =
        {
          gmail = {
            outgoing = "smtp+plain://smtp.gmail.com:587";
            outgoingCredCmd = "cat ${passPath}";
          };
          protonmail = {
            outgoing = "smtp+plain://127.0.0.1:1025";
            outgoingCredCmd = "cat ${passPath}";
          };
          mxroute = {
            outgoing = "smtps://fusion.mxrouting.net:465";
            outgoingCredCmd = "cat ${passPath}";
          };
          imap = {
            outgoing = "";
            outgoingCredCmd = "";
          };
        }
        .${acc.provider};
    in
    ''
      [${name}]
      source = ${source}
      from = ${acc.realName} <${acc.email}>
      ${if smtpConfig.outgoing != "" then "outgoing = ${smtpConfig.outgoing}" else ""}
      ${
        if smtpConfig.outgoingCredCmd != "" then "outgoing-cred-cmd = ${smtpConfig.outgoingCredCmd}" else ""
      }
      default = ${if acc.primary then "INBOX" else ""}
      copy-to = Sent
      archive = Archive
      postpone = Drafts
      folders-sort = INBOX,Drafts,Sent,Archive,Spam,Trash
      ${queryMap}
    '';

  # Generate notmuch query map for account filtering
  # Uses provider-aware folder translation (e.g., Gmail's "Sent" → "[Gmail]/Sent Mail")
  mkQueryMap =
    _name: acc:
    let
      tr = mailHelpers.translateFolder acc.provider;
    in
    ''
      INBOX=folder:"${acc.email}/INBOX"
      Sent=folder:"${acc.email}/${tr "Sent"}"
      Drafts=folder:"${acc.email}/${tr "Drafts"}"
      Trash=folder:"${acc.email}/${tr "Trash"}"
      Archive=folder:"${acc.email}/${tr "Archive"}"
      ${optionalString (acc.spamFolder or null != null) ''Spam=folder:"${acc.email}/${acc.spamFolder}"''}
    '';
}
