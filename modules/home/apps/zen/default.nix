{
  lib,
  config,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption types optionalString;
  cfg = config.${namespace}.apps.zen;

  # Import sibling configuration files
  zenSettings = import ./settings.nix;
  zenKeybinds = import ./keybinds.nix;
  zenContainers = import ./containers.nix;
  zenSearch = import ./search.nix { inherit pkgs; };

  # Stylix integration (conditional)
  stylixEnabled = config.stylix.enable or false;
  colors = if stylixEnabled then config.lib.stylix.colors.withHashtag else { };

  # Path to user-editable overrides file
  localOverridesPath = "${config.home.homeDirectory}/.zen/user-overrides.js";

  # Profile path - if not specified, will be auto-detected or created as "default"
  profileDir = if cfg.profilePath != null then cfg.profilePath else "default";
  profileFullPath = "${config.home.homeDirectory}/.zen/${profileDir}";

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

        settings = zenSettings.base;
        keyboardShortcuts = zenKeybinds;

        # Custom CSS Overrides (adjustments to Stylix-generated theme)
        userChrome = optionalString stylixEnabled ''
          /* URL bar: slightly lighter than main background */
          .urlbar-background {
            background-color: color-mix(in srgb, ${colors.base00} 90%, white) !important;
          }
        '';
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
      BROWSER = "zen";
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
      { directory = ".zen"; mode = "0700"; }
    ];

    # Activation scripts for user-overrides.js management
    home.activation.createZenOverridesTemplate = mkIf cfg.useLocalOverrides zenActivation.createZenOverridesTemplate;
    home.activation.applyZenOverrides = mkIf cfg.useLocalOverrides zenActivation.applyZenOverrides;
  };
}
