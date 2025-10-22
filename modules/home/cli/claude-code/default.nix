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
        gemini = ''
          ---
          allowed-tools: Bash(gemini "*":*), Bash(gemini -y:*), Bash(gemini -m:*), Bash(gemini -o:*)
          argument-hint: [query]
          description: Quick queries using Gemini (facts, lookups, syntax)
          ---
          ## Task

          Use Gemini CLI to get a fast response for: $ARGUMENTS

          Run the following command and present the response:

          !`gemini "$ARGUMENTS" -y -o json 2>/dev/null | jq -r '.response'`

          **Use Gemini for:**
          - Quick factual lookups and explanations
          - Syntax questions in unfamiliar languages
          - Alternative implementation ideas
          - Non-code research and brainstorming
        '';
        gemini-research = ''
          ---
          allowed-tools: Bash(gemini "*":*), Bash(gemini -y:*), Bash(gemini -m:*), Bash(gemini -o:*)
          argument-hint: [topic]
          description: Deep research using Gemini with web search
          ---
          ## Task

          Use Gemini to research: $ARGUMENTS

          Gemini has web search capabilities. Ask it to search for current documentation,
          latest API changes, best practices, or package availability.

          Run: !`gemini "Research the following topic, use web search if needed: $ARGUMENTS" -y -o json 2>/dev/null | jq -r '.response'`

          Present the findings to help inform our implementation strategy.
        '';
        gemini-compare = ''
          ---
          allowed-tools: Bash(gemini "*":*), Bash(gemini -y:*), Bash(gemini -m:*), Bash(gemini -o:*)
          argument-hint: [options-to-compare]
          description: Get multiple approaches/perspectives from Gemini
          ---
          ## Task

          Ask Gemini to compare different approaches for: $ARGUMENTS

          Run: !`gemini "Provide 3 different approaches or perspectives for: $ARGUMENTS. Compare their trade-offs." -y -o json 2>/dev/null | jq -r '.response'`

          Use this to explore alternative solutions before committing to an approach.
        '';
        codex = ''
          ---
          allowed-tools: Bash(codex exec:*)
          argument-hint: [code-task]
          description: Code generation/exploration using Codex (read-only)
          ---
          ## Task

          Use Codex to explore: $ARGUMENTS

          Run in read-only sandbox mode for safe code exploration:

          !`codex exec "$ARGUMENTS" -s read-only 2>&1 | sed -n '/^codex$/,/^tokens used$/p' | sed '1d;$d'`

          **Use Codex read-only mode for:**
          - Testing unfamiliar syntax before using it
          - Generating example code for learning
          - Validating regex patterns or command flags
          - Quick code explanations

          Review the response and integrate useful insights.
        '';
        codex-build = ''
          ---
          allowed-tools: Bash(codex exec:*)
          argument-hint: [description]
          description: Generate and execute code using Codex (workspace-write)
          ---
          ## Task

          Use Codex to build: $ARGUMENTS

          ⚠️  This runs in workspace-write mode - Codex can create/modify files.

          Run: !`codex exec "$ARGUMENTS" --full-auto 2>&1 | sed -n '/^codex$/,/^tokens used$/p' | sed '1d;$d'`

          **Use Codex workspace-write for:**
          - Generating boilerplate files
          - Creating test fixtures
          - Building quick utilities or scripts

          Review what Codex created and verify it meets requirements.
        '';
        codex-analyze = ''
          ---
          allowed-tools: Bash(codex exec:*)
          argument-hint: [image-path] [question]
          description: Analyze images/diagrams using Codex
          ---
          ## Task

          Use Codex to analyze an image.

          Extract image path and question from: $ARGUMENTS

          Run: !`codex exec "[question about image]" -i [image-path] -s read-only 2>&1 | sed -n '/^codex$/,/^tokens used$/p' | sed '1d;$d'`

          **Use for analyzing:**
          - Architecture diagrams
          - Screenshots of errors or UI
          - Flowcharts or wireframes

          Present Codex's analysis to inform our implementation.
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
        includeCoAuthoredBy = false;
        theme = "dark";
        env = {
          "DISABLE_AUTOUPDATER" = 1;
        };
      };
    };
  };
}
