{ lib
, pkgs
, config
, namespace
, ...
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
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [
        vscodevim.vim
        sainnhe.gruvbox-material

        github.copilot
        github.copilot-chat
        continue.continue

        mkhl.direnv
        jnoortheen.nix-ide
        arrterian.nix-env-selector

      ] ++ cfg.extensions;

      userSettings = {
        "workbench.sideBar.location" = "right";
        "workbench.tips.enabled" = false;

        "editor.indentSize" = 2;
        "editor.wordWrap" = "on";

        "terminal.external.linuxExec" = "nu";

        "git.openRepositoryInParentFolders" = "always";
        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;

        # .nix stuff
        "[nix]"."editor.tabSize" = 2;
        "nix.enableLanguageServer" = true;
        "nix.formatterPath" = "nixfmt";
        "nix.serverPath" = "nixd";

        # ai stuff
        "github.copilot.advanced" = { };
        "github.copilot.chat.scopeSelection" = true;
        "github.copilot.chat.terminalChatLocation" = "terminal";
        "github.copilot.chat.search.semanticTextResults" = true;
        "github.copilot.chat.experimental.inlineChatCompletionTrigger.enabled" = true;
        "github.copilot.chat.experimental.inlineChatHint.enabled" = true;
        "github.copilot.chat.experimental.temporalContext.enabled" = true;
      };
    };
  };
}
