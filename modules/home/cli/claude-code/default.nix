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
  options.${namespace}.cli.claude-code = {
    enable = mkBoolOpt false "Enable the claude ai assistant cli tool";
  };

  config = mkIf cfg.enable {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;
      agents = {
        code-reviewer = ''
          ---
          name: code-reviewer
          description: Specialized code review agent
          tools: Read, Edit, Grep
          ---

          You are a principal software engineer specializing in code reviews. Focus on code quality, security, and maintainability.
        '';
        documentation = ''
          ---
          name: documentation
          description: Documentation writing assistant
          model: haiku-4-5-sonnet
          tools: Read, Write, Edit
          ---

          You are a technical writer who creates clear, comprehensive documentation.
          Focus on user-friendly explanations and examples.
        '';
      };
      commands = {
        changelog = ''
          ---
          allowed-tools: Bash(git log:*), Bash(git diff:*)
          argument-hint: [version] [change-type] [message]
          description: Update CHANGELOG.md with new entry
          ---
          Parse the version, change type, and message from the input
          and update the CHANGELOG.md file accordingly.
        '';
        commit = ''
          ---
          allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
          description: Create a git commit with proper message
          ---
          ## Context

          - Current git status: !`git status`
          - Current git diff: !`git diff HEAD`
          - Recent commits: !`git log --oneline -5`

          ## Task

          Based on the changes above, create a single atomic git commit with a descriptive message.
        '';
        fix-issue = ''
          ---
          allowed-tools: Bash(git status:*), Read
          argument-hint: [issue-number]
          description: Fix GitHub issue following coding standards
          ---
          Fix issue #$ARGUMENTS following our coding standards and best practices.
        '';
      };
      hooks = {
        post-commit = ''
          #!/usr/bin/env bash
          echo "Committed with message: $1"
        '';
        pre-edit = ''
          #!/usr/bin/env bash
          echo "About to edit file: $1"
        '';
      };
      mcpServers = {
        nixos = {
          transport = "stdio";
          command = "nix";
          args = [ "run" "github:utensils/mcp-nixos" "--" ];
        };
        ref = {
          type = "http";
          url = "https://api.ref.tools/mcp?apiKey=${config.sops.placeholder.ref_api}";
        };
        github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp/";
        };
      };
      settings = {
        statusLine = {
          enabled = true;
          template = "{{cwd}} • {{git_branch}} {{git_status}}";
          showGitInfo = true;
          refreshIntervalMs = 1000;
          command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')] 📁 $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
          padding = 0;
        };
        includeCoAuthoredBy = false;
        theme = "dark";
        env = {
          "DISABLE_AUTOUPDATER" = 1;
        };
      };
    };
  };
}
