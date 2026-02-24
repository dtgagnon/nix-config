{ lib
, config
, namespace
, inputs
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.${namespace}.apps.zen;
  zenBrowserPkgs = inputs.zen-browser.packages.${pkgs.system};

  # Upstream occasionally replaces twilight artifacts in-place; pin the observed
  # hash locally so rebuilds stay unblocked.
  zenTwilightPatched =
    if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then
      pkgs.wrapFirefox
        (zenBrowserPkgs.twilight-unwrapped.overrideAttrs (_: {
          src = pkgs.fetchzip {
            url = "https://github.com/zen-browser/desktop/releases/download/twilight-1/zen.linux-x86_64.tar.xz";
            hash = "sha256-3ia9fNT8pfmD+/5Bw2kApIv0VqetrGDAj64FnOZZ0a8=";
          };
        }))
        { }
    else
      zenBrowserPkgs.twilight;

  # Import sibling configuration files
  zenSettings = import ./settings.nix;
  zenKeybinds = import ./keybinds.nix;
  zenContainers = import ./containers.nix;
  zenSearch = import ./search.nix { inherit pkgs; };

  # Path to user-editable overrides file
  localOverridesPath = "${config.xdg.configHome}/zen/user-overrides.js";

  # Profile path - if not specified, will be auto-detected or created as "default"
  profileDir = if cfg.profilePath != null then cfg.profilePath else "default";
  profileFullPath = "${config.xdg.configHome}/zen/${profileDir}";

  # Import activation scripts with required arguments
  zenActivation = import ./activation.nix { inherit lib localOverridesPath profileFullPath; };
in
{
  options.${namespace}.apps.zen = {
    enable = mkEnableOption "Enable Zen Browser";

    profilePath = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The profile directory name (found in ~/.config/zen/).
        If null, uses "default" for new installs or auto-detects existing profile.

        To find your existing profile path, check ~/.config/zen/profiles.ini
      '';
      example = "abc123xy.default";
    };

    useLocalOverrides = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable runtime-writable local overrides via ~/.config/zen/user-overrides.js

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
      package = zenTwilightPatched;
      suppressXdgMigrationWarning = true;

      profiles.default = {
        id = 0;
        name = "default";
        isDefault = true;

        settings = zenSettings.base;
        keyboardShortcuts = zenKeybinds;
      } // lib.optionalAttrs (cfg.profilePath != null) {
        path = cfg.profilePath;
        containers = zenContainers;
        search = zenSearch;
        settings = zenSettings.base // zenSettings.extended;

        # Zen Mods (Theme Store)
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
      BROWSER = "zen-twilight";
    };

    # MIME type associations for default browser
    xdg.mimeApps.defaultApplications = mkIf cfg.defaultBrowser {
      "application/x-extension-htm" = "zen-twilight.desktop";
      "application/x-extension-html" = "zen-twilight.desktop";
      "application/x-extension-shtml" = "zen-twilight.desktop";
      "application/x-extension-xht" = "zen-twilight.desktop";
      "application/x-extension-xhtml" = "zen-twilight.desktop";
      "application/xhtml+xml" = "zen-twilight.desktop";
      "text/html" = "zen-twilight.desktop";
      "x-scheme-handler/about" = "zen-twilight.desktop";
      "x-scheme-handler/ftp" = "zen-twilight.desktop";
      "x-scheme-handler/http" = "zen-twilight.desktop";
      "x-scheme-handler/https" = "zen-twilight.desktop";
      "x-scheme-handler/unknown" = "zen-twilight.desktop";
    };

    # Preserve Zen Browser data (imperative config, pins, workspaces, etc.)
    spirenix.preservation.directories = [
      { directory = ".config/zen"; mode = "0700"; }
    ];

    # Activation scripts for user-overrides.js management
    home.activation.createZenOverridesTemplate = mkIf cfg.useLocalOverrides zenActivation.createZenOverridesTemplate;
    home.activation.applyZenOverrides = mkIf cfg.useLocalOverrides zenActivation.applyZenOverrides;

    # Migrate browser data from legacy ~/.zen/ to XDG location (~/.config/zen/)
    # The browser falls back to ~/.zen/ when it can't write to the HM-managed profiles.ini,
    # which causes all declarative config (user.js, containers, Stylix CSS) to be ignored.
    home.activation.migrateZenToXdg = config.lib.dag.entryAfter [ "linkGeneration" ] ''
      LEGACY_DIR="$HOME/.zen"
      XDG_DIR="${config.xdg.configHome}/zen"
      PROFILE_DIR="${profileDir}"

      if [ -d "$LEGACY_DIR" ] && [ -f "$LEGACY_DIR/profiles.ini" ] && [ ! -L "$LEGACY_DIR/profiles.ini" ]; then
        $VERBOSE_ECHO "Migrating Zen Browser data from $LEGACY_DIR to $XDG_DIR"
        $DRY_RUN_CMD mkdir -p "$XDG_DIR/$PROFILE_DIR"

        # Sync profile data (newer files only, don't overwrite HM symlinks)
        if [ -d "$LEGACY_DIR/$PROFILE_DIR" ]; then
          for f in "$LEGACY_DIR/$PROFILE_DIR"/*; do
            basename="$(basename "$f")"
            target="$XDG_DIR/$PROFILE_DIR/$basename"
            # Skip if target is a symlink (HM-managed file)
            if [ -L "$target" ]; then
              continue
            fi
            $DRY_RUN_CMD cp -a --update "$f" "$target"
          done
        fi

        # Sync Profile Groups
        if [ -d "$LEGACY_DIR/Profile Groups" ]; then
          $DRY_RUN_CMD cp -a --update "$LEGACY_DIR/Profile Groups" "$XDG_DIR/"
        fi

        # Remove legacy directory entirely
        $DRY_RUN_CMD rm -rf "$LEGACY_DIR"
        $VERBOSE_ECHO "Zen Browser XDG migration complete. Removed $LEGACY_DIR"
      fi
    '';
};
}
