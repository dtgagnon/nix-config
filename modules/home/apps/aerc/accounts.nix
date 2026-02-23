# Account configuration generators for aerc
# Provides mkAercAccount and mkQueryMap functions
{
  lib,
  config,
  namespace,
}:
let
  inherit (lib) optionalString replaceStrings;

  mailCfg = config.${namespace}.services.mail;
  homeDir = config.home.homeDirectory;
  mailDir = "${homeDir}/${mailCfg.mailDir}";

  # URL-encode email address for use in SMTP URLs (@ -> %40)
  urlEncodeEmail = email: replaceStrings [ "@" ] [ "%40" ] email;

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
      # Username is URL-encoded in the SMTP URL for explicit authentication
      encodedEmail = urlEncodeEmail acc.email;

      # Translate logical folder names to provider-specific names (e.g., Gmail's [Gmail]/Drafts)
      tr = mailHelpers.translateFolder acc.provider;
      # With notmuch, use the actual maildir-relative path (e.g., user@example.com/Sent)
      # so aerc can write to the correct directory for copy-to/archive/postpone operations.
      # With plain maildir, use the provider-translated folder name directly.
      folderPath = folder: if mailCfg.notmuch.enable then "${acc.email}/${tr folder}" else tr folder;

      smtpConfig =
        {
          gmail = {
            outgoing = "smtp+plain://${encodedEmail}@smtp.gmail.com:587";
            outgoingCredCmd = "cat ${passPath}";
          };
          protonmail = {
            outgoing = "smtp+plain://${encodedEmail}@127.0.0.1:1025";
            outgoingCredCmd = "cat ${passPath}";
          };
          mxroute = {
            outgoing = "smtps://${encodedEmail}@fusion.mxrouting.net:465";
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
      from = ${if acc.realName != "" then "${acc.realName} <${acc.email}>" else acc.email}
      ${if smtpConfig.outgoing != "" then "outgoing = ${smtpConfig.outgoing}" else ""}
      ${
        if smtpConfig.outgoingCredCmd != "" then "outgoing-cred-cmd = ${smtpConfig.outgoingCredCmd}" else ""
      }
      default = ${if acc.primary then "INBOX" else ""}
      copy-to = ${folderPath "Sent"}
      archive = ${folderPath "Archive"}
      postpone = ${folderPath "Drafts"}
      folders-sort = INBOX,Drafts,Sent,Archive,Spam,Trash
      ${queryMap}
    '';

  # Generate notmuch query map for account filtering (static - kept for reference)
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

  # Generate shell script to dynamically create query map from maildir structure
  mkQueryMapScript =
    name: acc: ''
      QUERYMAP="${mailDir}/.notmuch/querymap-${name}"
      ACCOUNT_DIR="${mailDir}/${acc.email}"

      # Ensure .notmuch directory exists
      mkdir -p "${mailDir}/.notmuch"

      # Only generate if account directory exists
      if [ -d "$ACCOUNT_DIR" ]; then
        # Start fresh query map
        echo "# Auto-generated query map for ${name}" > "$QUERYMAP"

        # Find all directories in the account folder and generate query entries
        # Exclude hidden directories and special maildir folders (cur, new, tmp)
        find "$ACCOUNT_DIR" -type d -not -path '*/\.*' -not -name 'cur' -not -name 'new' -not -name 'tmp' | while read -r dir; do
          # Get relative path from account directory
          folder="''${dir#$ACCOUNT_DIR/}"

          # Skip if it's the account directory itself
          if [ "$folder" != "$ACCOUNT_DIR" ] && [ -n "$folder" ]; then
            # Generate query map entry
            echo "$folder=folder:\"${acc.email}/$folder\"" >> "$QUERYMAP"
          fi
        done

        # Ensure INBOX is always present even if not yet created
        if ! grep -q "^INBOX=" "$QUERYMAP"; then
          echo "INBOX=folder:\"${acc.email}/INBOX\"" >> "$QUERYMAP"
        fi

        $VERBOSE_ECHO "Generated query map for ${name} with $(wc -l < "$QUERYMAP") folders"
      else
        $VERBOSE_ECHO "Warning: Account directory $ACCOUNT_DIR does not exist yet for ${name}"
        # Create minimal query map with INBOX
        mkdir -p "$(dirname "$QUERYMAP")"
        echo "INBOX=folder:\"${acc.email}/INBOX\"" > "$QUERYMAP"
      fi
    '';
}
