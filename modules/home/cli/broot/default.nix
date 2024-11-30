{
  config,
  lib,
  namespace,
  ...
}:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.broot;
in {
  options.${namespace}.cli.broot = {
    enable = mkBoolOpt false "Whether to enable broot directory navigation tool";
  };

  config = mkIf cfg.enable {
    programs.broot = {
      enable = true;
      
      settings = {
        modal = true;  # vim-like mode
        show_selection_mark = true;
        default_flags = "gh";  # Show hidden files by default
        
        verbs = [
          {
            invocation = "edit";
            shortcut = "e";
            execution = "$EDITOR {file}";
          }
          {
            invocation = "create {subpath}";
            execution = "$EDITOR {directory}/{subpath}";
          }
          {
            invocation = "git_diff";
            shortcut = "gd";
            execution = "git diff {file}";
          }
        ];
      };
    };
  };
}
