{ lib
, config
, namespace
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption types optionalString;
  cfg = config.${namespace}.apps.zen;

  # Path to user-editable overrides file
  localOverridesPath = "${config.home.homeDirectory}/.zen/user-overrides.js";

  # Profile path where user.js will be created
  profilePath = "${config.home.homeDirectory}/.zen/default";
in
{
  options.${namespace}.apps.zen = {
    enable = mkEnableOption "Enable Zen Browser";

    useLocalOverrides = mkOption {
      type = types.bool;
      default = true;
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
    # Use the zen-browser home-manager module for Stylix theming support
    # IMPORTANT: This module inherits from Firefox's HM module
    programs.zen-browser = {
      enable = true;

      # Minimal profile declaration to avoid overwriting imperative config
      # We intentionally DO NOT set:
      # - settings = {} (would create user.js and overwrite about:config changes)
      # - spaces/pins/mods (would overwrite workspace configuration)
      # - isDefault = true (would modify profiles.ini)
      profiles.default = {
        id = 0;
        name = "Default";
        # Stylix will theme this profile via userChrome.css/userContent.css
      };
    };

    # Configure Stylix to theme zen-browser
    stylix.targets.zen-browser = {
      profileNames = [ "default" ];
      enableCss = true; # Enables userChrome.css and userContent.css theming
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

    # Preserve all Zen Browser data including user-overrides.js
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
          $DRY_RUN_CMD cat > "$OVERRIDES_FILE" <<'EOF'
// Zen Browser Local Overrides
// Location: ~/.zen/user-overrides.js
//
// This file is preserved across rebuilds and can be edited directly.
// Preferences here will be appended to your profile's user.js on each rebuild.
//
// Add your custom preferences using the format:
//   user_pref("preference.name", value);
//
// Examples:
//   user_pref("browser.tabs.warnOnClose", false);
//   user_pref("browser.download.panel.shown", false);
//   user_pref("browser.download.useDownloadDir", false);
//   user_pref("privacy.clearOnShutdown.cache", true);
//   user_pref("browser.startup.page", 3); // Restore previous session
//
// Find available preferences in about:config
// After editing, run: nixos-rebuild switch --flake .#YOUR-HOST
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
    # This runs AFTER home-manager creates the base user.js, allowing runtime edits
    home.activation.applyZenOverrides = mkIf cfg.useLocalOverrides (
      lib.hm.dag.entryAfter [ "linkGeneration" "createZenOverridesTemplate" ] ''
        OVERRIDES_FILE="${localOverridesPath}"
        PROFILE_USER_JS="${profilePath}/user.js"
        PROFILE_DIR="${profilePath}"

        if [ -f "$OVERRIDES_FILE" ] && [ -s "$OVERRIDES_FILE" ]; then
          # Create profile directory if it doesn't exist yet
          $DRY_RUN_CMD mkdir -p "$PROFILE_DIR"

          # Check if user.js exists and create it if not (in case no declarative settings)
          if [ ! -f "$PROFILE_USER_JS" ]; then
            $VERBOSE_ECHO "Creating initial user.js for Zen Browser profile"
            $DRY_RUN_CMD cat > "$PROFILE_USER_JS" <<'EOF'
// Zen Browser User Preferences
// This file is managed by Home Manager
// Local overrides from ~/.zen/user-overrides.js are appended below
EOF
          fi

          # Remove any previously appended overrides (to avoid duplication)
          $DRY_RUN_CMD sed -i '/^\/\/ BEGIN LOCAL OVERRIDES/,/^\/\/ END LOCAL OVERRIDES/d' "$PROFILE_USER_JS"

          # Append the current overrides with delimiters
          $VERBOSE_ECHO "Applying local overrides from $OVERRIDES_FILE"
          $DRY_RUN_CMD cat >> "$PROFILE_USER_JS" <<EOF

// BEGIN LOCAL OVERRIDES (from ~/.zen/user-overrides.js)
$(cat "$OVERRIDES_FILE")
// END LOCAL OVERRIDES
EOF

          $VERBOSE_ECHO "✓ Zen Browser local overrides applied successfully"
        else
          $VERBOSE_ECHO "No Zen Browser local overrides found at $OVERRIDES_FILE"
        fi
      ''
    );
  };
}
