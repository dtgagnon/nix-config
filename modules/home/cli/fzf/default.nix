{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.fzf;
in
{
  options.${namespace}.cli.fzf = {
    enable = mkBoolOpt true "Enables fzf";
  };

  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;

      # Search files with NixOS-specific exclusions
      defaultCommand = "${getExe pkgs.fd} --hidden --strip-cwd-prefix --max-depth 6 --exclude .git --exclude result --exclude .result --exclude 'result-*' --exclude .direnv --exclude .cache --exclude node_modules --exclude target --exclude dist --exclude dist-newstyle --exclude .stack-work --exclude __pycache__ --exclude .pytest_cache --exclude .mypy_cache --exclude .cargo --exclude .venv --exclude venv";
      fileWidgetOptions = [
        "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
      ];
      # Search directories with same exclusions
      changeDirWidgetCommand = "${getExe pkgs.fd} --type=d --hidden --strip-cwd-prefix --max-depth 6 --exclude .git --exclude result --exclude .result --exclude 'result-*' --exclude .direnv --exclude .cache --exclude node_modules --exclude target --exclude dist --exclude dist-newstyle --exclude .stack-work --exclude __pycache__ --exclude .pytest_cache --exclude .mypy_cache --exclude .cargo --exclude .venv --exclude venv";
      changeDirWidgetOptions = [
        "--preview 'eza --tree --color=always {} | head -200'"
      ];

      defaultOptions = [
        "--border='rounded' --border-label='' --preview-window='border-rounded' --prompt='> '"
        "--marker='>' --pointer='>' --separator='─' --scrollbar='│'"
        "--info='right'"
      ];
    };
  };
}
