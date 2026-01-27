{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.claude-code;

  # Direnv initialization script for bash sessions spawned by Claude Code
  # Guard prevents re-entry when direnv spawns bash subprocesses during evaluation
  direnvInitScript = pkgs.writeText "claude-bash-init.sh" ''
    if command -v direnv >/dev/null 2>&1; then
      if [ -n "$CLAUDECODE" ] && [ -z "$__CLAUDE_DIRENV_LOADED" ]; then
        export __CLAUDE_DIRENV_LOADED=1
        eval "$(DIRENV_LOG_FORMAT= direnv export bash)"
      fi
    fi
  '';

  # Wrapped claude-code package that injects secrets as environment variables
  claude-wrapped = pkgs.symlinkJoin {
    name = "claude-code-wrapped";
    paths = [ pkgs.claude-code ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --add-flags "--allow-dangerously-skip-permissions" \
        ${lib.optionalString cfg.direnvIntegration "--set BASH_ENV ${direnvInitScript}"} \
        --run 'export N8N_ACCESS_TOKEN=$(cat ${config.sops.secrets.n8n_access_token.path})' \
        --run 'export REF_API_KEY=$(cat ${config.sops.secrets.ref_api.path})' \
        --run 'export GITHUB_READ_TOKEN=$(cat ${config.sops.secrets.github_read_token.path})' \
        --run 'export ODOO_API_KEY=$(cat ${config.sops.secrets.odoo_api_key.path})' \
        --run 'set -a; source ${config.sops.secrets.mxroute-env.path}; set +a'
    '';
    meta = {
      mainProgram = "claude";
    };
  };
in
{
  # Conditionally import sub-modules.
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.${namespace}.cli.claude-code = {
    enable = mkBoolOpt false "Enable the claude ai assistant cli tool";
    router = mkBoolOpt false "Enable the claude-code-router package for allow other LLMs to be used";
    direnvIntegration = mkBoolOpt true "Auto-load direnv environments in Claude Code bash sessions";
  };

  config = mkIf cfg.enable {
    # Declare preservation needs for this module
    ${namespace}.preservation = {
      directories = [ ".claude" ];
      files = [ ".claude.json" ];
    };

    home.packages = mkIf cfg.router [ pkgs.claude-code-router ];
    programs.claude-code = {
      enable = true;
      package = claude-wrapped;
      settings = {
        includeCoAuthoredBy = false;
        spinnerTipsEnabled = false;
        theme = "dark";
        env = {
          "DISABLE_AUTOUPDATER" = 1;
          "ENABLE_EXPERIMENTAL_MCP_CLI" = true;
          "ENABLE_LSP_TOOL" = true;
        };
        models = {
          opus = { };
          haiku = { };
          sonnet = { };
        };
        statusLine = {
          type = "command";
          command = let
            colors = config.lib.stylix.colors;
            c = base: "\\033[38;2;${toString colors."${base}-rgb-r"};${toString colors."${base}-rgb-g"};${toString colors."${base}-rgb-b"}m";
          in ''
            input=$(cat)
            MODEL=$(echo "$input" | jq -r '.model.display_name')
            DIR=$(echo "$input" | jq -r '.workspace.current_dir')
            DIRNAME=$(basename "$DIR")
            TIME=$(date +"%I:%M %p")

            # Stylix colors (injected at build time)
            C_DIR=$'${c "base0D"}'
            C_GIT=$'${c "base0E"}'
            C_MODEL=$'${c "base0A"}'
            C_TIME=$'${c "base05"}'
            C_SEP=$'${c "base03"}'
            C_RESET=$'\033[0m'

            # Git info - symbol only shown when in a git repo
            GIT_INFO=""
            if git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1; then
              BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
              STATUS=""
              if [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ]; then
                STATUS="*"
              fi
              if [ -n "$BRANCH" ]; then
                GIT_INFO=" ''${C_GIT}  $BRANCH$STATUS''${C_RESET}"
              fi
            fi

            echo "''${C_DIR}$DIRNAME''${C_RESET}$GIT_INFO ''${C_SEP}│''${C_RESET} ''${C_MODEL}$MODEL''${C_RESET} ''${C_SEP}│''${C_RESET} ''${C_TIME}$TIME''${C_RESET}"
          '';
        };
      };
    };
  };
}
