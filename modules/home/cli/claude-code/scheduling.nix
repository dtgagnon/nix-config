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

    # Build --allowedTools arguments
    TOOLS_ARGS=()
    for tool in "''${ALLOWED_TOOLS[@]}"; do
      TOOLS_ARGS+=("--allowedTools" "$tool")
    done

    if [ ''${#TOOLS_ARGS[@]} -eq 0 ]; then
      echo "ERROR: No allowedTools found in task frontmatter. Refusing to run without permissions." >&2
      exit 1
    fi

    TASK_CONTENT=$(${pkgs.coreutils}/bin/cat "$TASK_FILE")

    # Count previous attempts
    ATTEMPT_COUNT=$(${pkgs.gnugrep}/bin/grep -c '^## .*Execution' "$TASK_FILE" 2>/dev/null || echo 0)
    ATTEMPT_COUNT=$((ATTEMPT_COUNT + 1))

    # Execute task via claude with approved permissions
    OUTPUT=$(claude -p "You are executing a scheduled task autonomously. Follow the steps exactly.

    After completing ALL steps, verify each Success Criterion is met.
    You MUST end your response with exactly one of these lines:
      TASK_RESULT: PASS
      TASK_RESULT: FAIL — <reason>
    This is required for the automation system to process your result.

    $TASK_CONTENT" "''${TOOLS_ARGS[@]}" 2>&1) || true

    # Determine result
    if echo "$OUTPUT" | ${pkgs.gnugrep}/bin/grep -q "TASK_RESULT: PASS"; then
      RESULT="pass"
    elif echo "$OUTPUT" | ${pkgs.gnugrep}/bin/grep -q "TASK_RESULT: FAIL"; then
      RESULT="fail"
    else
      RESULT="inconclusive"
    fi

    NOW=$(${pkgs.coreutils}/bin/date -Iseconds)

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

    case "$RESULT" in
      pass)
        printf '\n---\n\n## Execution Log — attempt %d (%s)\n\n```\n%s\n```\n' \
          "$ATTEMPT_COUNT" "$NOW" "$OUTPUT" >> "$TASK_FILE"
        mv "$TASK_FILE" "$TASKS_DIR/completed/"
        cleanup_units
        echo "Task verified PASS — cleaned up"
        ;;
      fail|inconclusive)
        LABEL=$( [ "$RESULT" = "inconclusive" ] && echo "Inconclusive (no TASK_RESULT token)" || echo "Failed" )
        printf '\n---\n\n## %s Execution — attempt %d/%d (%s)\n\n```\n%s\n```\n' \
          "$LABEL" "$ATTEMPT_COUNT" "$MAX_ATTEMPTS" "$NOW" "$OUTPUT" >> "$TASK_FILE"

        if [ "$ATTEMPT_COUNT" -ge "$MAX_ATTEMPTS" ]; then
          echo "Max attempts ($MAX_ATTEMPTS) reached — moving to needs-attention"
          mv "$TASK_FILE" "$TASKS_DIR/needs-attention/"
          cleanup_units
          ${pkgs.libnotify}/bin/notify-send -u critical "Task Runner" \
            "Task $(basename "$TASK_FILE") needs attention after $MAX_ATTEMPTS attempts" 2>/dev/null || true
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
      default = "$HOME/proj/AUTOMATE/tasks";
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
      run ln -sf "${task-runner}" "${tasksDir}/task-runner"
    '';
  };
}
