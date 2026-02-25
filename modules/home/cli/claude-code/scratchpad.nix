{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.claude-code;
  scratchpad = cfg.scheduling.scratchpad;
  tasksDir = cfg.scheduling.tasksDir;

  # Pre-check script: skip Claude invocation if no un-staged items
  scratchpad-agent-precheck = pkgs.writeShellScript "scratchpad-agent-precheck" ''
    set -euo pipefail

    SCRATCHPAD="${scratchpad.scratchpadPath}"

    # Check for item lines above --- that are NOT already [STAGED]
    NEW_ITEMS=$(${pkgs.gnused}/bin/sed '/^---$/,$d' "$SCRATCHPAD" \
      | ${pkgs.gnugrep}/bin/grep -E '^- ' \
      | ${pkgs.gnugrep}/bin/grep -v '^\- \[STAGED\]' \
      || true)

    if [ -z "$NEW_ITEMS" ]; then
      echo "No un-staged items in scratchpad. Skipping."
      exit 0
    fi

    # Has new items — invoke the task-runner
    exec ${tasksDir}/task-runner \
      ${tasksDir}/pending/scratchpad-agent.md \
      scratchpad-agent
  '';

  # Review wrapper: interactive Ghostty session for staged draft review
  scratchpad-review-wrapper = pkgs.writeShellScript "scratchpad-review-wrapper" ''
    set -euo pipefail

    NEEDS_ATTN="${tasksDir}/needs-attention/scratchpad"
    SCRATCHPAD="${scratchpad.scratchpadPath}"

    # Skip if nothing staged
    if [ ! -d "$NEEDS_ATTN" ] || [ -z "$(${pkgs.coreutils}/bin/ls -A "$NEEDS_ATTN" 2>/dev/null)" ]; then
      ${pkgs.libnotify}/bin/notify-send -u low "Scratchpad Review" "No staged drafts to review. Skipping."
      exit 0
    fi

    # Build context: list all staged items
    STAGED_ITEMS=$(${pkgs.findutils}/bin/find "$NEEDS_ATTN" -mindepth 1 -maxdepth 1 -type d | ${pkgs.coreutils}/bin/sort)
    ITEM_COUNT=$(echo "$STAGED_ITEMS" | ${pkgs.coreutils}/bin/wc -l)

    REVIEW_PROMPT="You're reviewing $ITEM_COUNT staged scratchpad draft(s) that need your approval.

Staged drafts are in \`$NEEDS_ATTN/\`. For each subdirectory, read its README.md and any draft files, then present the proposed action to the user.

For each item, ask the user: **approve**, **modify**, or **abandon**.

**On approval**:
- For scheduled tasks: move the task file to \`${tasksDir}/pending/\`, walk through the /schedule permission interview (define allowedTools), and create the systemd timer+service
- For one-off tasks: apply the drafted changes to their target locations
- For todos: add the entry to \`${scratchpad.todoJsonPath}\`
- **Remove the \`[STAGED]\` item line AND its \`>\` annotation line(s)** from \`$SCRATCHPAD\`
- Delete the staging subdirectory

**On abandon/reject**:
- **Remove the \`[STAGED]\` item line AND its \`>\` annotation line(s)** from \`$SCRATCHPAD\`
- Delete the staging subdirectory

**On modify**: discuss changes with the user, update the draft, then re-present for approval.

After processing all items, clean up empty directories in \`$NEEDS_ATTN/\`.

Let's start reviewing."

    claude --model "${scratchpad.model}" "$REVIEW_PROMPT"
  '';

  # Task file content for the scratchpad agent
  scratchpad-agent-task = pkgs.writeText "scratchpad-agent.md" ''
    ---
    summary: Triage and annotate DTGE scratchpad items
    schedule: "${scratchpad.agentSchedule}"
    recurring: true
    model: ${scratchpad.model}
    tags: [business, triage, scratchpad]
    allowedTools:
      - "Read(${scratchpad.scratchpadDir}/*)"
      - "Read(${scratchpad.scratchpadDir}/Work/CLAUDE.md)"
      - "Read(${tasksDir}/pending/*)"
      - "Read(${tasksDir}/needs-attention/*)"
      - "Edit(${scratchpad.scratchpadPath})"
      - "Write(${tasksDir}/needs-attention/*)"
      - "Bash(mkdir -p:${tasksDir}/needs-attention/scratchpad/*)"
      - "Bash(cp:${scratchpad.scratchpadDir}/* ${tasksDir}/needs-attention/scratchpad/*)"
      - "Bash(date:*)"
      - "Bash(ls:${tasksDir}/pending/*)"
      - "Grep"
    ---

    # Scratchpad Triage

    ## Context
    The DTGE scratchpad at `${scratchpad.scratchpadPath}` is a quick-capture
    inbox for business ideas and action items. This task triages unprocessed items
    and stages draft actions for human review.

    ## Steps

    1. **Read context**: Read scratchpad.md, todo.json, CLAUDE.md, and list existing
       pending scheduled tasks. Understand current business state and what's already
       tracked/automated.

    2. **Identify un-staged items**: Lines above `---` starting with `- ` that do NOT
       have the `[STAGED]` prefix. Skip `[STAGED]` items entirely. If no un-staged items
       exist, output TASK_RESULT: PASS with "No new items to process."

    3. **For each un-staged item, assess and produce a draft**:

       a. **Determine category**:
          - **One-off task**: Actionable, non-recurring (e.g., "add desktop entry", "find CPA")
          - **Recurring automation**: Needs a scheduled task (e.g., "schedule automation to...")
          - **Research/exploration**: Needs investigation before action
          - **Ambiguous**: Needs clarification from user

       b. **Stage draft work** into `needs-attention/scratchpad/<date>_<slug>/`:
          - Create a `README.md` with: category, concise assessment, proposed action, questions
          - For scheduled tasks: draft a task file following the template format
          - For one-off tasks: draft the deliverable without modifying originals
          - For research: write a brief research plan/outline
          - For ambiguous items: write clarifying questions in the README

       c. **Mark and annotate the scratchpad item**:
          - Replace `- ` prefix with `- [STAGED] `
          - Add a concise `>` annotation on the next line

    4. **Do NOT**:
       - Modify any files outside scratchpad.md and the needs-attention staging area
       - Remove items from the scratchpad (that happens during review sessions)
       - Create systemd timers or services
       - Execute the drafted actions

    ## Success Criteria
    - All un-staged items above `---` were assessed and marked `[STAGED]`
    - Each staged item has a corresponding directory in `needs-attention/scratchpad/`
    - No original files were modified (only scratchpad.md and needs-attention/ contents)
  '';

  # Task file content for the review agent
  scratchpad-review-task = pkgs.writeText "scratchpad-review.md" ''
    ---
    summary: Interactive review of staged scratchpad drafts
    schedule: "${scratchpad.reviewSchedule}"
    recurring: true
    model: ${scratchpad.model}
    tags: [business, review, scratchpad]
    allowedTools:
      - "Bash(${lib.getExe scratchpad.terminal} -e:${scratchpad-review-wrapper})"
    ---

    # Scratchpad Review

    ## Context
    The scratchpad agent triages items hourly and stages drafts into
    `needs-attention/scratchpad/`. This task opens an interactive Ghostty terminal
    3x daily so the user can review, approve, modify, or reject each staged draft.

    ## Steps
    1. Launch terminal with the review wrapper script
    2. The wrapper skips automatically if nothing is staged

    ## Success Criteria
    - Terminal opens with an interactive Claude session (or skips cleanly if empty)
  '';
in
{
  options.${namespace}.cli.claude-code.scheduling.scratchpad = {
    enable = mkBoolOpt false "Enable the scratchpad triage and review agents";

    scratchpadDir = mkOption {
      type = types.str;
      default = "/home/dtgagnon/Documents/DTGE";
      description = "Directory containing scratchpad.md and todo.json";
    };

    scratchpadPath = mkOption {
      type = types.str;
      default = "/home/dtgagnon/Documents/DTGE/scratchpad.md";
      description = "Full path to scratchpad.md";
    };

    todoJsonPath = mkOption {
      type = types.str;
      default = "/home/dtgagnon/Documents/DTGE/todo.json";
      description = "Full path to todo.json";
    };

    agentSchedule = mkOption {
      type = types.str;
      default = "Mon..Fri *-*-* 08..21:00:00";
      description = "Systemd OnCalendar for the triage agent (hourly 8am-9pm weekdays)";
    };

    reviewSchedule = mkOption {
      type = types.str;
      default = "Mon..Fri *-*-* 09,12,15:00:00";
      description = "Systemd OnCalendar for the interactive review sessions";
    };

    model = mkOption {
      type = types.str;
      default = "sonnet";
      description = "Claude model for both agents";
    };

    terminal = mkOption {
      type = types.package;
      default = pkgs.ghostty;
      description = "Terminal emulator for interactive review sessions";
    };
  };

  config = mkIf (cfg.enable && cfg.scheduling.enable && scratchpad.enable) {
    # Place task files in pending/ (only if not already present, to preserve execution logs)
    home.activation.setupScratchpadAgent = lib.hm.dag.entryAfter [ "setupSchedulingDirs" ] ''
      run mkdir -p "${tasksDir}/needs-attention/scratchpad"
      if [ ! -f "${tasksDir}/pending/scratchpad-agent.md" ]; then
        run cp "${scratchpad-agent-task}" "${tasksDir}/pending/scratchpad-agent.md"
      fi
      if [ ! -f "${tasksDir}/pending/scratchpad-review.md" ]; then
        run cp "${scratchpad-review-task}" "${tasksDir}/pending/scratchpad-review.md"
      fi
    '';

    # Scratchpad agent — autonomous triage (hourly, with pre-check)
    systemd.user.services.scratchpad-agent = {
      Unit = {
        Description = "Scratchpad agent — triage and annotate";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        WorkingDirectory = builtins.replaceStrings [ "$HOME" ] [ "%h" ] tasksDir;
        ExecStart = "${scratchpad-agent-precheck}";
        TimeoutStartSec = "10m";
        Environment = [
          "PATH=${
            lib.makeBinPath [
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.gnused
              pkgs.findutils
            ]
          }:/run/current-system/sw/bin:%h/.nix-profile/bin"
        ];
      };
    };

    systemd.user.timers.scratchpad-agent = {
      Unit.Description = "Timer for scratchpad agent — triage and annotate";
      Timer = {
        OnCalendar = scratchpad.agentSchedule;
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };

    # Scratchpad-review agent — interactive Ghostty session
    systemd.user.services.scratchpad-review = {
      Unit = {
        Description = "Scratchpad-review agent — interactive draft review";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        WorkingDirectory = builtins.replaceStrings [ "$HOME" ] [ "%h" ] tasksDir;
        ExecStart = "${lib.getExe scratchpad.terminal} -e ${scratchpad-review-wrapper}";
        TimeoutStartSec = "2h";
        Environment = [
          "PATH=${
            lib.makeBinPath [
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.gnused
              pkgs.findutils
            ]
          }:/run/current-system/sw/bin:%h/.nix-profile/bin"
        ];
      };
    };

    systemd.user.timers.scratchpad-review = {
      Unit.Description = "Timer for scratchpad-review agent — interactive draft review";
      Timer = {
        OnCalendar = scratchpad.reviewSchedule;
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
