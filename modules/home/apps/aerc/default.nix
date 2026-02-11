# modules/home/apps/aerc/default.nix
#
# Terminal-based email client that integrates with the mail service module.
# Uses notmuch as the backend when available, or maildir directly.
{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    types
    mkMerge
    filterAttrs
    mapAttrsToList
    ;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.apps.aerc;

  stylixEnabled = config.stylix.enable or false;
  stylixStyleset = import ./styles.nix { inherit config; };

  mailCfg = config.${namespace}.services.mail;
  homeDir = config.home.homeDirectory;
  mailDir = "${homeDir}/${mailCfg.mailDir}";

  # Import mail helpers for provider-aware folder name translation
  mailHelpers = import ../../services/mail/helpers.nix {
    inherit lib config;
    cfg = mailCfg;
  };

  # Filter enabled mail accounts
  enabledAccounts = filterAttrs (_: acc: acc.enable) mailCfg.accounts;

  # Generate aerc account config for a single account
  mkAercAccount =
    name: acc:
    let
      # Use notmuch backend if enabled, otherwise maildir
      source =
        if mailCfg.notmuch.enable then "notmuch://${mailDir}" else "maildir://${mailDir}/${acc.email}";

      # For notmuch, filter to this account's mail
      queryMap =
        if mailCfg.notmuch.enable then
          ''
            query-map = ${mailDir}/.notmuch/querymap-${name}
          ''
        else
          "";

      passPath = config.sops.secrets."mail-${name}-password".path or "/run/secrets/mail-${name}-password";

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
      ${lib.optionalString (
        acc.spamFolder or null != null
      ) ''Spam=folder:"${acc.email}/${acc.spamFolder}"''}
    '';
in
{
  options.${namespace}.apps.aerc = {
    enable = mkBoolOpt false "Enable aerc terminal email client";

    useNotmuch = mkBoolOpt true "Use notmuch as the backend (requires mail.notmuch.enable)";

    extraConfig = mkOpt types.lines "" "Extra configuration to append to aerc.conf";
    extraBinds = mkOpt types.lines "" "Extra keybindings to append to binds.conf";
    extraAccounts = mkOpt types.lines "" "Extra account configuration to append to accounts.conf";
    stylesets = mkOpt (types.attrsOf types.str) { } "Custom stylesets for aerc";
    templates = mkOpt (types.attrsOf types.str) { } "Custom templates for aerc";
  };

  config = mkIf cfg.enable (mkMerge [
    # Base aerc configuration using structured extraConfig
    {
      programs.aerc = {
        enable = true;

        extraConfig = {
          general = {
            unsafe-accounts-conf = true;
            log-file = "~/.cache/aerc/aerc.log";
            log-level = "error";
          };
          ui = {
            index-columns = "date<20,name<25,flags>4,subject<*";
            column-date = "{{.DateAutoFormat .Date.Local}}";
            column-name = "{{index (.From | names) 0}}";
            column-flags = ''{{.Flags | join ""}}'';
            column-subject = "{{.ThreadPrefix}}{{.Subject}}";
            timestamp-format = "2006-01-02 15:04";
            this-day-time-format = "15:04";
            this-week-time-format = "Mon 15:04";
            this-year-time-format = "Jan 02";
            sidebar-width = 25;
            empty-message = "(no messages)";
            empty-dirlist = "(no folders)";
            mouse-enabled = true;
            which-key = true;
            new-message-bell = true;
            pinned-tab-marker = "\"\`\"";
            dirlist-left = "{{.Folder}}";
            dirlist-right = "{{if .Unread}}{{.Unread}}/{{end}}{{.Exists}}";
            sort = "-r date";
            next-message-on-delete = true;
            auto-mark-read = true;
            completion-delay = "250ms";
            completion-min-chars = 1;
            completion-popovers = true;
            border-char-vertical = "│";
            border-char-horizontal = "─";
            styleset-name = "default";
            icon-unread = "";
            icon-read = "";
            icon-flagged = "";
            icon-draft = "";
            icon-attachment = "";
          };
          statusline = {
            status-columns = "left<*,center>=,right>*";
            column-left = "[{{.Account}}] {{.StatusInfo}}";
            column-center = "{{.PendingKeys}}";
            column-right = "{{.TrayInfo}}";
            separator = " |";
            display-mode = "text";
          };
          viewer = {
            pager = "less -R";
            alternatives = "text/plain,text/html";
            show-headers = false;
            header-layout = "From|To,Cc|Bcc,Date,Subject";
            always-show-mime = false;
            parse-http-links = true;
          };
          compose = {
            editor = "$EDITOR";
            header-layout = "To|From,Subject";
            address-book-cmd = lib.optionalString mailCfg.notmuch.enable "${pkgs.notmuch}/bin/notmuch address %s";
            reply-to-self = false;
            no-attachment-warning = "^[^>]*attach";
          };
          templates = {
            template-dirs = "${config.xdg.configHome}/aerc/templates";
            quoted-reply = "quoted_reply";
            forwards = "forward_as_body";
          };
          hooks = lib.optionalAttrs mailCfg.notmuch.enable {
            mail-received = ''${pkgs.libnotify}/bin/notify-send "New mail from $AERC_FROM_NAME" "$AERC_SUBJECT"'';
          };
          multipart-converters = {
            "text/html" =
              "${pkgs.w3m}/bin/w3m -T text/html -cols 80 -dump -o display_image=false -o display_link_number=true";
          };
          filters = {
            "text/plain" = "${pkgs.coreutils}/bin/cat";
            "text/html" =
              "${pkgs.w3m}/bin/w3m -T text/html -cols 80 -dump -o display_image=false -o display_link_number=true";
            "message/delivery-status" = "${pkgs.coreutils}/bin/cat";
            "message/rfc822" = "${pkgs.coreutils}/bin/cat";
            "application/pdf" = "${pkgs.poppler-utils}/bin/pdftotext - -";
            "application/pgp-signature" = "${pkgs.gnupg}/bin/gpg --verify 2>&1 || true";
            "image/*" =
              "${lib.getExe pkgs.chafa} -f sixel -s \${AERC_IMAGE_WIDTH:-80}x\${AERC_IMAGE_HEIGHT:-24} -";
          };
          openers = {
            "application/pdf" = "${pkgs.zathura}/bin/zathura";
            "image/*" = "${lib.getExe pkgs.imv}";
            "text/html" = "${pkgs.xdg-utils}/bin/xdg-open";
          };
        };

        extraBinds = ''
          # Global keybindings
          [messages]
          q = :quit<Enter>

          j = :next<Enter>
          <Down> = :next<Enter>
          <C-d> = :next 50%<Enter>
          <C-f> = :next 100%<Enter>
          <PgDn> = :next 100%<Enter>

          k = :prev<Enter>
          <Up> = :prev<Enter>
          <C-u> = :prev 50%<Enter>
          <C-b> = :prev 100%<Enter>
          <PgUp> = :prev 100%<Enter>

          g = :select 0<Enter>
          G = :select -1<Enter>

          J = :next-folder<Enter>
          K = :prev-folder<Enter>
          H = :collapse-folder<Enter>
          L = :expand-folder<Enter>

          v = :mark -t<Enter>
          V = :mark -v<Enter>
          <space> = :mark -t<Enter>

          mr = :read<Enter>
          mu = :unread<Enter>

          T = :toggle-threads<Enter>

          <Enter> = :view<Enter>
          l = :view<Enter>
          d = :prompt 'Really delete this message?' 'delete-message'<Enter>
          D = :delete<Enter>
          A = :archive flat<Enter>

          C = :compose<Enter>
          rr = :reply -a<Enter>
          rq = :reply -aq<Enter>
          Rr = :reply<Enter>
          Rq = :reply -q<Enter>

          c = :cf<space>
          $ = :term<Enter>
          ! = :term<Enter>
          | = :pipe<space>

          / = :search<space>
          \ = :filter<space>
          n = :next-result<Enter>
          N = :prev-result<Enter>
          <Esc> = :clear<Enter>

          s = :split<Enter>
          S = :vsplit<Enter>

          <A-h> = :prev-tab<Enter>
          <A-l> = :next-tab<Enter>

          [messages:folder=Drafts]
          <Enter> = :recall<Enter>

          [view]
          / = :toggle-key-passthrough<Enter>/
          q = :close<Enter>
          h = :close<Enter>
          | = :pipe<space>

          f = :forward<Enter>
          rr = :reply -a<Enter>
          rq = :reply -aq<Enter>
          Rr = :reply<Enter>
          Rq = :reply -q<Enter>

          H = :toggle-headers<Enter>
          <C-k> = :prev-part<Enter>
          <C-j> = :next-part<Enter>
          J = :next<Enter>
          K = :prev<Enter>
          S = :save<space>
          | = :pipe<space>
          D = :delete<Enter>
          A = :archive flat<Enter>

          <C-l> = :open-link<space>

          o = :open<Enter>
          O = :open -a<Enter>

          <A-h> = :prev-tab<Enter>
          <A-l> = :next-tab<Enter>

          [view::passthrough]
          $noinherit = true
          $ex = <C-x>
          <Esc> = :toggle-key-passthrough<Enter>

          [compose]
          $noinherit = true
          $ex = <C-x>
          <C-k> = :prev-field<Enter>
          <C-j> = :next-field<Enter>
          <A-p> = :switch-account -p<Enter>
          <A-n> = :switch-account -n<Enter>
          <tab> = :next-field<Enter>
          <backtab> = :prev-field<Enter>
          <C-p> = :prev-tab<Enter>
          <C-n> = :next-tab<Enter>
          <A-h> = :prev-tab<Enter>
          <A-l> = :next-tab<Enter>

          [compose::editor]
          $noinherit = true
          $ex = <C-x>
          <C-k> = :prev-field<Enter>
          <C-j> = :next-field<Enter>
          <C-p> = :prev-tab<Enter>
          <C-n> = :next-tab<Enter>
          <A-h> = :prev-tab<Enter>
          <A-l> = :next-tab<Enter>

          [compose::review]
          y = :send<Enter>
          n = :abort<Enter>
          v = :preview<Enter>
          p = :postpone<Enter>
          q = :choose -o d discard -o p postpone<Enter>
          e = :edit<Enter>
          a = :attach<space>
          d = :detach<space>

          <A-h> = :prev-tab<Enter>
          <A-l> = :next-tab<Enter>

          [terminal]
          $noinherit = true
          $ex = <C-x>
          <C-p> = :prev-tab<Enter>
          <C-n> = :next-tab<Enter>
          <A-h> = :prev-tab<Enter>
          <A-l> = :next-tab<Enter>

          ${cfg.extraBinds}
        '';

        stylesets = {
          default =
            if stylixEnabled then
              stylixStyleset
            else
              ''
                *.default = true
                *.normal = true

                title.reverse = true
                title.bold = true

                header.bold = true

                *error.fg = red
                *warning.fg = yellow
                *success.fg = green

                statusline*.default = true
                statusline*.reverse = true

                msglist_unread.bold = true
                msglist_deleted.fg = gray

                selector_focused.reverse = true
                selector_chooser.bold = true

                tab.reverse = true
                border.reverse = true

                part_mimetype.fg = gray
                part_filename.fg = yellow
              '';
        }
        // cfg.stylesets;

        templates = {
          quoted_reply = ''
            X-Mailer: aerc {{version}}

            On {{dateFormat (.OriginalDate | toLocal) "Mon Jan 2, 2006 at 3:04 PM MST"}}, {{.OriginalFrom | names | join ", "}} wrote:
            {{- if eq .OriginalMIMEType "text/html"}}
            {{exec `html` .OriginalText | trimSignature | quote}}
            {{- else}}
            {{trimSignature .OriginalText | quote}}
            {{- end}}
          '';

          forward_as_body = ''
            X-Mailer: aerc {{version}}

            ---------- Forwarded message ----------
            From: {{.OriginalFrom | names | join ", "}}
            Date: {{dateFormat (.OriginalDate | toLocal) "Mon Jan 2, 2006 at 3:04 PM MST"}}

            {{.OriginalText}}
          '';
        }
        // cfg.templates;

        extraAccounts = ''
          ${builtins.concatStringsSep "\n" (mapAttrsToList mkAercAccount enabledAccounts)}
          ${cfg.extraAccounts}
        '';
      };

      xdg.desktopEntries.aerc = {
        name = "Aerc";
        genericName = "Email Client";
        comment = "Terminal-based email client";
        exec = "aerc";
        icon = "mail-client";
        terminal = true;
        type = "Application";
        categories = [
          "Network"
          "Email"
        ];
      };

      home = {
        sessionVariables.MAIL_CLIENT = lib.mkDefault "aerc";
        packages = with pkgs; [
          w3m # HTML rendering
          dante # SOCKS proxy support
        ];
      };

      # Ensure cache directory exists
      home.activation.createAercCache = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${config.home.homeDirectory}/.cache/aerc"
      '';

      ${namespace}.preservation.directories = [
        ".config/aerc"
        ".cache/aerc"
      ];
    }

    # User-provided extra config (string form) - mkIf needed to avoid type conflict with attrset
    (mkIf (cfg.extraConfig != "") {
      programs.aerc.extraConfig = cfg.extraConfig;
    })

    # Notmuch query maps for account filtering
    (mkIf (cfg.useNotmuch && mailCfg.notmuch.enable) {
      home.file = lib.mapAttrs' (
        name: acc:
        lib.nameValuePair "${mailCfg.mailDir}/.notmuch/querymap-${name}" {
          text = mkQueryMap name acc;
        }
      ) enabledAccounts;
    })
  ]);
}
