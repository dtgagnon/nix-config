{ pkgs, lib, ... }:
let
  inherit (lib) getExe;
in
''
  # Helper function to find git root directory
  def --env get-git-root [] {
    let result = (do -i { git rev-parse --show-toplevel } | complete)
    if $result.exit_code == 0 {
      $result.stdout | str trim
    } else {
      $env.PWD
    }
  }

  # Context-aware fzf file search (searches from git root if in a repo)
  def --env fzf-file-widget [] {
    let root = (get-git-root)
    cd $root
    let selection = (${getExe pkgs.fd} --hidden --strip-cwd-prefix --max-depth 6 --exclude .git --exclude result --exclude .result --exclude 'result-*' --exclude .direnv --exclude .cache --exclude node_modules --exclude target --exclude dist --exclude dist-newstyle --exclude .stack-work --exclude __pycache__ --exclude .pytest_cache --exclude .mypy_cache --exclude .cargo --exclude .venv --exclude venv | fzf --preview 'if (ls {} | get type.0) == "dir" { eza --tree --color=always {} | head -200 } else { bat -n --color=always --line-range :500 {} }')
    if ($selection | is-not-empty) {
      $selection
    }
  }

  # Context-aware fzf directory search (searches from git root if in a repo)
  def --env fzf-dir-widget [] {
    let root = (get-git-root)
    cd $root
    let selection = (${getExe pkgs.fd} --type=d --hidden --strip-cwd-prefix --max-depth 6 --exclude .git --exclude result --exclude .result --exclude 'result-*' --exclude .direnv --exclude .cache --exclude node_modules --exclude target --exclude dist --exclude dist-newstyle --exclude .stack-work --exclude __pycache__ --exclude .pytest_cache --exclude .mypy_cache --exclude .cargo --exclude .venv --exclude venv | fzf --preview 'eza --tree --color=always {} | head -200')
    if ($selection | is-not-empty) {
      cd $selection
    }
  }

  # Ripgrep in a zoxide-known directory
  # Usage: rgz PATTERN [ZOXIDE_QUERY] [...RIPGREP_FLAGS]
  # - rgz TODO          -> interactive fzf selection
  # - rgz TODO CODE     -> search TODO in zoxide directory matching CODE
  # - rgz TODO CODE -i  -> same but case-insensitive
  def rgz [pattern: string, query?: string, ...args: string] {
    let dir = if ($query == null) {
      # No query provided - use interactive fzf
      zoxide query --list | fzf --preview 'eza --tree --color=always {} | head -200'
    } else {
      # Query provided - use zoxide query directly
      zoxide query $query
    }
    if ($dir | is-not-empty) {
      ${getExe pkgs.ripgrep} $pattern ...$args $dir
    }
  }

  # Interactive ripgrep: select directory, then enter pattern
  def rgi [...args: string] {
    let dir = (zoxide query --list | fzf --preview 'eza --tree --color=always {} | head -200')
    if ($dir | is-not-empty) {
      let pattern = (input "Search pattern: ")
      if ($pattern | is-not-empty) {
        ${getExe pkgs.ripgrep} $pattern ...$args $dir
      }
    }
  }
''
