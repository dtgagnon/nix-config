{ lib
, pkgs
, config
, inputs
, namespace
, ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.${namespace}.apps.kiro;
in
{
  options.${namespace}.apps.kiro = {
    enable = mkEnableOption "kiro IDE";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.kiro inputs.nixd.packages.${system}.nixd ];

    xdg.configFile."Kiro/User/nixed-settings.json".text = ''
      {
        "kiro.marketplaceExtensionGalleryServiceURL": "https://marketplace.visualstudio.com/_apis/public/gallery",
        "kiro.marketplaceGalleryItemURL": "https://marketplace.visualstudio.com/items",
        "kiro.marketplaceExtensionGallerySource": "https://marketplace.visualstudio.com/_apis/public/gallery",
        "kiro.autocompleteSpeed": "fast",
        "kiro.autoExecutionPolicy": "off",
        "kiro.chatFontSize": "default",
        "kiro.rememberLastModelSelection": true,
        "kiro.openRecentConversation": true,
        "kiro.explainAndFixInCurrentConversation": true,
        "workbench.sideBar.location": "right",
        "workbench.colorTheme": "base24-catppuccin-frappe",
        "workbench.iconTheme": "gruvbox-material-icon-theme",
        "window.menuBarVisibility": "compact",
        "terminal.integrated.defaultProfile.linux": "zsh",
        "workbench.layoutControl.enabled": false,
        "workbench.productIconTheme": "material-product-icons",

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
    '';

    home.file = {
      ".kiro/argv.json".text = ''
        // This configuration file allows you to pass permanent command line arguments to VS Code.
        {
          // For compatibility with Hyprland, to tell it the keyring to use.
          "password-store":"gnome-libsecret",

          // Use software rendering instead of hardware accelerated rendering. This can help in cases where you see rendering issues in VS Code.
          // "disable-hardware-acceleration": true,

          // Allows to disable crash reporting. Should restart the app if the value is changed.
          "enable-crash-reporter": false,

          // Unique id used for correlating crash reports sent from this instance. Do not edit this value.
          "crash-reporter-id": "4c9b8afe-4e3d-40db-a77d-3879fc1923bd"
        }
      '';
    };
  };
}
