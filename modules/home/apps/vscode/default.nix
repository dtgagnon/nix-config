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
  cfg = config.${namespace}.apps.vscode;
in
{
  options.${namespace}.apps.vscode = {
    enable = mkBoolOpt false "Enable vscode";
    extensions = mkOpt (types.listOf types.package) [ ] "List of extensions to install as strings";
  };

  config = mkIf cfg.enable {
    spirenix.desktop.styling.stylix.excludedTargets = [ "vscode" ];
    home.packages = [ inputs.nixd.packages.${system}.nixd ]; # for nix LSP

    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      profiles.default = {
        extensions =
          with pkgs.vscode-extensions;
          [
            vscodevim.vim
            sainnhe.gruvbox-material

            github.copilot
            github.copilot-chat
            continue.continue

            mkhl.direnv
            jnoortheen.nix-ide
            arrterian.nix-env-selector

          ]
          ++ cfg.extensions;
      };
    };

    # This configuration file allows you to pass permanent command line arguments to VSCode.
    home.file.".vscode-oss/argv.json".text = ''
      {
      // For compatibility with Hyprland, to tell it the keyring to use.
      "password-store": "gnome-libsecret",

      // Use software rendering instead of hardware accelerated rendering. This can help in cases where you see rendering issues in VS Code.
      // "disable-hardware-acceleration": true,

      // Allows to disable crash reporting. Should restart the app if the value is changed.
      "enable-crash-reporter": false,

      // Unique id used for correlating crash reports sent from this instance. Do not edit this value.
      "crash-reporter-id": "b24b470f-e40a-4d0d-85e4-fcb22afc5576"
      }
    '';

    xdg.configFile."VSCodium/User/starter-for-settings.json".text = ''
      {
      // Chat settings
      "chat.editor.fontFamily": "JetBrainsMono Nerd Font Mono",
      "chat.editor.fontSize": 16,

      // Debug console settings
      "debug.console.fontFamily": "JetBrainsMono Nerd Font Mono",
      "debug.console.fontSize": 16,

      // Markdown preview settings
      "markdown.preview.fontFamily": "DejaVu Sans",
      "markdown.preview.fontSize": 16,

      // SCM settings
      "scm.inputFontFamily": "JetBrainsMono Nerd Font Mono",
      "scm.inputFontSize": 16,

      // Screencast mode settings
      "screencastMode.fontSize": 80,

      // Terminal settings
      "terminal.integrated.fontSize": 16,
      "terminal.external.linuxExec": "nu",

      // Workbench settings
      "workbench.colorTheme": "Gruvbox Material Dark",
      "workbench.iconTheme": "gruvbox-material-icon-theme",
      "workbench.productIconTheme": "material-product-icons",
      "workbench.sideBar.location": "right",
      "workbench.tips.enabled": false,

      // Editor settings
      "editor.indentSize": 2,
      "editor.fontFamily": "JetBrainsMono Nerd Font Mono",
      "editor.fontSize": 16,
      "editor.inlayHints.fontFamily": "JetBrainsMono Nerd Font Mono",
      "editor.inlineSuggest.fontFamily": "JetBrainsMono Nerd Font Mono",
      "editor.minimap.sectionHeaderFontSize": 16,
      "editor.wordWrap": "on",

      // Git settings
      "git.openRepositoryInParentFolders": "always",
      "git.enableSmartCommit": true,
      "git.confirmSync": false,

      // Nix settings
      "[nix]": {
      "editor.tabSize": 2
      },
      "nix.enableLanguageServer": true,
      "nix.formatterPath": "nixfmt",
      "nix.serverPath": "nixd",
      "nix.serverSettings": {},

      // GitHub Copilot settings
      "github.copilot.advanced": {},
      "github.copilot.chat.scopeSelection": true,
      "github.copilot.chat.terminalChatLocation": "terminal",
      "github.copilot.chat.search.semanticTextResults": true,
      "github.copilot.chat.experimental.inlineChatCompletionTrigger.enabled": true,
      "github.copilot.chat.experimental.inlineChatHint.enabled": true,
      "github.copilot.chat.temporalContext.enabled": true,

      // Window settings
      "window.customTitleBarVisibility": "auto",
      "window.menuBarVisibility": "toggle",

      // Continue settings
      "continue.enableTabAutocomplete": false
      }
    '';

    spirenix.preservation.directories = [
      ".config/VSCodium"
      ".vscode-oss"
    ];
  };
}
