{ lib
, config
, namespace
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.${namespace}.apps.zen;

  # Path to user-editable overrides file
  localOverridesPath = "${config.home.homeDirectory}/.zen/user-overrides.js";

  # Profile path - if not specified, will be auto-detected or created as "default"
  profileDir = if cfg.profilePath != null
    then cfg.profilePath
    else "default";
  profileFullPath = "${config.home.homeDirectory}/.zen/${profileDir}";
in
{
  options.${namespace}.apps.zen = {
    enable = mkEnableOption "Enable Zen Browser";

    profilePath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The profile directory name (found in ~/.zen/).
        If null, uses "default" for new installs or auto-detects existing profile.

        To find your existing profile path, check ~/.zen/profiles.ini
      '';
      example = "abc123xy.default";
    };

    useLocalOverrides = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable runtime-writable local overrides via ~/.zen/user-overrides.js

        When enabled, preferences in this file will be appended to the profile's
        user.js file on each rebuild, allowing you to maintain custom settings
        that override the declarative configuration without editing Nix files.
      '';
    };

    defaultBrowser = mkOption {
      type = types.bool;
      default = true;
      description = "Set Zen Browser as the default web browser";
    };
  };

  config = mkIf cfg.enable {
    programs.zen-browser = {
      enable = true;

      profiles.default = {
        id = 0;
        name = "default";
        isDefault = true;

        # ── Base Settings (applied to all users) ───────────────────────
        # These are sensible defaults for privacy, security, and UX
        settings = {
          # ─ General UI ─
          "browser.aboutConfig.showWarning" = false;
          "browser.ctrlTab.sortByRecentlyUsed" = true;
          "browser.bookmarks.defaultLocation" = "toolbar_____";

          # ─ Privacy & Security ─
          "dom.security.https_only_mode_ever_enabled" = true;
          "datareporting.usage.uploadEnabled" = false;

          # ─ Disable Sponsored Content ─
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.urlbar.suggest.quicksuggest.all" = false;
        };

        # ── Keyboard Shortcuts (applied to all users) ──────────────────
        # Tab switching with Alt instead of Ctrl, workspace nav with Alt+Shift
        keyboardShortcuts = [
          { id = "key_selectTab1"; key = "1"; modifiers = { alt = true; }; }
          { id = "key_selectTab2"; key = "2"; modifiers = { alt = true; }; }
          { id = "key_selectTab3"; key = "3"; modifiers = { alt = true; }; }
          { id = "key_selectTab4"; key = "4"; modifiers = { alt = true; }; }
          { id = "key_selectTab5"; key = "5"; modifiers = { alt = true; }; }
          { id = "key_selectTab6"; key = "6"; modifiers = { alt = true; }; }
          { id = "key_selectTab7"; key = "7"; modifiers = { alt = true; }; }
          { id = "key_selectTab8"; key = "8"; modifiers = { alt = true; }; }
          { id = "key_selectLastTab"; key = "9"; modifiers = { alt = true; }; }
          { id = "zen-workspace-forward"; key = "}"; modifiers = { alt = true; shift = true; }; }
          { id = "zen-workspace-backward"; key = "{"; modifiers = { alt = true; shift = true; }; }
        ];
      } // lib.optionalAttrs (cfg.profilePath != null) {
        path = cfg.profilePath;

        # ── Container Tabs ─────────────────────────────────────────────
        containers = {
          Personal = {
            id = 1;
            icon = "fingerprint";
            color = "blue";
          };
          "Client Zone" = {
            id = 2;
            icon = "briefcase";
            color = "red";
          };
          Banking = {
            id = 3;
            icon = "dollar";
            color = "green";
          };
          Shopping = {
            id = 4;
            icon = "cart";
            color = "pink";
          };
          Work = {
            id = 7;
            icon = "briefcase";
            color = "yellow";
          };
        };

        # ── Extensions ─────────────────────────────────────────────────
        # Extensions are managed imperatively via about:addons
        # They change frequently and are easier to manage in the browser

        # ── Search Engines ─────────────────────────────────────────────
        search = {
          default = "ddg";
          privateDefault = "ddg";
          force = true;
          engines = {
            "Nix Packages" = {
              urls = [{ template = "https://search.nixos.org/packages?query={searchTerms}"; }];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "Nix Options" = {
              urls = [{ template = "https://search.nixos.org/options?query={searchTerms}"; }];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@no" ];
            };
            "NixOS Wiki" = {
              urls = [{ template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; }];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@nw" ];
            };
            "Home Manager Options" = {
              urls = [{ template = "https://home-manager-options.extranix.com/?query={searchTerms}"; }];
              icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@hm" ];
            };
            "GitHub" = {
              urls = [{ template = "https://github.com/search?q={searchTerms}&type=code"; }];
              definedAliases = [ "@gh" ];
            };
            "YouTube" = {
              urls = [{ template = "https://www.youtube.com/results?search_query={searchTerms}"; }];
              definedAliases = [ "@yt" ];
            };
            # Disable sponsored/unwanted engines
            "Bing".metaData.hidden = true;
            "Amazon.com".metaData.hidden = true;
            "eBay".metaData.hidden = true;
            "Wikipedia (en)".metaData.alias = "@wiki";
          };
        };

        # ── Extended Settings (power user) ─────────────────────────────
        # These supplement the base settings above
        settings = {
          # ─ General UI ─
          "browser.tabs.inTitlebar" = 1;

          # ─ Homepage & New Tab ─
          "browser.startup.homepage" = "https://duckduckgo.com";
          "browser.newtabpage.enabled" = false;
          "browser.newtabpage.activity-stream.feeds.section.highlights" = true;

          # ─ AI Sidebar (Claude) ─
          "browser.ml.chat.enabled" = true;
          "browser.ml.chat.provider" = "https://claude.ai/new";
          "browser.ml.chat.sidebar" = true;
          "browser.ml.chat.page.footerBadge" = false;
          "browser.ml.chat.page.menuBadge" = false;
          "browser.ml.enable" = true;

          # ─ Privacy & Security (additional) ─
          "browser.safebrowsing.malware.enabled" = false;
          "browser.safebrowsing.phishing.enabled" = false;

          # ─ URL Bar ─
          "browser.urlbar.placeholderName.private" = "DuckDuckGo";

          # ─ Forms & Autofill (disabled - using Proton Pass) ─
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          "dom.forms.autocomplete.formautofill" = true;

          # ─ Developer Tools ─
          "devtools.cache.disabled" = true;
          "devtools.toolbox.host" = "window";
          "devtools.everOpened" = true;
          "devtools.netmonitor.persistlog" = true;

          # ─ Downloads ─
          "browser.download.autohideButton" = true;
          "browser.download.panel.shown" = true;

          # ─ Translations ─
          "browser.translations.alwaysTranslateLanguages" = "zh-Hans";
          "browser.translations.mostRecentTargetLanguages" = "en";
        };

        # ── Zen Mods (Theme Store) ─────────────────────────────────────
        mods = [
          "a5f6a231-e3c8-4ce8-8a8e-3e93efd6adec" # Cleaned URL bar
          "81fcd6b3-f014-4796-988f-6c3cb3874db8" # Zen Context Menu
        ];

        # Note: Pinned tabs (pins) are intentionally left imperative
        # Note: Workspaces (spaces) are intentionally left imperative
      };
    };

    # Configure Stylix to theme zen-browser
    stylix.targets.zen-browser = {
      profileNames = [ "default" ];
      enableCss = true;
    };

    # Set as default browser if enabled
    home.sessionVariables = mkIf cfg.defaultBrowser {
      BROWSER = "zen-beta";
    };

    # MIME type associations for default browser
    xdg.mimeApps.defaultApplications = mkIf cfg.defaultBrowser {
      "application/x-extension-htm" = "zen-beta.desktop";
      "application/x-extension-html" = "zen-beta.desktop";
      "application/x-extension-shtml" = "zen-beta.desktop";
      "application/x-extension-xht" = "zen-beta.desktop";
      "application/x-extension-xhtml" = "zen-beta.desktop";
      "application/xhtml+xml" = "zen-beta.desktop";
      "text/html" = "zen-beta.desktop";
      "x-scheme-handler/about" = "zen-beta.desktop";
      "x-scheme-handler/ftp" = "zen-beta.desktop";
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "x-scheme-handler/unknown" = "zen-beta.desktop";
    };

    # Preserve Zen Browser data (imperative config, pins, workspaces, etc.)
    spirenix.preservation.directories = [
      { directory = ".zen"; mode = "0700"; }
    ];

    # Create template user-overrides.js file if it doesn't exist
    home.activation.createZenOverridesTemplate = mkIf cfg.useLocalOverrides (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        OVERRIDES_FILE="${localOverridesPath}"
        OVERRIDES_DIR=$(dirname "$OVERRIDES_FILE")

        if [ ! -f "$OVERRIDES_FILE" ]; then
          $DRY_RUN_CMD mkdir -p "$OVERRIDES_DIR"
          $DRY_RUN_CMD tee "$OVERRIDES_FILE" > /dev/null <<'EOF'
// Zen Browser Local Overrides
// Location: ~/.zen/user-overrides.js
//
// This file is preserved across rebuilds and can be edited directly.
// Preferences here will be appended to your profile's user.js on each rebuild.
//
// Add your custom preferences using the format:
//   user_pref("preference.name", value);
//
// These preferences override any declarative settings from Nix.

// Your custom preferences below:

EOF
          $DRY_RUN_CMD chmod 600 "$OVERRIDES_FILE"
          $VERBOSE_ECHO "Created Zen Browser local overrides file at $OVERRIDES_FILE"
        fi
      ''
    );

    # Append user-overrides.js to profile's user.js at activation time
    home.activation.applyZenOverrides = mkIf cfg.useLocalOverrides (
      lib.hm.dag.entryAfter [ "linkGeneration" "createZenOverridesTemplate" ] ''
        OVERRIDES_FILE="${localOverridesPath}"
        PROFILE_USER_JS="${profileFullPath}/user.js"
        PROFILE_DIR="${profileFullPath}"

        # Create profile directory if it doesn't exist
        $DRY_RUN_CMD mkdir -p "$PROFILE_DIR"

        # Get the base content (either from nix-store symlink or existing file)
        BASE_CONTENT=""
        if [ -L "$PROFILE_USER_JS" ]; then
          # It's a symlink (from home-manager/nix store) - read and remove it
          $VERBOSE_ECHO "Reading declarative user.js from nix store"
          BASE_CONTENT=$(cat "$PROFILE_USER_JS")
          $DRY_RUN_CMD rm "$PROFILE_USER_JS"
        elif [ -f "$PROFILE_USER_JS" ]; then
          # Regular file exists - read content, stripping old overrides
          BASE_CONTENT=$(sed '/^\/\/ BEGIN LOCAL OVERRIDES/,/^\/\/ END LOCAL OVERRIDES/d' "$PROFILE_USER_JS")
        fi

        # Build the new user.js with base content + overrides
        if [ -f "$OVERRIDES_FILE" ] && [ -s "$OVERRIDES_FILE" ]; then
          $VERBOSE_ECHO "Applying local overrides from $OVERRIDES_FILE"

          $DRY_RUN_CMD tee "$PROFILE_USER_JS" > /dev/null <<EOF
// Zen Browser User Preferences
// Base configuration from Nix/Stylix (if any)
$BASE_CONTENT

// BEGIN LOCAL OVERRIDES (from ~/.zen/user-overrides.js)
// These settings take precedence over declarative config above
$(cat "$OVERRIDES_FILE")
// END LOCAL OVERRIDES
EOF
          $DRY_RUN_CMD chmod 600 "$PROFILE_USER_JS"
          $VERBOSE_ECHO "✓ Zen Browser user.js created with local overrides"
        elif [ -n "$BASE_CONTENT" ]; then
          # No overrides file, but we have base content - restore it as regular file
          $VERBOSE_ECHO "Restoring declarative user.js (no local overrides found)"
          $DRY_RUN_CMD tee "$PROFILE_USER_JS" > /dev/null <<EOF
$BASE_CONTENT
EOF
          $DRY_RUN_CMD chmod 600 "$PROFILE_USER_JS"
        else
          $VERBOSE_ECHO "No user.js configuration (declarative or local)"
        fi
      ''
    );
  };
}
