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
  si = cfg.selfImprove;

  insightsDir = si.insightsDir;

  # JSON schemas for inter-stage contracts (embedded as nix strings, written to files)
  analysisSchema = pkgs.writeText "analysis-schema.json" (
    builtins.toJSON {
      type = "object";
      required = [
        "findings"
        "metadata"
      ];
      properties = {
        metadata = {
          type = "object";
          required = [
            "report_date"
            "facets_analyzed"
            "config_files_read"
          ];
          properties = {
            report_date = {
              type = "string";
            };
            facets_analyzed = {
              type = "integer";
            };
            config_files_read = {
              type = "integer";
            };
          };
        };
        findings = {
          type = "array";
          items = {
            type = "object";
            required = [
              "id"
              "category"
              "severity"
              "title"
              "description"
              "source"
              "current_state"
              "suggested_action"
            ];
            properties = {
              id = {
                type = "string";
              };
              category = {
                type = "string";
                enum = [
                  "skill-gap"
                  "mcp-suggestion"
                  "hook-improvement"
                  "permission-gap"
                  "claude-md-addition"
                  "workflow-optimization"
                  "config-drift"
                ];
              };
              severity = {
                type = "string";
                enum = [
                  "low"
                  "medium"
                  "high"
                ];
              };
              title = {
                type = "string";
              };
              description = {
                type = "string";
              };
              source = {
                type = "string";
              };
              current_state = {
                type = "string";
              };
              suggested_action = {
                type = "string";
              };
            };
          };
        };
      };
    }
  );

  planSchema = pkgs.writeText "plan-schema.json" (
    builtins.toJSON {
      type = "object";
      required = [
        "items"
        "skipped_findings"
      ];
      properties = {
        items = {
          type = "array";
          items = {
            type = "object";
            required = [
              "id"
              "finding_ids"
              "type"
              "priority"
              "title"
              "target_file"
              "change_type"
              "change_description"
              "rollback_instruction"
              "risk"
            ];
            properties = {
              id = {
                type = "string";
              };
              finding_ids = {
                type = "array";
                items = {
                  type = "string";
                };
              };
              type = {
                type = "string";
                enum = [
                  "config"
                  "skill"
                  "infrastructure"
                  "documentation"
                ];
              };
              priority = {
                type = "string";
                enum = [
                  "low"
                  "medium"
                  "high"
                ];
              };
              title = {
                type = "string";
              };
              target_file = {
                type = "string";
              };
              change_type = {
                type = "string";
                enum = [
                  "edit"
                  "create"
                  "append"
                ];
              };
              change_description = {
                type = "string";
              };
              rollback_instruction = {
                type = "string";
              };
              risk = {
                type = "string";
                enum = [
                  "low"
                  "medium"
                  "high"
                ];
              };
            };
          };
        };
        skipped_findings = {
          type = "array";
          items = {
            type = "object";
            required = [
              "finding_id"
              "reason"
            ];
            properties = {
              finding_id = {
                type = "string";
              };
              reason = {
                type = "string";
              };
            };
          };
        };
      };
    }
  );

  executionSchema = pkgs.writeText "execution-schema.json" (
    builtins.toJSON {
      type = "object";
      required = [
        "results"
        "summary"
      ];
      properties = {
        results = {
          type = "array";
          items = {
            type = "object";
            required = [
              "item_id"
              "status"
              "detail"
              "files_modified"
            ];
            properties = {
              item_id = {
                type = "string";
              };
              status = {
                type = "string";
                enum = [
                  "success"
                  "failure"
                  "skipped"
                ];
              };
              detail = {
                type = "string";
              };
              files_modified = {
                type = "array";
                items = {
                  type = "string";
                };
              };
            };
          };
        };
        summary = {
          type = "object";
          required = [
            "total"
            "succeeded"
            "failed"
            "skipped"
          ];
          properties = {
            total = {
              type = "integer";
            };
            succeeded = {
              type = "integer";
            };
            failed = {
              type = "integer";
            };
            skipped = {
              type = "integer";
            };
          };
        };
      };
    }
  );

  notify-approval = pkgs.writeShellScript "notify-approval" ''
    # notify-approval <plan-summary-path> <approval-json-path>
    # Sends a notification with approve/review/reject actions.
    # Writes result to approval JSON file.
    set -euo pipefail

    PLAN_SUMMARY="$1"
    APPROVAL_FILE="$2"
    TIMEOUT="''${3:-${toString si.approvalTimeout}}"

    ACTION=$(${pkgs.coreutils}/bin/timeout "$TIMEOUT" \
      ${pkgs.libnotify}/bin/notify-send -u normal \
      --action="approve=Approve All" \
      --action="review=Review Plan" \
      --action="reject=Reject" \
      "Self-Improve Pipeline" \
      "Plan ready with $(${pkgs.jq}/bin/jq '.items | length' "$(dirname "$PLAN_SUMMARY")/plan.json") improvements" \
      2>/dev/null) || ACTION="timeout"

    case "$ACTION" in
      approve)
        echo '{"decision":"approved","method":"notification","timestamp":"'"$(${pkgs.coreutils}/bin/date -Iseconds)"'"}' > "$APPROVAL_FILE"
        ;;
      review)
        # Open terminal with plan summary, then prompt for decision
        $TERMINAL -e ${pkgs.bash}/bin/bash -c '
          ${pkgs.glow}/bin/glow "'"$PLAN_SUMMARY"'"
          echo ""
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "  [A]pprove  or  [R]eject?"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          read -r -n1 choice
          if [ "$choice" = "A" ] || [ "$choice" = "a" ]; then
            echo "{\"decision\":\"approved\",\"method\":\"review\",\"timestamp\":\"$(date -Iseconds)\"}" > "'"$APPROVAL_FILE"'"
          else
            echo "{\"decision\":\"rejected\",\"method\":\"review\",\"timestamp\":\"$(date -Iseconds)\"}" > "'"$APPROVAL_FILE"'"
          fi
        '
        # Wait briefly for the file to be written
        sleep 2
        if [ ! -f "$APPROVAL_FILE" ]; then
          echo '{"decision":"rejected","method":"review_no_response","timestamp":"'"$(${pkgs.coreutils}/bin/date -Iseconds)"'"}' > "$APPROVAL_FILE"
        fi
        ;;
      reject)
        echo '{"decision":"rejected","method":"notification","timestamp":"'"$(${pkgs.coreutils}/bin/date -Iseconds)"'"}' > "$APPROVAL_FILE"
        ;;
      timeout)
        echo '{"decision":"rejected","method":"timeout","timestamp":"'"$(${pkgs.coreutils}/bin/date -Iseconds)"'"}' > "$APPROVAL_FILE"
        ;;
    esac
  '';

  notify-results = pkgs.writeShellScript "notify-results" ''
    # notify-results <execution-json-path>
    # Sends a completion notification with a summary.
    set -euo pipefail

    EXEC_FILE="$1"
    SUCCEEDED=$(${pkgs.jq}/bin/jq '.summary.succeeded' "$EXEC_FILE")
    FAILED=$(${pkgs.jq}/bin/jq '.summary.failed' "$EXEC_FILE")
    TOTAL=$(${pkgs.jq}/bin/jq '.summary.total' "$EXEC_FILE")

    if [ "$FAILED" -gt 0 ]; then
      URGENCY="critical"
      MSG="$SUCCEEDED/$TOTAL succeeded, $FAILED failed"
    else
      URGENCY="normal"
      MSG="All $TOTAL improvements applied successfully"
    fi

    ACTION=$(${pkgs.coreutils}/bin/timeout 60 \
      ${pkgs.libnotify}/bin/notify-send -u "$URGENCY" \
      --action="view=View Results" \
      "Self-Improve Complete" \
      "$MSG" 2>/dev/null) || true

    if [ "$ACTION" = "view" ]; then
      $TERMINAL -e ${pkgs.glow}/bin/glow "$(dirname "$EXEC_FILE")/plan-summary.md"
    fi
  '';

  self-improve-pipeline = pkgs.writeShellScript "self-improve-pipeline" ''
        set -euo pipefail

        INSIGHTS_DIR="${insightsDir}"
        RUNS_DIR="$INSIGHTS_DIR/runs"
        RUN_ID="$(${pkgs.coreutils}/bin/date +%Y-%m-%d_%H%M%S)"
        RUN_DIR="$RUNS_DIR/$RUN_ID"
        LOG_FILE="$RUN_DIR/pipeline.log"

        mkdir -p "$RUN_DIR"

        log() {
          echo "[$(${pkgs.coreutils}/bin/date -Iseconds)] $*" >> "$LOG_FILE"
        }

        log "Pipeline started: $RUN_ID"

        # ── Pre-check: verify /insights report exists and is recent ──
        REPORT="$HOME/.claude/usage-data/report.html"
        if [ ! -f "$REPORT" ]; then
          log "No insights report found at $REPORT"
          ${pkgs.libnotify}/bin/notify-send -u normal "Self-Improve Pipeline" \
            "No insights report found. Run /insights first." 2>/dev/null || true
          exit 0
        fi

        REPORT_AGE=$(( $(${pkgs.coreutils}/bin/date +%s) - $(${pkgs.coreutils}/bin/stat -c %Y "$REPORT") ))
        MAX_AGE=$((14 * 86400))
        if [ "$REPORT_AGE" -gt "$MAX_AGE" ]; then
          log "Insights report is $(( REPORT_AGE / 86400 )) days old (max 14)"
          ${pkgs.libnotify}/bin/notify-send -u normal "Self-Improve Pipeline" \
            "Insights report is stale ($(( REPORT_AGE / 86400 ))d old). Run /insights for fresh data." 2>/dev/null || true
          exit 0
        fi

        log "Report found, age: $(( REPORT_AGE / 86400 ))d"

        # ── Stage 1: Analysis ──
        log "Stage 1: Analysis starting"

        ANALYSIS_PROMPT='You are analyzing Claude Code usage insights to identify configuration improvements.

    Read the following files and compare the suggestions in the insights report against current configuration state:

    **Insights data (already analyzed by /insights):**
    - ~/.claude/usage-data/report.html (the full insights report with improvement suggestions)
    - ~/.claude/usage-data/facets/ (per-session structured analysis files, read all JSON files in this directory)

    **Current config state (compare suggestions against these):**
    - ~/.claude/settings.json (permissions, env vars, model config)
    - ~/.claude/CLAUDE.md (global instructions)
    - ~/nix-config/nixos/CLAUDE.md (project instructions)
    - ~/nix-config/nixos/modules/home/cli/claude-code/permissions.nix
    - ~/nix-config/nixos/modules/home/cli/claude-code/mcp-servers.nix

    Also check for skills and hooks:
    - List files in ~/.claude/skills/ to understand existing skills
    - List files in ~/.claude/hooks/ if it exists
    - List files in ~/.claude/agents/ if it exists

    Read the insights report carefully. It contains improvement suggestions for MCP servers, skills, hooks, CLAUDE.md, and workflows. Compare these against the current config state. Identify suggestions that are NOT yet implemented and would genuinely improve AI agent behavior or developer workflow.

    Produce a structured delta of actionable improvements. Each finding should clearly describe:
    - What the insights report suggests
    - What the current config state is
    - What specific action would close the gap

    Be conservative: only include findings where there is a clear, actionable gap between what is suggested and what is configured. Do not include vague or already-implemented suggestions.'

        echo "$ANALYSIS_PROMPT" | claude -p \
          --model "${si.analysisModel}" \
          --output-format json \
          --json-schema "$(${pkgs.coreutils}/bin/cat ${analysisSchema})" \
          --max-budget-usd "${si.budgetAnalysis}" \
          --allowedTools \
            "Read(~/.claude/*)" \
            "Read(~/.claude/**/*)" \
            "Read(~/nix-config/nixos/CLAUDE.md)" \
            "Read(~/nix-config/nixos/modules/home/cli/claude-code/*.nix)" \
            "Grep" \
            "Bash(jq:*)" \
            "Bash(ls:*)" \
          > "$RUN_DIR/raw-stage1.json" 2>>"$LOG_FILE" || true

        SUBTYPE=$(${pkgs.jq}/bin/jq -r '.subtype' "$RUN_DIR/raw-stage1.json" 2>/dev/null || echo "unknown")
        if [ "$SUBTYPE" != "success" ]; then
          ERRORS=$(${pkgs.jq}/bin/jq -r '.errors // ["Unknown error"] | join(", ")' "$RUN_DIR/raw-stage1.json" 2>/dev/null || echo "Unknown error")
          log "Stage 1 failed: $ERRORS"
          ${pkgs.libnotify}/bin/notify-send -u critical "Self-Improve Pipeline" \
            "Stage 1 (Analysis) failed: $ERRORS" 2>/dev/null || true
          exit 1
        fi

        ${pkgs.jq}/bin/jq '.structured_output' "$RUN_DIR/raw-stage1.json" > "$RUN_DIR/analysis.json"
        FINDING_COUNT=$(${pkgs.jq}/bin/jq '.findings | length' "$RUN_DIR/analysis.json")
        COST1=$(${pkgs.jq}/bin/jq -r '.total_cost_usd // 0' "$RUN_DIR/raw-stage1.json")
        log "Stage 1 complete: $FINDING_COUNT findings, cost: \$$COST1"

        if [ "$FINDING_COUNT" -eq 0 ]; then
          log "No findings — pipeline complete"
          ${pkgs.libnotify}/bin/notify-send -u low "Self-Improve Pipeline" \
            "Analysis complete: no improvements needed." 2>/dev/null || true
          exit 0
        fi

        # ── Stage 2: Planning ──
        log "Stage 2: Planning starting"

        ANALYSIS_CONTENT=$(${pkgs.coreutils}/bin/cat "$RUN_DIR/analysis.json")
        PLAN_PROMPT="You are planning configuration improvements for Claude Code based on analysis findings.

    Here are the analysis findings to plan improvements for:

    $ANALYSIS_CONTENT

    For each finding, determine whether it should become an actionable plan item or be skipped (with reason).

    For actionable items, specify:
    - The exact target file path that needs to be modified or created
    - The type of change (edit existing file, create new file, or append to file)
    - A clear description of what to change
    - A rollback instruction (how to undo the change)
    - Risk level (low/medium/high)

    Guidelines:
    - Never plan changes to secret files, .env files, or sops-encrypted content
    - Never plan nixos-rebuild or system activation commands
    - Never plan git commits — the user will review and commit manually
    - Prefer minimal, focused changes over sweeping refactors
    - For Nix module changes, describe the change precisely but keep it contained
    - Skip findings that are too vague, already partially implemented, or would require architectural changes

    Be conservative with risk assessment. Mark anything touching permissions or system config as medium or high risk."

        echo "$PLAN_PROMPT" | claude -p \
          --model "${si.planModel}" \
          --output-format json \
          --json-schema "$(${pkgs.coreutils}/bin/cat ${planSchema})" \
          --max-budget-usd "${si.budgetPlan}" \
          --allowedTools "" \
          > "$RUN_DIR/raw-stage2.json" 2>>"$LOG_FILE" || true

        SUBTYPE=$(${pkgs.jq}/bin/jq -r '.subtype' "$RUN_DIR/raw-stage2.json" 2>/dev/null || echo "unknown")
        if [ "$SUBTYPE" != "success" ]; then
          ERRORS=$(${pkgs.jq}/bin/jq -r '.errors // ["Unknown error"] | join(", ")' "$RUN_DIR/raw-stage2.json" 2>/dev/null || echo "Unknown error")
          log "Stage 2 failed: $ERRORS"
          ${pkgs.libnotify}/bin/notify-send -u critical "Self-Improve Pipeline" \
            "Stage 2 (Planning) failed: $ERRORS" 2>/dev/null || true
          exit 1
        fi

        ${pkgs.jq}/bin/jq '.structured_output' "$RUN_DIR/raw-stage2.json" > "$RUN_DIR/plan.json"
        ITEM_COUNT=$(${pkgs.jq}/bin/jq '.items | length' "$RUN_DIR/plan.json")
        COST2=$(${pkgs.jq}/bin/jq -r '.total_cost_usd // 0' "$RUN_DIR/raw-stage2.json")
        log "Stage 2 complete: $ITEM_COUNT plan items, cost: \$$COST2"

        if [ "$ITEM_COUNT" -eq 0 ]; then
          log "No actionable items — pipeline complete"
          ${pkgs.libnotify}/bin/notify-send -u low "Self-Improve Pipeline" \
            "Planning complete: no actionable improvements." 2>/dev/null || true
          exit 0
        fi

        # Generate human-readable plan summary
        ${pkgs.jq}/bin/jq -r '
          "# Self-Improve Plan\n\n" +
          "**Generated:** \(now | strftime("%Y-%m-%d %H:%M"))\n" +
          "**Items:** \(.items | length)\n\n" +
          "## Planned Changes\n\n" +
          (.items | to_entries | map(
            "### \(.value.id). \(.value.title)\n" +
            "- **Type:** \(.value.type) | **Priority:** \(.value.priority) | **Risk:** \(.value.risk)\n" +
            "- **File:** `\(.value.target_file)`\n" +
            "- **Change:** \(.value.change_type)\n" +
            "- **Description:** \(.value.change_description)\n" +
            "- **Rollback:** \(.value.rollback_instruction)\n"
          ) | join("\n")) +
          (if (.skipped_findings | length) > 0 then
            "\n## Skipped Findings\n\n" +
            (.skipped_findings | map("- **\(.finding_id):** \(.reason)") | join("\n"))
          else "" end)
        ' "$RUN_DIR/plan.json" > "$RUN_DIR/plan-summary.md"

        # ── Stage 3: Approval ──
        log "Stage 3: Awaiting approval"

        ${notify-approval} "$RUN_DIR/plan-summary.md" "$RUN_DIR/approval.json"

        if [ ! -f "$RUN_DIR/approval.json" ]; then
          log "No approval file generated"
          exit 1
        fi

        DECISION=$(${pkgs.jq}/bin/jq -r '.decision' "$RUN_DIR/approval.json")
        log "Approval decision: $DECISION"

        if [ "$DECISION" != "approved" ]; then
          log "Plan rejected or timed out — pipeline complete"
          exit 0
        fi

        # ── Stage 4: Execution ──
        log "Stage 4: Execution starting"

        # Build dynamic allowedTools from plan target files
        DYNAMIC_TOOLS=()
        while IFS= read -r target_file; do
          DYNAMIC_TOOLS+=("Edit($target_file)")
          DYNAMIC_TOOLS+=("Write($target_file)")
          target_dir=$(dirname "$target_file")
          DYNAMIC_TOOLS+=("Read($target_dir/*)")
        done < <(${pkgs.jq}/bin/jq -r '.items[].target_file' "$RUN_DIR/plan.json" | sort -u)
        # Add basic read/inspection tools
        DYNAMIC_TOOLS+=("Bash(cat:*)" "Bash(ls:*)" "Grep")

        PLAN_CONTENT=$(${pkgs.coreutils}/bin/cat "$RUN_DIR/plan.json")
        EXEC_PROMPT="You are executing approved configuration improvements for Claude Code.

    Here is the approved plan to execute:

    $PLAN_CONTENT

    Execute each plan item sequentially. For each item:
    1. Read the target file first to understand its current state
    2. Apply the described change precisely
    3. Verify the change was applied correctly
    4. Record the result

    Important rules:
    - Do NOT create git commits
    - Do NOT run nixos-rebuild or any system activation commands
    - Do NOT modify any files not listed in the plan
    - Do NOT modify secret files, .env files, or sops-encrypted content
    - If a change cannot be applied safely, skip it and record the reason
    - Make minimal, precise edits — do not refactor surrounding code"

        echo "$EXEC_PROMPT" | claude -p \
          --model "${si.executionModel}" \
          --output-format json \
          --json-schema "$(${pkgs.coreutils}/bin/cat ${executionSchema})" \
          --max-budget-usd "${si.budgetExecution}" \
          --allowedTools "''${DYNAMIC_TOOLS[@]}" \
          > "$RUN_DIR/raw-stage4.json" 2>>"$LOG_FILE" || true

        SUBTYPE=$(${pkgs.jq}/bin/jq -r '.subtype' "$RUN_DIR/raw-stage4.json" 2>/dev/null || echo "unknown")
        if [ "$SUBTYPE" != "success" ]; then
          ERRORS=$(${pkgs.jq}/bin/jq -r '.errors // ["Unknown error"] | join(", ")' "$RUN_DIR/raw-stage4.json" 2>/dev/null || echo "Unknown error")
          log "Stage 4 failed: $ERRORS"
          ${pkgs.libnotify}/bin/notify-send -u critical "Self-Improve Pipeline" \
            "Stage 4 (Execution) failed: $ERRORS" 2>/dev/null || true
          exit 1
        fi

        ${pkgs.jq}/bin/jq '.structured_output' "$RUN_DIR/raw-stage4.json" > "$RUN_DIR/execution.json"
        COST4=$(${pkgs.jq}/bin/jq -r '.total_cost_usd // 0' "$RUN_DIR/raw-stage4.json")
        log "Stage 4 complete, cost: \$$COST4"

        # ── Completion ──
        TOTAL_COST=$(echo "$COST1 + $COST2 + $COST4" | ${pkgs.bc}/bin/bc 2>/dev/null || echo "unknown")
        log "Pipeline complete. Total cost: \$$TOTAL_COST"

        ${pkgs.systemd}/bin/systemd-run --user --no-block -- \
          ${notify-results} "$RUN_DIR/execution.json" 2>/dev/null || true
  '';
in
{
  options.${namespace}.cli.claude-code.selfImprove = {
    enable = mkBoolOpt false "Enable the self-improvement pipeline for Claude Code configuration";

    insightsDir = mkOption {
      type = types.str;
      default = "$HOME/proj/AUTOMATE/insights";
      description = "Base directory for pipeline run artifacts";
    };

    schedule = mkOption {
      type = types.str;
      default = "Sun *-*-* 09:00:00";
      description = "Systemd OnCalendar schedule for automatic pipeline runs";
    };

    analysisModel = mkOption {
      type = types.str;
      default = "opus";
      description = "Model for Stage 1 (analysis)";
    };

    planModel = mkOption {
      type = types.str;
      default = "opus";
      description = "Model for Stage 2 (planning)";
    };

    executionModel = mkOption {
      type = types.str;
      default = "opus";
      description = "Model for Stage 4 (execution)";
    };

    budgetAnalysis = mkOption {
      type = types.str;
      default = "3.00";
      description = "Max USD budget for Stage 1 (analysis)";
    };

    budgetPlan = mkOption {
      type = types.str;
      default = "3.00";
      description = "Max USD budget for Stage 2 (planning)";
    };

    budgetExecution = mkOption {
      type = types.str;
      default = "5.00";
      description = "Max USD budget for Stage 4 (execution)";
    };

    approvalTimeout = mkOption {
      type = types.int;
      default = 1800;
      description = "Seconds to wait for human approval before auto-rejecting";
    };
  };

  config = mkIf (cfg.enable && si.enable) {
    # Create pipeline directories on activation
    home.activation.setupSelfImproveDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${insightsDir}/runs"
    '';

    # Systemd service for the pipeline
    systemd.user.services.claude-self-improve = {
      Unit.Description = "Claude Code Self-Improvement Pipeline";
      Service = {
        Type = "oneshot";
        ExecStart = "${self-improve-pipeline}";
        TimeoutStartSec = "1h";
        Environment = [
          "PATH=${
            lib.makeBinPath [
              pkgs.coreutils
              pkgs.jq
              pkgs.gnugrep
              pkgs.gnused
              pkgs.bc
            ]
          }:/run/current-system/sw/bin:%h/.nix-profile/bin"
          "TERMINAL=${pkgs.ghostty}/bin/ghostty"
        ];
      };
    };

    # Systemd timer for scheduled runs
    systemd.user.timers.claude-self-improve = {
      Unit.Description = "Timer for Claude Code Self-Improvement Pipeline";
      Timer = {
        OnCalendar = si.schedule;
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
