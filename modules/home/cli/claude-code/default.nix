{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.claude-code;
in
{
  # Conditionally import sub-modules.
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.${namespace}.cli.claude-code = {
    enable = mkBoolOpt false "Enable the claude ai assistant cli tool";
  };

  config = mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;
      settings = {
        includeCoAuthoredBy = false;
        theme = "dark";
        permissions = {
          allow = [
            "Bash(git diff:*)"
            "Bash(git status:*)"
          ];
          ask = [
            "Bash(curl:*)"
          ];
          deny = [
            "Read(./.env)"
            "Read(./secrets/**)"
          ];
        };
        env = {
          "DISABLE_AUTOUPDATER" = 1;
        };
        models = {
          opus = { };
          haiku = { };
          sonnet = { };
        };
        statusLine = {
          type = "command";
          command = ''
            input=$(cat)
            MODEL=$(echo "$input" | jq -r '.model.display_name')
            DIR=$(echo "$input" | jq -r '.workspace.current_dir')
            DIRNAME=$(basename "$DIR")

            # Get git info if in a git repo
            GIT_INFO=""
            if git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1; then
              BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
              # Get git status indicators
              STATUS=""
              if [ -n "$(git -C "$DIR" status --porcelain 2>/dev/null)" ]; then
                STATUS="*"
              fi
              if [ -n "$BRANCH" ]; then
                GIT_INFO=" | $BRANCH$STATUS"
              fi
            fi

            echo "[$MODEL] 📁 $DIRNAME$GIT_INFO"
          '';
        };
      };
    };
  };
}
