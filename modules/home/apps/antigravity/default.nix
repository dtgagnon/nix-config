{
  lib,
  pkgs,
  config,
  inputs,
  system,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.apps.antigravity;
in
{
  options.${namespace}.apps.antigravity = {
    enable = mkBoolOpt false "Enable Google Gemini Antigravity IDE";
    extensions = mkOpt (types.listOf types.packages) [ ] "List of vscode extension packages";
    extraConfig = mkOpt types.str "" "Initial configuration for antigravity to use";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.spirenix.antigravity
      inputs.nixd.packages.${system}.nixd
      pkgs.google-chrome
    ];

    home.sessionVariables = {
      CHROME_BIN = "${pkgs.google-chrome}/bin/google-chrome-stable";
    };

    xdg.configFile = {
      "Antigravity/User/settings.json".text = ''
        {
          "antigravity.marketplaceExtensionGallerySource": "https://marketplace.visualstudio.com/_apis/public/gallery",
          "antigravity.autocompleteSpeed": "fast",
          "antigravity.autoExecutionPolicy": "off",
          "antigravity.chatFontSize": "default",
          "antigravity.rememberLastModelSelection": true,
          "antigravity.openRecentConversation": true,
          "antigravity.explainAndFixInCurrentConversation": true,
          "antigravity.chromeBinaryPath": "${pkgs.google-chrome}/bin/google-chrome-stable",
          "antigravity.browserUserProfilePath": "~/.gemini/antigravity-browser-profile",
          "antigravity.browserCDPPort": 9222,
          "workbench.sideBar.location": "right",
          "workbench.colorTheme": "base24-catppuccin-frappe",
          "workbench.iconTheme": "gruvbox-material-icon-theme",
          "window.menuBarVisibility": "compact",
          "terminal.integrated.defaultProfile.linux": "zsh",
          "workbench.layoutControl.enabled": false,
          "workbench.productIconTheme": "material-product-icons",
          "antigravity.marketplaceExtensionGalleryServiceURL": "https://marketplace.visualstudio.com/_apis/public/gallery",
          "antigravity.marketplaceGalleryItemURL": "https://marketplace.visualstudio.com/items",
          "explorer.confirmDragAndDrop": false,
          "explorer.confirmDelete": false,
          "git.confirmSync": false,
          "color-highlight.languages": [
              "html",
              "css",
              "typescript",
              "typescriptreact",
              "javascript",
              "nix",
              "json",
              "*"
          ],
          "workbench.activityBar.location": "top",
          "nix.serverPath": "",
          "editor.inlayHints.enabled": "off",
          "workbench.colorCustomizations": {
              "editor.lineHighlightBackground": "#1073cf2d",
              "editor.lineHighlightBorder": "#9fced11f"
          },
          "editor.wordWrap": "off",
          "diffEditor.wordWrap": "off",
          "editor.guides.indentation": false,
          "editor.guides.bracketPairs": false,
          "blockman.n23AnalyzeSquareBrackets": true,
          "blockman.n33A04B1FromFocusToOutwardForFocusTreeBorders": "!40,0,0,0; basic",
          "blockman.n33A01B1FromDepth0ToInwardForAllBorders": "!10,0,0,0; linear-gradient(to right, rgb(19,26,31), rgb(39,46,51)) > linear-gradient(to right, rgb(19,26,31), rgb(39,46,51)) > linear-gradient(to right, rgb(19,26,31), rgb(39,46,51)) > linear-gradient(to right, rgb(19,26,31), rgb(39,46,51)) > linear-gradient(to right, rgb(19,26,31), rgb(39,46,51)) > linear-gradient(to right, rgb(19,26,31), rgb(39,46,51)) > linear-gradient(to right, rgb(19,26,31), rgb(39,46,51)) > linear-gradient(to right, rgb(19,26,31), rgb(39,46,51)) > linear-gradient(to right, rgb(19,26,31), rgb(39,46,51)) > linear-gradient(to right, rgb(19,26,31), rgb(39,46,51)) >",
          "blockman.n27AlsoRenderBlocksInsideSingleLineAreas": true,
          "blockman.n04Sub05MinDistanceBetweenRightSideEdges": 2,
          "blockman.n33A01B2FromDepth0ToInwardForAllBackgrounds": "10,0,0,0; none > none > none > none > none > none > none > none > none > none",
          "blockman.n28TimeToWaitBeforeRerenderAfterLastChangeEvent": 0.5,
          "blockman.n31RenderIncrementBeforeAndAfterVisibleRange": 100,
          "blockman.n05CustomColorOfDepth0": "linear-gradient(to right, rgb(19,26,31), rgb(39,46,51))",
          "blockman.n04Sub02ColorComboPresetForLightTheme": "none",
          "blockman.n06CustomColorOfDepth1": "linear-gradient(to right, rgb(19,26,31), rgb(39,46,51))",
          "blockman.n07CustomColorOfDepth2": "linear-gradient(to right, rgb(19,26,31), rgb(39,46,51))",
          "blockman.n08CustomColorOfDepth3": "linear-gradient(to right, rgb(19,26,31), rgb(39,46,51))",
          "blockman.n10CustomColorOfDepth5": "linear-gradient(to right, rgb(19,26,31), rgb(39,46,51))",
          "blockman.n12CustomColorOfDepth7": "linear-gradient(to right, rgb(19,26,31), rgb(39,46,51))",
          "blockman.n13CustomColorOfDepth8": "linear-gradient(to right, rgb(19,26,31), rgb(39,46,51))",
          "blockman.n15CustomColorOfDepth10": "linear-gradient(to right, rgb(19,26,31), rgb(39,46,51))",
          "blockman.n18CustomColorOfFocusedBlockBorder": "linear-gradient(to right, #859289, rgb(39,46,51))",
          "blockman.n14CustomColorOfDepth9": "linear-gradient(to right, rgb(19,26,31), rgb(39,46,51))",
          "blockman.n09CustomColorOfDepth4": "linear-gradient(to right, rgb(19,26,31), rgb(39,46,51))",
          "blockman.n11CustomColorOfDepth6": "linear-gradient(to right, rgb(19,26,31), rgb(39,46,51))",
          "blockman.n17CustomColorOfFocusedBlock": "none",
          "keyboard.dispatch": "keyCode",
        }
      ''
      + cfg.extraConfig;
    };

    # spirenix.user.persistHomeDirs = [
    #   ".config/Antigravity" # Future XDG config location
    #   ".antigravity" # Current data directory
    #   ".gemini" # Codeium data directory
    # ];

    home.file = {
      ".antigravity/argv.json".text = ''
        				// This configuration file allows you to pass permanent command line arguments to VS Code.
        				{
        					// For compatibility with Hyprland, to tell it the keyring to use.
        					"password-store":"gnome-libsecret",

        					// Use software rendering instead of hardware accelerated rendering. This can help in cases where you see rendering issues in VS Code.
        					// "disable-hardware-acceleration": true,

        					// Allows to disable crash reporting. Should restart the app if the value is changed.
        					"enable-crash-reporter": false,

        					// Unique id used for correlating crash reports sent from this instance. Do not edit this value.
        					"crash-reporter-id": "e832de61-f47a-4c08-811e-4a1a2e81e2aa"
        				}
        			'';
      # ".antigravity/extensions/extensions.json".text = ''
      # '';
    };
  };
}
