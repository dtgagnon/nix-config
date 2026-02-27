# Parallel test derivation of the scratchpad scripts generated inline by:
#   ../../modules/home/cli/claude-code/scheduled/scratchpad.nix
#
# That module uses pkgs.writeShellScript with Nix-interpolated paths baked in at
# evaluation time. This standalone derivation parameterises those same paths as
# runtime environment variables so the binaries can be used without recompilation.
#
# Required env vars are listed per-binary below and are guarded with
# ${VAR:?error message} so missing values cause a clear early failure.
{
  lib,
  pkgs,
  writeShellApplication,
  symlinkJoin,
  coreutils,
  gnugrep,
  gnused,
  findutils,
  libnotify,
}:
let
  # ---------------------------------------------------------------------------
  # scratchpad-precheck
  #
  # Equivalent to the `precheck` writeShellScript in scratchpad.nix.
  #
  # Required runtime environment variables:
  #   SCRATCHPAD_PATH    — absolute path to the <name>-scratchpad.md file
  #   TASKS_DIR          — absolute path to the tasks root directory
  #   AGENT_TASK_NAME    — name of the agent task (e.g. scratchpad-agent-work)
  #
  # The script looks for un-staged items (lines beginning with "- " above the
  # "---" separator that are NOT already "[STAGED]") and, when found, delegates
  # to the task-runner script located at $TASKS_DIR/task-runner.
  # ---------------------------------------------------------------------------
  precheck = writeShellApplication {
    name = "scratchpad-precheck";

    runtimeInputs = [
      coreutils
      gnugrep
      gnused
      findutils
    ];

    text = ''
      # Validate required environment variables
      : "''${SCRATCHPAD_PATH:?SCRATCHPAD_PATH must be set to the path of the scratchpad markdown file}"
      : "''${TASKS_DIR:?TASKS_DIR must be set to the tasks root directory}"
      : "''${AGENT_TASK_NAME:?AGENT_TASK_NAME must be set (e.g. scratchpad-agent-work)}"

      SCRATCHPAD="$SCRATCHPAD_PATH"

      # Check for item lines above --- that are NOT already [STAGED]
      NEW_ITEMS=$(sed '/^---$/,$d' "$SCRATCHPAD" \
        | grep -E '^- ' \
        | grep -v '^\- \[STAGED\]' \
        || true)

      if [ -z "$NEW_ITEMS" ]; then
        echo "No un-staged items in scratchpad ($AGENT_TASK_NAME). Skipping."
        exit 0
      fi

      # Has new items — invoke the task-runner
      exec "$TASKS_DIR/task-runner" \
        "$TASKS_DIR/pending/$AGENT_TASK_NAME.md" \
        "$AGENT_TASK_NAME"
    '';
  };

  # ---------------------------------------------------------------------------
  # scratchpad-review
  #
  # Equivalent to the `reviewWrapper` writeShellScript in scratchpad.nix.
  #
  # Required runtime environment variables:
  #   NEEDS_ATTN_DIR     — absolute path to the needs-attention staging directory
  #                        (e.g. $TASKS_DIR/needs-attention/scratchpad-<name>)
  #   SCRATCHPAD_PATH    — absolute path to the <name>-scratchpad.md file
  #   SCRATCHPAD_NAME    — human-readable scratchpad name used in notifications
  #                        and review prompt text (e.g. "work")
  #   TASKS_DIR          — absolute path to the tasks root directory (used in
  #                        the review prompt for pending/ and todo.json paths)
  #   TODO_JSON_PATH     — absolute path to the <name>-todo.json file
  #   CLAUDE_MODEL       — claude model string to pass to `claude --model`
  #                        (e.g. "sonnet" or "claude-opus-4-6")
  #
  # The script skips (with a low-urgency desktop notification) if nothing is
  # staged in NEEDS_ATTN_DIR.  Otherwise it constructs the review prompt
  # (preserving the heredoc from the original) and launches claude interactively.
  #
  # Note: the original module launches this script inside a terminal emulator
  # via the systemd service's ExecStart.  This binary is the inner script; the
  # caller is responsible for wrapping it in the desired terminal (e.g.
  # `ghostty -e scratchpad-review`).
  # ---------------------------------------------------------------------------
  review = writeShellApplication {
    name = "scratchpad-review";

    runtimeInputs = [
      coreutils
      findutils
      libnotify
    ];

    text = ''
      # Validate required environment variables
      : "''${NEEDS_ATTN_DIR:?NEEDS_ATTN_DIR must be set to the needs-attention staging directory}"
      : "''${SCRATCHPAD_PATH:?SCRATCHPAD_PATH must be set to the path of the scratchpad markdown file}"
      : "''${SCRATCHPAD_NAME:?SCRATCHPAD_NAME must be set to the scratchpad instance name (e.g. work)}"
      : "''${TASKS_DIR:?TASKS_DIR must be set to the tasks root directory}"
      : "''${TODO_JSON_PATH:?TODO_JSON_PATH must be set to the todo.json file path}"
      : "''${CLAUDE_MODEL:?CLAUDE_MODEL must be set to the claude model string (e.g. sonnet)}"

      NEEDS_ATTN="$NEEDS_ATTN_DIR"
      SCRATCHPAD="$SCRATCHPAD_PATH"

      # Skip if nothing staged
      if [ ! -d "$NEEDS_ATTN" ] || [ -z "$(ls -A "$NEEDS_ATTN" 2>/dev/null)" ]; then
        notify-send -u low "Scratchpad Review ($SCRATCHPAD_NAME)" "No staged drafts to review. Skipping."
        exit 0
      fi

      # Build context: list all staged items
      STAGED_ITEMS=$(find "$NEEDS_ATTN" -mindepth 1 -maxdepth 1 -type d | sort)
      ITEM_COUNT=$(echo "$STAGED_ITEMS" | wc -l)

      REVIEW_PROMPT="You're reviewing $ITEM_COUNT staged scratchpad draft(s) for the '$SCRATCHPAD_NAME' scratchpad that need your approval.

      Staged drafts are in \`$NEEDS_ATTN/\`. For each subdirectory, read its README.md and any draft files, then present the proposed action to the user.

      For each item, ask the user: **approve**, **modify**, or **abandon**.

      **On approval**:
      - For scheduled tasks: move the task file to \`$TASKS_DIR/pending/\`, walk through the /schedule permission interview (define allowedTools), and create the systemd timer+service
      - For one-off tasks: apply the drafted changes to their target locations
      - For todos: add the entry to \`$TODO_JSON_PATH\`
      - **Remove the \`[STAGED]\` item line AND its \`>\` annotation line(s)** from \`$SCRATCHPAD\`
      - Delete the staging subdirectory

      **On abandon/reject**:
      - **Remove the \`[STAGED]\` item line AND its \`>\` annotation line(s)** from \`$SCRATCHPAD\`
      - Delete the staging subdirectory

      **On modify**: discuss changes with the user, update the draft, then re-present for approval.

      After processing all items, clean up empty directories in \`$NEEDS_ATTN/\`.

      Let's start reviewing."

      claude --model "$CLAUDE_MODEL" "$REVIEW_PROMPT"
    '';
  };
in
symlinkJoin {
  name = "scratchpad-agent";
  paths = [
    precheck
    review
  ];

  meta = with lib; {
    description = "Standalone scratchpad triage precheck and interactive review binaries (parallel test of the scratchpad.nix home-manager module logic)";
    platforms = platforms.linux;
  };
}
