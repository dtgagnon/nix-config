{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkForce mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.fzf;
in {
  options.${namespace}.cli.fzf = {
    enable = mkBoolOpt true "Enables fzf";
  };

  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;

      defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
      fileWidgetOptions = [
        "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
      ];
      changeDirWidgetCommand = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
      changeDirWidgetOptions = [
        "--preview 'eza --tree --color=always {} | head -200'"
      ];

      colors = with config.lib.stylix.colors.withHashtag; mkForce {
        "bg" = base00;
        "bg+" = base02;
        "fg" = base05;
        "fg+" = base05;
        "header" = base0E;
        "hl" = base08;
        "hl+" = base08;
        "info" = base0A;
        "marker" = base06;
        "pointer" = base06;
        "prompt" = base0E;
        "spinner" = base06;
      };

      defaultOptions = [
        "--border='rounded' --border-label='' --preview-window='border-rounded' --prompt='> '"
        "--marker='>' --pointer='>' --separator='─' --scrollbar='│'"
        "--info='right'"
      ];
    };
  };
}
