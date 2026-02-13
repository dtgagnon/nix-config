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

  mailCfg = config.${namespace}.services.mail;

  # Filter enabled mail accounts
  enabledAccounts = filterAttrs (_: acc: acc.enable) mailCfg.accounts;

  # Import modular components
  accountGenerators = import ./accounts.nix { inherit lib config namespace; };
  inherit (accountGenerators) mkAercAccount mkQueryMap;

  keybinds = import ./keybinds.nix { inherit cfg; };
  stylesets = import ./styles.nix { inherit config cfg; };
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

        extraBinds = keybinds;

        stylesets = stylesets;

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
