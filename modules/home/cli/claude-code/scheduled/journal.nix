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
  journal = cfg.scheduling.journal;

  tasksDir = cfg.scheduling.tasksDir;

  # Task file for /schedule list visibility and documentation
  journal-checkin-task = pkgs.writeText "workday-checkin.md" ''
    ---
    summary: Workday check-in popup — asks what you're working on, summarizes to daily note
    schedule: "${journal.schedule}"
    recurring: true
    model: ${journal.model}
    ${lib.optionalString (journal.until != null) "until: \"${journal.until}\""}
    tags: [productivity, check-in, journal]
    allowedTools:
      - "Bash(${lib.getExe journal.terminal} -e:${journal-checkin})"
    ---

    # Workday Check-In

    ## Context
    An interactive Claude Code session that pops up in a Ghostty terminal during the
    workday to check in on progress, offer help, and keep momentum going. After the
    conversation ends, the session is summarized and logged to the Obsidian daily note.

    ## Flow

    ### First check-in of the day (no daily note exists yet)
    1. Claude prompts user for **On My Mind** and **Intentions**
    2. User chats naturally about their morning headspace and plans
    3. Session ends — Sonnet populates On My Mind + Intentions; Experiences/Grateful left as placeholders
    4. Daily note is created with frontmatter + populated content

    ### Midday follow-up check-ins (daily note exists)
    1. Claude opens with the daily note content and asks about progress
    2. User chats, then closes the session
    3. Sonnet generates a 2-5 bullet summary appended under `## Check-in (HH:MM)`

    ### Last check-in of the day (daily note exists, lastCheckInHour)
    1. Claude prompts for progress AND **Experiences** and **Grateful for**
    2. User reflects on the day, then closes the session
    3. Check-in summary appended; Experiences/Grateful sections populated

    ## Success Criteria
    - Ghostty terminal opens with an interactive Claude session
    - Daily note is created or updated appropriately for the check-in mode
  '';

  journal-checkin = pkgs.writeShellScript "journal-checkin" ''
set -euo pipefail

VAULT_DIR="${journal.vaultDir}"
DAILY_NOTES_DIR="$VAULT_DIR/Daily Notes"

# --- Expiry check (conditional on until date) ---
UNTIL_DATE="${if journal.until != null then journal.until else ""}"
if [ -n "$UNTIL_DATE" ]; then
  CURRENT_EPOCH=$(${pkgs.coreutils}/bin/date +%s)
  UNTIL_EPOCH=$(${pkgs.coreutils}/bin/date -d "$UNTIL_DATE" +%s 2>/dev/null || echo 0)
  if [ "$CURRENT_EPOCH" -ge "$UNTIL_EPOCH" ]; then
    ${pkgs.libnotify}/bin/notify-send -u normal "Workday Check-in" \
      "Check-in schedule expired (until: $UNTIL_DATE). Disable via nix config."
    exit 0
  fi
fi

# --- Resolve today's daily note path ---
DATE_PREFIX=$(${pkgs.coreutils}/bin/date +%Y%m%d)
DATE_HUMAN=$(${pkgs.coreutils}/bin/date +'%B %-d, %Y')
DATE_FILE="''${DATE_PREFIX}-''${DATE_HUMAN}.md"
DAILY_NOTE="$DAILY_NOTES_DIR/$DATE_FILE"

# Ordinal suffix for frontmatter dates
DAY_NUM=$(${pkgs.coreutils}/bin/date +'%-d')
case $DAY_NUM in
  1|21|31) SUFFIX="st";;
  2|22)    SUFFIX="nd";;
  3|23)    SUFFIX="rd";;
  *)       SUFFIX="th";;
esac
DATE_FANCY="$(${pkgs.coreutils}/bin/date +'%A, %B %-d')''${SUFFIX}$(${pkgs.coreutils}/bin/date +' %Y, %H:%M:%S')"
PREV_YEAR_LINK=$(${pkgs.coreutils}/bin/date -d '-1 year' +'%B %-d, %Y')

# --- Create marker for session identification ---
MARKER=$(${pkgs.coreutils}/bin/mktemp)

# --- Determine check-in mode ---
# Modes: first (no daily note yet), last (lastCheckInHour), midday (everything else)
CURRENT_HOUR=$(${pkgs.coreutils}/bin/date +%H)
IS_FIRST_CHECKIN=true
IS_LAST_CHECKIN=false
DAILY_CONTEXT=""

if [ -f "$DAILY_NOTE" ]; then
  IS_FIRST_CHECKIN=false
  DAILY_CONTEXT=$(${pkgs.coreutils}/bin/cat "$DAILY_NOTE")
fi

if [ "$CURRENT_HOUR" = "${journal.lastCheckInHour}" ] && [ "$IS_FIRST_CHECKIN" = false ]; then
  IS_LAST_CHECKIN=true
fi

# --- Build check-in prompt ---
if [ "$IS_FIRST_CHECKIN" = true ]; then
  CHECKIN_PROMPT="Hey! This is your first workday check-in of the day, and there's no daily note yet. Let's set up your day!

I'd like to help you fill out your daily note. Let's chat through these — just talk naturally:

1. **What's on your mind** right now? Anything weighing on you or top-of-mind?
2. **What are your intentions** for today — what do you want to accomplish or focus on?

After we chat, I'll capture everything into your daily note automatically. So just talk freely!"
elif [ "$IS_LAST_CHECKIN" = true ]; then
  CHECKIN_PROMPT="Hey! This is your last check-in for the day. Let's wrap things up.

Here's what's in your daily note so far today:

---
$DAILY_CONTEXT
---

Two things I'd like to cover:

1. **How did your day go?** Progress, wins, blockers — anything you want to note from this last stretch.
2. **Let's fill in the rest of your daily note:**
   - **Experiences** — What stood out today? Any moments, interactions, or things worth remembering?
   - **Grateful for** — What are you grateful for today?

Take your time, just talk naturally and I'll capture it all."
else
  CHECKIN_PROMPT="Hey! This is your scheduled workday check-in.

Here's what's in your daily note so far today:

---
$DAILY_CONTEXT
---

Based on what you've noted and any earlier check-ins above, how's everything going? Making progress? Hit any walls or have anything you want to talk through?"
fi

# --- Run interactive claude session ---
claude --model "${journal.model}" "$CHECKIN_PROMPT"

# --- Post-session: find and summarize ---
${pkgs.coreutils}/bin/sleep 1

# Find the session JSONL created during this check-in (newest file newer than marker)
LATEST_SESSION=$(${pkgs.findutils}/bin/find "$HOME/.claude/projects/" \
  -name "*.jsonl" \
  -newer "$MARKER" \
  ! -path "*/subagents/*" \
  -type f \
  -printf '%T@ %p\n' 2>/dev/null \
  | ${pkgs.coreutils}/bin/sort -rn \
  | ${pkgs.coreutils}/bin/head -1 \
  | ${pkgs.coreutils}/bin/cut -d' ' -f2-)
${pkgs.coreutils}/bin/rm -f "$MARKER"

if [ -z "$LATEST_SESSION" ]; then
  echo "No session found to summarize."
  exit 0
fi

SESSION_ID=$(${pkgs.coreutils}/bin/basename "$LATEST_SESSION" .jsonl)
echo "Found session: ''${SESSION_ID:0:8}"
echo "Generating summary..."

# Extract user and assistant message lines (JSONL types "user" and "A")
MESSAGES=$(${pkgs.gnugrep}/bin/grep -E '"type"\s*:\s*"(user|A)"' "$LATEST_SESSION" 2>/dev/null | ${pkgs.coreutils}/bin/head -50 || echo "")

if [ -z "$MESSAGES" ]; then
  echo "No conversation messages found."
  exit 0
fi

TIME_NOW=$(${pkgs.coreutils}/bin/date +%H:%M)

# --- Summarize and write to daily note ---
if [ "$IS_FIRST_CHECKIN" = true ]; then
  # First check-in: populate On My Mind + Intentions only; leave Experiences/Grateful as placeholders
  NOTE_BODY=$(claude -p --model "${journal.model}" <<PROMPT
You are populating an Obsidian daily note from a morning check-in conversation.

Extract from the conversation:
- What's on the user's mind → "On My Mind" section (a short paragraph or a few sentences)
- Their intentions/plans → "Intentions" section (as bullet points)

The "Experiences" and "Grateful for" sections should be left as "…" — these will be filled in at the end-of-day check-in.

Then write a "## Check-in ($TIME_NOW)" section with 2-4 bullet points summarizing the conversation. Include a note that the daily note template was populated from this check-in.

Output ONLY the note body below — no YAML frontmatter, no code fences, no preamble.
Use this exact structure:

On this day: [[$PREV_YEAR_LINK]]

# On My Mind

<extracted content>

# Intentions

<extracted bullet points>

# Experiences

…

# Grateful for

…

## Check-in ($TIME_NOW)

<bullet summary>
- *(Daily note template populated from this check-in)*

---

Session ID: ''${SESSION_ID:0:8}

Conversation data (JSONL format):
$MESSAGES
PROMPT
  )

  # Create the daily note with frontmatter + populated body
  ${pkgs.coreutils}/bin/cat > "$DAILY_NOTE" <<EOF
---
title: $DATE_HUMAN
date_created: $DATE_FANCY
date_modified: $DATE_FANCY
tags:
  - daily
---
$NOTE_BODY
EOF

  echo "Daily note created and populated: $DAILY_NOTE"

elif [ "$IS_LAST_CHECKIN" = true ]; then
  # Last check-in: produce the complete updated daily note
  UPDATED_NOTE=$(claude -p --model "${journal.model}" <<PROMPT
You are processing the end-of-day check-in conversation for an Obsidian daily note.

Here is the current daily note:

---
$DAILY_CONTEXT
---

Do the following:

1. **Check-in summary**: Write a "## Check-in ($TIME_NOW)" section with 2-5 bullet points covering what the user worked on, progress, wins, blockers. Append it after all existing check-in sections at the end of the note.

2. **Experiences section**: Extract any experiences, notable moments, or interactions the user mentioned. If the "# Experiences" section currently contains only "…", replace it with the extracted bullet points. If it already has content, append the new bullet points below the existing ones.

3. **Grateful for section**: Extract what the user expressed gratitude for. Same logic — replace "…" if that's all that's there, otherwise append below existing content.

If the user didn't discuss one of these topics, leave that section unchanged.

Output the COMPLETE updated daily note — including the YAML frontmatter and ALL existing content. Do not omit, summarize, or rewrite any existing sections. Only modify Experiences, Grateful for, and append the new check-in section.

Output ONLY the note content — no code fences, no preamble, no commentary.

---

Session ID: ''${SESSION_ID:0:8}

Conversation data (JSONL format):
$MESSAGES
PROMPT
  )

  printf '%s\n' "$UPDATED_NOTE" > "$DAILY_NOTE"

  echo "End-of-day check-in: daily note updated with Experiences/Grateful and check-in summary: $DAILY_NOTE"

else
  # Midday follow-up check-in: append summary to existing note
  SUMMARY=$(claude -p --model "${journal.model}" <<PROMPT
Summarize this workday check-in conversation concisely for an Obsidian daily note.
Format as 2-5 markdown bullet points covering: what the user was working on, progress made, and any blockers or wins mentioned.
Output ONLY the bullet points — no headers, no YAML, no preamble, no extra commentary.

Session ID: ''${SESSION_ID:0:8}

Conversation data (JSONL format):
$MESSAGES
PROMPT
  )

  printf '\n## Check-in (%s)\n\n%s\n' "$TIME_NOW" "$SUMMARY" >> "$DAILY_NOTE"
  echo "Check-in summary appended: $DAILY_NOTE"
fi
  '';
in
{
  options.${namespace}.cli.claude-code.scheduling.journal = {
    enable = mkBoolOpt false "Enable the smart journal workday check-in system";

    vaultDir = mkOption {
      type = types.str;
      default = "$HOME/Apps/Obsidian/dereks-head";
      description = "Obsidian vault root directory";
    };

    schedule = mkOption {
      type = types.str;
      default = "Mon..Fri *-*-* 09,11,13,15,17:00:00";
      description = "Systemd OnCalendar expression for check-in schedule";
    };

    lastCheckInHour = mkOption {
      type = types.str;
      default = "17";
      description = "Hour (24h format) that triggers end-of-day mode";
    };

    model = mkOption {
      type = types.str;
      default = "sonnet";
      description = "Claude model for interactive sessions and summarization";
    };

    until = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional expiry date (YYYY-MM-DD); null means indefinite";
    };

    terminal = mkOption {
      type = types.package;
      default = pkgs.ghostty;
      description = "Terminal emulator package for interactive sessions";
    };
  };

  config = mkIf (cfg.enable && cfg.scheduling.enable && journal.enable) {
    # Seed task file to pending/ (only if not already present, to preserve execution logs)
    home.activation.setupJournalCheckin = lib.hm.dag.entryAfter [ "setupSchedulingDirs" ] ''
      if [ ! -f "${tasksDir}/pending/workday-checkin.md" ]; then
        run cp "${journal-checkin-task}" "${tasksDir}/pending/workday-checkin.md"
      fi
    '';

    systemd.user.services.journal-checkin = {
      Unit = {
        Description = "Smart Journal workday check-in session";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        WorkingDirectory = builtins.replaceStrings [ "$HOME" ] [ "%h" ] cfg.scheduling.tasksDir;
        ExecStart = "${lib.getExe journal.terminal} -e ${journal-checkin}";
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

    systemd.user.timers.journal-checkin = {
      Unit.Description = "Timer for smart journal workday check-in";
      Timer = {
        OnCalendar = journal.schedule;
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
