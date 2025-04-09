{ lib
, pkgs
, config
, inputs
, system
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.apps.windsurf;
in
{
  options.${namespace}.apps.windsurf = {
    enable = mkBoolOpt false "Enable windsurf module";
    extensions = mkOpt (types.listOf types.packages) [ ] "List of vscode extension packages";
    extraConfig = mkOpt types.str "" "Initial configuration for windsurf to use";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.spirenix.windsurf inputs.nixd.packages.${system}.nixd ];

    # programs.vscode = {
    #   enable = true;
    #   package = pkgs.spirenix.windsurf;
    #   profiles.default = {
    #     extensions = with pkgs.vscode-extensions; [
    #       vscodevim.vim
    #       sainnhe.gruvbox-material
    #       jonathanharty.gruvbox-material-icon-theme
    #
    #       mkhl.direnv
    #       jnoortheen.nix-ide
    #       arrterian.nix-env-selector
    #       # continue.continue
    #
    #       # activitywatch.aw-watcher-vscode
    #       # andrsdc.base16-themes
    #       # arrterian.nix-env-selector
    #       # bourhaouta.tailwindshades
    #       # bradlc.vscode-tailwindcss
    #       # brettm12345.nixfmt-vscode
    #       # catppuccin.catppuccin-vsc
    #       # catppuccin.catppuccin-vsc-icons
    #       # catppuccin.catppuccin-vsc-pack
    #       # codeium.windsurfpyright
    #
    #       # github.copilot
    #       # github.copilot-chat
    #       # heybourn.headwind
    #       # leodevbro.blockman
    #       # mhutchie.git-graph
    #       # ms-python.debugpy
    #       # ms-python.python
    #       # ms-vscode-remote.remote-ssh
    #       # ms-vscode-remote.vscode-remote-extensionpack
    #       # ms-vscode.vscode-speech
    #       # naumovs.color-highlight
    #       # pkief.material-product-icons
    #       # rooveterinaryinc.roo-cline
    #       # stivo.tailwind-fold
    #       # svelte.svelte-vscode
    #       # tintedtheming.base16-tinted-themes
    #       # zarifprogrammer.tailwind-snippets
    #     ];
    #   };
    # };
    #
    #
    xdg.configFile = {
      "Windsurf/User/settings.json".text = ''
      {
        "windsurf.marketplaceExtensionGallerySource": "https://marketplace.visualstudio.com/_apis/public/gallery",
        "windsurf.autocompleteSpeed": "fast",
        "windsurf.autoExecutionPolicy": "off",
        "windsurf.chatFontSize": "default",
        "windsurf.rememberLastModelSelection": true,
        "windsurf.openRecentConversation": true,
        "windsurf.explainAndFixInCurrentConversation": true,
        "workbench.sideBar.location": "right",
        "workbench.colorTheme": "base16-everforest-dark-hard",
        "workbench.iconTheme": "gruvbox-material-icon-theme",
        "window.menuBarVisibility": "compact",
        "windsurf.cascadeCommandsAllowList": [
            "pnpm install",
            "pnpm add",
            "pnpm run dev"
        ],
        "terminal.integrated.defaultProfile.linux": "zsh",
        "workbench.layoutControl.enabled": false,
        "workbench.productIconTheme": "material-product-icons",
        "windsurf.marketplaceExtensionGalleryServiceURL": "https://marketplace.visualstudio.com/_apis/public/gallery",
        "windsurf.marketplaceGalleryItemURL": "https://marketplace.visualstudio.com/items",
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
      '' + cfg.extraConfig;
    };

    # spirenix.user.persistHomeDirs = [
    #   ".config/Windsurf" # Future XDG config location
    #   ".windsurf" # Current data directory
    #   ".codeium" # Codeium data directory
    # ];

    home.file = {
      ".windsurf/argv.json".text = ''
              // This configuration file allows you to pass permanent command line arguments to VS Code.
              {
                // For compatibility with Hyprland, to tell it the keyring to use.
                "password-store":"gnome-libsecret",

                // Use software rendering instead of hardware accelerated rendering. This can help in cases where you see rendering issues in VS Code.
                // "disable-hardware-acceleration": true,

                // Allows to disable crash reporting. Should restart the app if the value is changed.
                "enable-crash-reporter": true,

                // Unique id used for correlating crash reports sent from this instance. Do not edit this value.
                "crash-reporter-id": "4c9b8afe-4e3d-40db-a77d-3879fc1923bd"
              }
        		'';
      # ".windsurf/extensions/extensions.json".text = ''
      #           				[
      #             {
      #               "identifier": {
      #                 "id": "activitywatch.aw-watcher-vscode",
      #                 "uuid": "4f400159-99b2-491a-85e5-c885e46d057a"
      #               },
      #               "version": "0.5.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/activitywatch.aw-watcher-vscode-0.5.0",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "activitywatch.aw-watcher-vscode-0.5.0",
      #               "metadata": {
      #                 "id": "4f400159-99b2-491a-85e5-c885e46d057a",
      #                 "publisherId": "5e44e7fb-036f-4334-aa6b-b6888a9ed629",
      #                 "publisherDisplayName": "ActivityWatch",
      #                 "targetPlatform": "undefined",
      #                 "isApplicationScoped": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false,
      #                 "installedTimestamp": 1738176918178,
      #                 "pinned": false,
      #                 "preRelease": false,
      #                 "source": "gallery",
      #                 "size": 1357896
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "andrsdc.base16-themes",
      #                 "uuid": "5b70d193-8451-4993-b4d4-eabcc15b7fe1"
      #               },
      #               "version": "1.4.5",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/andrsdc.base16-themes-1.4.5",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "andrsdc.base16-themes-1.4.5",
      #               "metadata": {
      #                 "id": "5b70d193-8451-4993-b4d4-eabcc15b7fe1",
      #                 "publisherId": "9ead81b8-b179-4aee-b7ee-b29b6cc0bb16",
      #                 "publisherDisplayName": "AndrsDC",
      #                 "targetPlatform": "undefined",
      #                 "isApplicationScoped": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false,
      #                 "installedTimestamp": 1739654593119,
      #                 "pinned": false,
      #                 "preRelease": false,
      #                 "source": "gallery",
      #                 "size": 2219956
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "catppuccin.catppuccin-vsc-icons",
      #                 "uuid": "625b9abd-dfac-405b-bf34-e65f46e2f22f"
      #               },
      #               "version": "1.20.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/catppuccin.catppuccin-vsc-icons-1.20.0-universal",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "catppuccin.catppuccin-vsc-icons-1.20.0-universal",
      #               "metadata": {
      #                 "installedTimestamp": 1742419265808,
      #                 "size": 2446706,
      #                 "id": "625b9abd-dfac-405b-bf34-e65f46e2f22f",
      #                 "publisherDisplayName": "Catppuccin",
      #                 "publisherId": "e7d2ed61-53e0-4dd4-afbe-f536c3bb4316",
      #                 "isPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "catppuccin.catppuccin-vsc-pack",
      #                 "uuid": "27c20910-92b3-4f79-936a-d2e8470376d8"
      #               },
      #               "version": "1.0.2",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/catppuccin.catppuccin-vsc-pack-1.0.2",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "catppuccin.catppuccin-vsc-pack-1.0.2",
      #               "metadata": {
      #                 "id": "27c20910-92b3-4f79-936a-d2e8470376d8",
      #                 "publisherId": "e7d2ed61-53e0-4dd4-afbe-f536c3bb4316",
      #                 "publisherDisplayName": "Catppuccin",
      #                 "targetPlatform": "undefined",
      #                 "isApplicationScoped": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false,
      #                 "installedTimestamp": 1735819995324,
      #                 "pinned": false,
      #                 "preRelease": false,
      #                 "source": "gallery",
      #                 "size": 26824
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "jonathanharty.gruvbox-material-icon-theme",
      #                 "uuid": "8b7b553c-f741-437c-adf5-cc494eb7d4d8"
      #               },
      #               "version": "1.1.5",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/jonathanharty.gruvbox-material-icon-theme-1.1.5",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "jonathanharty.gruvbox-material-icon-theme-1.1.5",
      #               "metadata": {
      #                 "id": "8b7b553c-f741-437c-adf5-cc494eb7d4d8",
      #                 "publisherId": "ed4a519d-1055-467e-bad5-37205be2dea8",
      #                 "publisherDisplayName": "JonathanHarty",
      #                 "targetPlatform": "undefined",
      #                 "isApplicationScoped": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false,
      #                 "installedTimestamp": 1735796296393,
      #                 "pinned": false,
      #                 "preRelease": false,
      #                 "source": "gallery",
      #                 "size": 1367046
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "mkhl.direnv"
      #               },
      #               "version": "0.17.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/mkhl.direnv",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "mkhl.direnv",
      #               "metadata": {
      #                 "id": "e365e970-aeef-4dcd-8e4a-17306a27ab62",
      #                 "publisherDisplayName": "Martin Kühl",
      #                 "publisherId": "577d6c37-7054-4ca5-b4ce-9250409f3903",
      #                 "isPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "ms-python.debugpy",
      #                 "uuid": "4bd5d2c9-9d65-401a-b0b2-7498d9f17615"
      #               },
      #               "version": "2025.4.1",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/ms-python.debugpy-2025.4.1-linux-x64",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "ms-python.debugpy-2025.4.1-linux-x64",
      #               "metadata": {
      #                 "installedTimestamp": 1741798383197,
      #                 "size": 37971270,
      #                 "id": "4bd5d2c9-9d65-401a-b0b2-7498d9f17615",
      #                 "publisherDisplayName": "ms-python",
      #                 "publisherId": "998b010b-e2af-44a5-a6cd-0b5fd3b9b6f8",
      #                 "isPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "ms-python.python",
      #                 "uuid": "f1f59ae4-9318-4f3c-a9b5-81b2eaa5f8a5"
      #               },
      #               "version": "2025.2.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/ms-python.python-2025.2.0-universal",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "ms-python.python-2025.2.0-universal",
      #               "metadata": {
      #                 "installedTimestamp": 1741618753035,
      #                 "size": 23934546,
      #                 "id": "f1f59ae4-9318-4f3c-a9b5-81b2eaa5f8a5",
      #                 "publisherDisplayName": "ms-python",
      #                 "publisherId": "998b010b-e2af-44a5-a6cd-0b5fd3b9b6f8",
      #                 "isPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "ms-vscode-remote.remote-ssh",
      #                 "uuid": "607fd052-be03-4363-b657-2bd62b83d28a"
      #               },
      #               "version": "0.118.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/ms-vscode-remote.remote-ssh-0.118.0",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "ms-vscode-remote.remote-ssh-0.118.0",
      #               "metadata": {
      #                 "installedTimestamp": 1741618749290,
      #                 "size": 6709530,
      #                 "id": "607fd052-be03-4363-b657-2bd62b83d28a",
      #                 "publisherDisplayName": "Microsoft",
      #                 "publisherId": "ac9410a2-0d75-40ec-90de-b59bb705801d",
      #                 "isPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "ms-vscode-remote.vscode-remote-extensionpack",
      #                 "uuid": "23d72dfc-8dd1-4e30-926e-8783b4378f13"
      #               },
      #               "version": "0.26.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/ms-vscode-remote.vscode-remote-extensionpack-0.26.0",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "ms-vscode-remote.vscode-remote-extensionpack-0.26.0",
      #               "metadata": {
      #                 "id": "23d72dfc-8dd1-4e30-926e-8783b4378f13",
      #                 "publisherId": "ac9410a2-0d75-40ec-90de-b59bb705801d",
      #                 "publisherDisplayName": "Microsoft",
      #                 "targetPlatform": "undefined",
      #                 "isApplicationScoped": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false,
      #                 "installedTimestamp": 1737227877719,
      #                 "pinned": false,
      #                 "preRelease": false,
      #                 "source": "gallery",
      #                 "size": 40214
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "ms-vscode.vscode-speech",
      #                 "uuid": "e6610e16-9699-4e1d-a5d7-9bb1643db131"
      #               },
      #               "version": "0.12.1",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/ms-vscode.vscode-speech-0.12.1-linux-x64",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "ms-vscode.vscode-speech-0.12.1-linux-x64",
      #               "metadata": {
      #                 "id": "e6610e16-9699-4e1d-a5d7-9bb1643db131",
      #                 "publisherId": "5f5636e7-69ed-4afe-b5d6-8d231fb3d3ee",
      #                 "publisherDisplayName": "Microsoft",
      #                 "targetPlatform": "linux-x64",
      #                 "isApplicationScoped": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false,
      #                 "installedTimestamp": 1735870601663,
      #                 "pinned": false,
      #                 "preRelease": false,
      #                 "source": "gallery",
      #                 "size": 291834632
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "pkief.material-product-icons",
      #                 "uuid": "f797dacd-4e80-4f33-8b63-d665c0956013"
      #               },
      #               "version": "1.7.1",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/pkief.material-product-icons-1.7.1",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "pkief.material-product-icons-1.7.1",
      #               "metadata": {
      #                 "id": "f797dacd-4e80-4f33-8b63-d665c0956013",
      #                 "publisherId": "f9e5bc2f-fea1-4075-917f-d83e01e69f56",
      #                 "publisherDisplayName": "Philipp Kief",
      #                 "targetPlatform": "undefined",
      #                 "isApplicationScoped": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false,
      #                 "installedTimestamp": 1735796238060,
      #                 "pinned": false,
      #                 "preRelease": false,
      #                 "source": "gallery",
      #                 "size": 108867
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "sainnhe.gruvbox-material"
      #               },
      #               "version": "6.5.2",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/sainnhe.gruvbox-material",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "sainnhe.gruvbox-material",
      #               "metadata": {
      #                 "id": "d9437be1-e21c-4e9a-9548-e63650468296",
      #                 "publisherDisplayName": "sainnhe",
      #                 "publisherId": "cd5355a7-bbfb-4a47-8f70-727aed458bc8",
      #                 "isPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "svelte.svelte-vscode",
      #                 "uuid": "c5463f77-75d9-4a25-8cc4-d8541a461285"
      #               },
      #               "version": "109.5.3",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/svelte.svelte-vscode-109.5.3-universal",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "svelte.svelte-vscode-109.5.3-universal",
      #               "metadata": {
      #                 "installedTimestamp": 1741618753410,
      #                 "size": 45700516,
      #                 "id": "c5463f77-75d9-4a25-8cc4-d8541a461285",
      #                 "publisherDisplayName": "svelte",
      #                 "publisherId": "c3bf51ad-baaa-466c-952c-9c3ca9bfabed",
      #                 "isPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "tintedtheming.base16-tinted-themes",
      #                 "uuid": "1191387e-377a-400f-aefb-2d8772a10451"
      #               },
      #               "version": "0.18.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/tintedtheming.base16-tinted-themes-0.18.0",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "tintedtheming.base16-tinted-themes-0.18.0",
      #               "metadata": {
      #                 "installedTimestamp": 1741618749467,
      #                 "size": 23289600,
      #                 "id": "1191387e-377a-400f-aefb-2d8772a10451",
      #                 "publisherDisplayName": "Tinted Theming",
      #                 "publisherId": "fd615ab0-6e30-4b1e-9931-ef3f146a072b",
      #                 "isPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "vscodevim.vim"
      #               },
      #               "version": "1.29.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/vscodevim.vim",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "vscodevim.vim",
      #               "metadata": {
      #                 "id": "d96e79c6-8b25-4be3-8545-0e0ecefcae03",
      #                 "publisherDisplayName": "vscodevim",
      #                 "publisherId": "5d63889b-1b67-4b1f-8350-4f1dce041a26",
      #                 "isPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "codeium.windsurfpyright",
      #                 "uuid": "1adb9c26-188a-4fb6-840e-b1e951ecff7c"
      #               },
      #               "version": "1.28.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/codeium.windsurfpyright-1.28.0-universal",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "codeium.windsurfpyright-1.28.0-universal",
      #               "metadata": {
      #                 "installedTimestamp": 1742857856451,
      #                 "source": "gallery",
      #                 "id": "1adb9c26-188a-4fb6-840e-b1e951ecff7c",
      #                 "publisherId": "082b0525-4adf-4bcc-b60f-afa86c60860d",
      #                 "publisherDisplayName": "Codeium",
      #                 "targetPlatform": "undefined",
      #                 "updated": true,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false,
      #                 "isApplicationScoped": false,
      #                 "isMachineScoped": false,
      #                 "isBuiltin": false,
      #                 "pinned": false,
      #                 "preRelease": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "heybourn.headwind",
      #                 "uuid": "6226e0be-5975-4616-948c-545d562adc1d"
      #               },
      #               "version": "1.7.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/heybourn.headwind-1.7.0",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "heybourn.headwind-1.7.0",
      #               "metadata": {
      #                 "installedTimestamp": 1742857760666,
      #                 "pinned": false,
      #                 "source": "gallery",
      #                 "id": "6226e0be-5975-4616-948c-545d562adc1d",
      #                 "publisherId": "637eb2b9-b01e-4059-9fc4-f6b7ff485929",
      #                 "publisherDisplayName": "Ryan Heybourn",
      #                 "targetPlatform": "undefined",
      #                 "updated": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "zarifprogrammer.tailwind-snippets",
      #                 "uuid": "fca01007-19ce-45f7-bb55-8973c4784200"
      #               },
      #               "version": "1.0.2",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/zarifprogrammer.tailwind-snippets-1.0.2",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "zarifprogrammer.tailwind-snippets-1.0.2",
      #               "metadata": {
      #                 "installedTimestamp": 1742857763486,
      #                 "pinned": false,
      #                 "source": "gallery",
      #                 "id": "fca01007-19ce-45f7-bb55-8973c4784200",
      #                 "publisherId": "8ed87e85-76ca-40b7-a413-b962df97c858",
      #                 "publisherDisplayName": "ZS Software Studio",
      #                 "targetPlatform": "undefined",
      #                 "updated": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "bourhaouta.tailwindshades",
      #                 "uuid": "03b858e7-8bc6-41a0-b756-f38959b27d21"
      #               },
      #               "version": "0.0.5",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/bourhaouta.tailwindshades-0.0.5",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "bourhaouta.tailwindshades-0.0.5",
      #               "metadata": {
      #                 "installedTimestamp": 1742857769285,
      #                 "pinned": false,
      #                 "source": "gallery",
      #                 "id": "03b858e7-8bc6-41a0-b756-f38959b27d21",
      #                 "publisherId": "679cee90-29f4-4884-8b9b-85e0f1c1b350",
      #                 "publisherDisplayName": "Omar Bourhaouta",
      #                 "targetPlatform": "undefined",
      #                 "updated": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "stivo.tailwind-fold",
      #                 "uuid": "38454b33-2ebc-4d0c-b04c-77e5ea5cdb4b"
      #               },
      #               "version": "0.2.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/stivo.tailwind-fold-0.2.0",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "stivo.tailwind-fold-0.2.0",
      #               "metadata": {
      #                 "installedTimestamp": 1742857782796,
      #                 "pinned": false,
      #                 "source": "gallery",
      #                 "id": "38454b33-2ebc-4d0c-b04c-77e5ea5cdb4b",
      #                 "publisherId": "db2ef22b-a2f9-4b8a-9fe0-7929938e0d8b",
      #                 "publisherDisplayName": "Stivo",
      #                 "targetPlatform": "undefined",
      #                 "updated": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "naumovs.color-highlight",
      #                 "uuid": "121396ad-85a1-45ec-9fd1-d95028a847f5"
      #               },
      #               "version": "2.8.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/naumovs.color-highlight-2.8.0",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "naumovs.color-highlight-2.8.0",
      #               "metadata": {
      #                 "installedTimestamp": 1742939827238,
      #                 "pinned": false,
      #                 "source": "gallery",
      #                 "id": "121396ad-85a1-45ec-9fd1-d95028a847f5",
      #                 "publisherId": "e9a76d04-24d4-44eb-a202-964f71acf59e",
      #                 "publisherDisplayName": "Sergii N",
      #                 "targetPlatform": "undefined",
      #                 "updated": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "brettm12345.nixfmt-vscode",
      #                 "uuid": "1aa812d9-007d-46e3-ae73-91210cf36115"
      #               },
      #               "version": "0.0.1",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/brettm12345.nixfmt-vscode-0.0.1",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "brettm12345.nixfmt-vscode-0.0.1",
      #               "metadata": {
      #                 "installedTimestamp": 1743180949125,
      #                 "pinned": false,
      #                 "source": "gallery",
      #                 "id": "1aa812d9-007d-46e3-ae73-91210cf36115",
      #                 "publisherId": "9185a15a-6721-45e7-8961-bc8a1cbc60ec",
      #                 "publisherDisplayName": "brettm12345",
      #                 "targetPlatform": "undefined",
      #                 "updated": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "catppuccin.catppuccin-vsc",
      #                 "uuid": "69264e4d-cd3b-468a-8f2b-e69673c7d864"
      #               },
      #               "version": "3.17.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/catppuccin.catppuccin-vsc-3.17.0",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "catppuccin.catppuccin-vsc-3.17.0",
      #               "metadata": {
      #                 "isApplicationScoped": false,
      #                 "isMachineScoped": false,
      #                 "isBuiltin": false,
      #                 "installedTimestamp": 1743201874156,
      #                 "pinned": false,
      #                 "source": "gallery",
      #                 "id": "69264e4d-cd3b-468a-8f2b-e69673c7d864",
      #                 "publisherId": "e7d2ed61-53e0-4dd4-afbe-f536c3bb4316",
      #                 "publisherDisplayName": "Catppuccin",
      #                 "targetPlatform": "undefined",
      #                 "updated": true,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false,
      #                 "preRelease": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "bradlc.vscode-tailwindcss"
      #               },
      #               "version": "0.14.13",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/bradlc.vscode-tailwindcss-0.14.13",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "bradlc.vscode-tailwindcss-0.14.13",
      #               "metadata": {
      #                 "isApplicationScoped": false,
      #                 "isMachineScoped": false,
      #                 "isBuiltin": false,
      #                 "installedTimestamp": 1743620236249,
      #                 "pinned": false,
      #                 "source": "gallery",
      #                 "id": "4db62a7c-7d70-419c-96d2-6c3a4dc77ea5",
      #                 "publisherId": "84722833-669b-4c7d-920e-b60e43fae19a",
      #                 "publisherDisplayName": "Tailwind Labs",
      #                 "targetPlatform": "undefined",
      #                 "updated": true,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false,
      #                 "preRelease": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "jnoortheen.nix-ide"
      #               },
      #               "version": "0.4.16",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/jnoortheen.nix-ide-0.4.16",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "jnoortheen.nix-ide-0.4.16",
      #               "metadata": {
      #                 "isApplicationScoped": false,
      #                 "isMachineScoped": false,
      #                 "isBuiltin": false,
      #                 "installedTimestamp": 1743694191516,
      #                 "pinned": true,
      #                 "source": "gallery",
      #                 "id": "0ffebccd-4265-4f2d-a855-db1adcf278c7",
      #                 "publisherId": "3a7c13d8-8768-454a-be53-290c25bd0f85",
      #                 "publisherDisplayName": "Noortheen",
      #                 "targetPlatform": "undefined",
      #                 "updated": true,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false,
      #                 "preRelease": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "arrterian.nix-env-selector"
      #               },
      #               "version": "1.0.12",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/arrterian.nix-env-selector",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "arrterian.nix-env-selector",
      #               "metadata": {
      #                 "isApplicationScoped": false,
      #                 "isMachineScoped": false,
      #                 "isBuiltin": false,
      #                 "installedTimestamp": 1743694194341,
      #                 "pinned": true,
      #                 "source": "gallery",
      #                 "id": "7d5f2292-e10e-4cd3-84b7-f8c9a551f845",
      #                 "publisherId": "08a14899-ff7f-4355-bf22-b63b438231de",
      #                 "publisherDisplayName": "Roman Valihura",
      #                 "targetPlatform": "undefined",
      #                 "updated": true,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false,
      #                 "preRelease": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "rooveterinaryinc.roo-cline"
      #               },
      #               "version": "3.11.5",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/rooveterinaryinc.roo-cline-3.11.5",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "rooveterinaryinc.roo-cline-3.11.5",
      #               "metadata": {
      #                 "isApplicationScoped": false,
      #                 "isMachineScoped": false,
      #                 "isBuiltin": false,
      #                 "installedTimestamp": 1743778492702,
      #                 "pinned": false,
      #                 "source": "gallery",
      #                 "id": "4ce92b26-476a-4dd1-bf50-a8df00b87a74",
      #                 "publisherId": "4b55a936-06f2-4448-983f-3caa1b8e500a",
      #                 "publisherDisplayName": "Roo Code",
      #                 "targetPlatform": "undefined",
      #                 "updated": true,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false,
      #                 "preRelease": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "leodevbro.blockman"
      #               },
      #               "version": "1.7.8",
      #               "location": {
      #                 "$mid": 1,
      #                 "path": "/home/dtgagnon/.windsurf/extensions/leodevbro.blockman-1.7.8",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "leodevbro.blockman-1.7.8",
      #               "metadata": {
      #                 "installedTimestamp": 1743778547439,
      #                 "pinned": false,
      #                 "source": "gallery",
      #                 "id": "4a65c1f4-5251-41fa-925e-5b154e94d6e4",
      #                 "publisherId": "24a18384-bf2c-4ec9-a6a7-5b3d3a618211",
      #                 "publisherDisplayName": "leodevbro",
      #                 "targetPlatform": "undefined",
      #                 "updated": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false
      #               }
      #             },
      #             {
      #               "identifier": {
      #                 "id": "mhutchie.git-graph"
      #               },
      #               "version": "1.30.0",
      #               "location": {
      #                 "$mid": 1,
      #                 "fsPath": "/home/dtgagnon/.windsurf/extensions/mhutchie.git-graph-1.30.0",
      #                 "external": "file:///home/dtgagnon/.windsurf/extensions/mhutchie.git-graph-1.30.0",
      #                 "path": "/home/dtgagnon/.windsurf/extensions/mhutchie.git-graph-1.30.0",
      #                 "scheme": "file"
      #               },
      #               "relativeLocation": "mhutchie.git-graph-1.30.0",
      #               "metadata": {
      #                 "installedTimestamp": 1743778771375,
      #                 "pinned": false,
      #                 "source": "gallery",
      #                 "id": "438221f8-1107-4ccd-a6fe-f3b7fe0856b7",
      #                 "publisherId": "996496dc-099f-469d-b89c-0d7713179365",
      #                 "publisherDisplayName": "mhutchie",
      #                 "targetPlatform": "undefined",
      #                 "updated": false,
      #                 "isPreReleaseVersion": false,
      #                 "hasPreReleaseVersion": false
      #               }
      #             }
      #           ]
      #   		'';
    };
  };
}
