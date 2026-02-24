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

  tasksDir = cfg.scheduling.tasksDir;

  notify-monitor = pkgs.writeShellScript "notify-monitor" ''
    # notify-monitor <task-name> <log-file-path>
    # Sends a desktop notification with an action to tail the live log.
    # Self-terminates after 60s if the notification is never acted on.
    TASK_NAME="$1"
    LOG_FILE="$2"

    ACTION=$(${pkgs.coreutils}/bin/timeout 60 \
      ${pkgs.libnotify}/bin/notify-send -u normal \
      --action="monitor=Monitor Log" "Agent Action" \
      "Starting task: $TASK_NAME" 2>/dev/null) || true

    if [ "$ACTION" = "monitor" ]; then
      $TERMINAL -e ${pkgs.bash}/bin/bash -c \
        '${pkgs.coreutils}/bin/cat "$1" 2>/dev/null; exec ${pkgs.coreutils}/bin/tail -f "$1"' \
        _ "$LOG_FILE"
    fi
  '';

  notify-completion = pkgs.writeShellScript "notify-completion" ''
    # notify-completion <task-name> <completed-file-path>
    # Sends a desktop notification with an action to view the completed task log.
    # Self-terminates after 30s if the notification is never acted on.
    TASK_NAME="$1"
    COMPLETED_FILE="$2"

    ACTION=$(${pkgs.coreutils}/bin/timeout 30 \
      ${pkgs.libnotify}/bin/notify-send -u normal \
      --action="view=View Log" "Agent Action" \
      "Task completed: $TASK_NAME" 2>/dev/null) || true

    if [ "$ACTION" = "view" ]; then
      $TERMINAL -e ${pkgs.glow}/bin/glow "$COMPLETED_FILE"
    fi
  '';

  task-runner = pkgs.writeShellScript "task-runner" ''
    # task-runner <task-file> <unit-name>
    # Called by systemd service ExecStart
    #
    # Reads a task file with YAML frontmatter, extracts allowedTools,
    # runs claude with those permissions, checks for TASK_RESULT token,
    # and handles pass/fail/retry/cleanup.

    set -euo pipefail

    TASK_FILE="$1"
    UNIT_NAME="$2"
    TASKS_DIR="${tasksDir}"
    MAX_ATTEMPTS=3
    RETRY_DELAY="1h"
    mkdir -p "$TASKS_DIR/needs-attention"

    # Check if this is a recurring task
    RECURRING=$(${pkgs.gnugrep}/bin/grep -m1 '^recurring:' "$TASK_FILE" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -o 'true' || echo "false")

    # Parse model preference (default: sonnet)
    MODEL=$(${pkgs.gnugrep}/bin/grep -m1 '^model:' "$TASK_FILE" 2>/dev/null | ${pkgs.gnused}/bin/sed 's/^model:[[:space:]]*//' | ${pkgs.coreutils}/bin/tr -d '"' || echo "")
    MODEL="''${MODEL:-sonnet}"

    # Parse recurring lifecycle limits
    MAX_ITERATIONS=$(${pkgs.gnugrep}/bin/grep -m1 '^max_iterations:' "$TASK_FILE" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -oP '\d+' || echo "0")
    UNTIL_DATE=$(${pkgs.gnugrep}/bin/grep -m1 '^until:' "$TASK_FILE" 2>/dev/null | ${pkgs.gnused}/bin/sed 's/^until:[[:space:]]*//' | ${pkgs.coreutils}/bin/tr -d '"' || echo "")

    # Extract allowedTools from YAML frontmatter
    ALLOWED_TOOLS=()
    in_tools=false
    while IFS= read -r line; do
      if [[ "$line" =~ ^allowedTools: ]]; then
        in_tools=true; continue
      fi
      if $in_tools; then
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
          tool="''${BASH_REMATCH[1]}"
          tool="''${tool%\"}"
          tool="''${tool#\"}"
          ALLOWED_TOOLS+=("$tool")
        else
          break
        fi
      fi
    done < "$TASK_FILE"

    # Build --allowedTools arguments (single flag, tools as variadic args)
    if [ ''${#ALLOWED_TOOLS[@]} -eq 0 ]; then
      echo "ERROR: No allowedTools found in task frontmatter. Refusing to run without permissions." >&2
      exit 1
    fi

    TASK_CONTENT=$(${pkgs.coreutils}/bin/cat "$TASK_FILE")
    TASK_NAME=$(basename "$TASK_FILE")

    cleanup_units() {
      ${pkgs.systemd}/bin/systemctl --user disable "$UNIT_NAME.timer" 2>/dev/null || true
      rm -f "$HOME/.config/systemd/user/$UNIT_NAME.timer"
      rm -f "$HOME/.config/systemd/user/$UNIT_NAME.service"
      ${pkgs.systemd}/bin/systemctl --user daemon-reload
    }

    schedule_retry() {
      local timer_file="$HOME/.config/systemd/user/$UNIT_NAME.timer"
      if [ -f "$timer_file" ]; then
        # systemd OnCalendar uses space separator, not ISO 8601 "T"
        ${pkgs.gnused}/bin/sed -i "s/^OnCalendar=.*/OnCalendar=$(${pkgs.coreutils}/bin/date -d "+''${RETRY_DELAY}" '+%Y-%m-%d %H:%M:%S')/" "$timer_file"
        ${pkgs.systemd}/bin/systemctl --user daemon-reload
        ${pkgs.systemd}/bin/systemctl --user restart "$UNIT_NAME.timer"
      fi
    }

    finalize_recurring() {
      local reason="$1"
      rm -f "$TASKS_DIR/needs-attention/$TASK_NAME" 2>/dev/null || true
      mv "$TASK_FILE" "$TASKS_DIR/completed/"
      cleanup_units
      ${pkgs.systemd}/bin/systemd-run --user --no-block -- \
        ${notify-completion} "$TASK_NAME" "$TASKS_DIR/completed/$TASK_NAME" 2>/dev/null || true
      echo "Recurring task finished ($reason) — cleaned up"
    }

    # Pre-execution check: skip if past the until date
    if [ "$RECURRING" = "true" ] && [ -n "$UNTIL_DATE" ]; then
      if [ "$(${pkgs.coreutils}/bin/date +%s)" -ge "$(${pkgs.coreutils}/bin/date -d "$UNTIL_DATE" +%s 2>/dev/null || echo 0)" ]; then
        finalize_recurring "until date reached"
        exit 0
      fi
    fi

    # Set up log file for monitoring (one line per assistant turn / tool result)
    mkdir -p "$TASKS_DIR/logs"
    LOG_STEM="''${TASK_NAME%.md}-$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)"
    LOG_FILE="$TASKS_DIR/logs/$LOG_STEM.jsonl"

    # Notify task start (non-blocking, with action to open live log)
    ${pkgs.systemd}/bin/systemd-run --user --no-block -- \
      ${notify-monitor} "$TASK_NAME" "$LOG_FILE" 2>/dev/null || true

    # Count previous attempts (grep -c prints 0 on no match but exits 1; capture output, ignore exit)
    ATTEMPT_COUNT=$(${pkgs.gnugrep}/bin/grep -c '^## .*Execution' "$TASK_FILE" 2>/dev/null || true)
    ATTEMPT_COUNT=''${ATTEMPT_COUNT:-0}
    ATTEMPT_COUNT=$((ATTEMPT_COUNT + 1))

    # Execute task via claude with approved permissions.
    # NOTE: prompt must go via stdin because --allowedTools is variadic and
    # consumes all subsequent positional arguments.
    # Uses stream-json for per-turn log visibility (tail -f the log file).
    PROMPT="You are executing a scheduled task autonomously. Follow the steps exactly.

After completing ALL steps, verify each Success Criterion is met.
You MUST end your response with exactly one of these lines:
  TASK_RESULT: PASS
  TASK_RESULT: FAIL — <reason>
This is required for the automation system to process your result.

$TASK_CONTENT"

    echo "$PROMPT" | claude -p \
      --model "$MODEL" \
      --output-format stream-json \
      --verbose \
      --allowedTools "''${ALLOWED_TOOLS[@]}" \
      2>&1 | ${pkgs.coreutils}/bin/tee "$LOG_FILE" > /dev/null || true

    # Extract final result text from the stream-json log
    OUTPUT=$(${pkgs.gnugrep}/bin/grep '"type":"result"' "$LOG_FILE" \
      | ${pkgs.gnused}/bin/sed 's/.*"result":"\(.*\)","stop_reason".*/\1/' || echo "")
    # Unescape JSON newlines
    OUTPUT=$(printf '%b' "$OUTPUT")

    # Determine result
    if echo "$OUTPUT" | ${pkgs.gnugrep}/bin/grep -q "TASK_RESULT: PASS"; then
      RESULT="pass"
    elif echo "$OUTPUT" | ${pkgs.gnugrep}/bin/grep -q "TASK_RESULT: FAIL"; then
      RESULT="fail"
    else
      RESULT="inconclusive"
    fi

    NOW=$(${pkgs.coreutils}/bin/date -Iseconds)

    case "$RESULT" in
      pass)
        printf '\n---\n\n## Execution Log — attempt %d (%s)\n\n```\n%s\n```\n' \
          "$ATTEMPT_COUNT" "$NOW" "$OUTPUT" >> "$TASK_FILE"
        # Clean up log file on success
        rm -f "$LOG_FILE" 2>/dev/null || true
        if [ "$RECURRING" = "true" ]; then
          # Clean up any needs-attention symlink from a previous failure
          rm -f "$TASKS_DIR/needs-attention/$TASK_NAME" 2>/dev/null || true
          # Check if max iterations reached
          ITERATION_COUNT=$(${pkgs.gnugrep}/bin/grep -c '^## Execution Log' "$TASK_FILE" 2>/dev/null || echo "0")
          if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION_COUNT" -ge "$MAX_ITERATIONS" ]; then
            finalize_recurring "max iterations ($MAX_ITERATIONS) reached"
          else
            ${pkgs.libnotify}/bin/notify-send -u normal "Agent Action" \
              "Recurring task completed: $TASK_NAME" 2>/dev/null || true
            echo "Recurring task PASS — staying scheduled"
          fi
        else
          mv "$TASK_FILE" "$TASKS_DIR/completed/"
          cleanup_units
          ${pkgs.systemd}/bin/systemd-run --user --no-block -- \
            ${notify-completion} "$TASK_NAME" "$TASKS_DIR/completed/$TASK_NAME" 2>/dev/null || true
          echo "Task verified PASS — cleaned up"
        fi
        ;;
      fail|inconclusive)
        LABEL=$( [ "$RESULT" = "inconclusive" ] && echo "Inconclusive (no TASK_RESULT token)" || echo "Failed" )
        printf '\n---\n\n## %s Execution — attempt %d/%d (%s)\n\nLog: %s\n\n```\n%s\n```\n' \
          "$LABEL" "$ATTEMPT_COUNT" "$MAX_ATTEMPTS" "$NOW" "$LOG_FILE" "$OUTPUT" >> "$TASK_FILE"

        if [ "$RECURRING" = "true" ]; then
          # Symlink into needs-attention for visibility; file stays in pending so the timer still works
          ln -sf "$TASK_FILE" "$TASKS_DIR/needs-attention/$TASK_NAME" 2>/dev/null || true
          FAIL_ACTION=$(${pkgs.coreutils}/bin/timeout 30 \
            ${pkgs.libnotify}/bin/notify-send -u critical \
            --action="log=View Log" "Agent Action" \
            "Recurring task failed: $TASK_NAME" 2>/dev/null) || true
          if [ "$FAIL_ACTION" = "log" ]; then
            $TERMINAL -e ${pkgs.bat}/bin/bat --paging=always "$LOG_FILE" &
          fi
          echo "Recurring task $RESULT — symlinked to needs-attention, timer stays active"
        elif [ "$ATTEMPT_COUNT" -ge "$MAX_ATTEMPTS" ]; then
          echo "Max attempts ($MAX_ATTEMPTS) reached — moving to needs-attention"
          mv "$TASK_FILE" "$TASKS_DIR/needs-attention/"
          cleanup_units
          ATTN_ACTION=$(${pkgs.coreutils}/bin/timeout 30 \
            ${pkgs.libnotify}/bin/notify-send -u critical \
            --action="log=View Log" "Agent Action" \
            "Task $(basename "$TASK_FILE") needs attention after $MAX_ATTEMPTS attempts" 2>/dev/null) || true
          if [ "$ATTN_ACTION" = "log" ]; then
            $TERMINAL -e ${pkgs.bat}/bin/bat --paging=always "$LOG_FILE" &
          fi
        else
          echo "Attempt $ATTEMPT_COUNT/$MAX_ATTEMPTS $RESULT — scheduling retry in $RETRY_DELAY"
          schedule_retry
        fi
        exit 1
        ;;
    esac
  '';
in
{
  options.${namespace}.cli.claude-code.scheduling = {
    enable = mkBoolOpt false "Enable the /schedule skill and task-runner infrastructure for autonomous AI-agent tasks";
    tasksDir = mkOption {
      type = types.str;
      default = "$HOME/proj/AUTOMATE/scheduled";
      description = "Directory for task files (pending, completed, needs-attention, templates)";
    };
  };

  config = mkIf (cfg.enable && cfg.scheduling.enable) {
    # Preserve systemd user units across reboots so timers survive
    ${namespace}.preservation.directories = [
      ".config/systemd/user"
    ];

    # Create task directories and symlink the nix-managed task-runner
    home.activation.setupSchedulingDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${tasksDir}/pending"
      run mkdir -p "${tasksDir}/completed"
      run mkdir -p "${tasksDir}/needs-attention"
      run mkdir -p "${tasksDir}/templates"
      run mkdir -p "${tasksDir}/scripts"
      run mkdir -p "${tasksDir}/logs"
      run ln -sf "${task-runner}" "${tasksDir}/task-runner"
    '';
  };
}
