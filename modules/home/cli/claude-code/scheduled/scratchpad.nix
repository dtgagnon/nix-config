{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    types
    filterAttrs
    mapAttrs
    mapAttrsToList
    concatMapStringsSep
    concatStringsSep
    optionalString
    ;
  inherit (lib.${namespace}) mkBoolOpt;

  servicePath = lib.makeBinPath [
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.findutils
  ];

  mkScratchpadInstance =
    tasksDir: name: inst:
    let
      scratchpadPath = "${tasksDir}/scratchpads/${name}-scratchpad.md";
      todoJsonPath = "${tasksDir}/todos/${name}-todos.json";
      needsAttnDir = "${tasksDir}/needs-attention/scratchpad-${name}";
      agentTaskName = "scratchpad-agent-${name}";
      reviewTaskName = "scratchpad-review-${name}";
      allTags = lib.unique (inst.tags ++ [ name ]);
      tagsYaml = "[${concatStringsSep ", " allTags}]";

      allowedToolsList = [
        ''"Read(${inst.targetDir}/*)"''
      ]
      ++ map (f: ''"Read(${inst.targetDir}/${f})"'') inst.contextFiles
      ++ [
        ''"Read(${tasksDir}/pending/*)"''
        ''"Read(${tasksDir}/needs-attention/*)"''
        ''"Edit(${scratchpadPath})"''
        ''"Write(${tasksDir}/needs-attention/*)"''
        ''"Bash(mkdir -p:${needsAttnDir}/*)"''
        ''"Bash(cp:${inst.targetDir}/* ${needsAttnDir}/*)"''
        ''"Bash(date:*)"''
        ''"Bash(ls:${tasksDir}/pending/*)"''
        ''"Grep"''
      ];
      allowedToolsYaml = concatMapStringsSep "\n" (t: "      - ${t}") allowedToolsList;

      contextListStr = optionalString (inst.contextFiles != [ ]) (
        ", " + concatStringsSep ", " inst.contextFiles
      );

      precheck = pkgs.writeShellScript "${agentTaskName}-precheck" ''
        set -euo pipefail

        SCRATCHPAD="${scratchpadPath}"

        # Check for item lines above --- that are NOT already [STAGED]
        NEW_ITEMS=$(${pkgs.gnused}/bin/sed '/^---$/,$d' "$SCRATCHPAD" \
          | ${pkgs.gnugrep}/bin/grep -E '^- ' \
          | ${pkgs.gnugrep}/bin/grep -v '^\- \[STAGED\]' \
          || true)

        if [ -z "$NEW_ITEMS" ]; then
          echo "No un-staged items in scratchpad (${name}). Skipping."
          exit 0
        fi

        # Has new items — invoke the task-runner
        exec ${tasksDir}/task-runner \
          ${tasksDir}/pending/${agentTaskName}.md \
          ${agentTaskName}
      '';

      reviewWrapper = pkgs.writeShellScript "${reviewTaskName}-wrapper" ''
        set -euo pipefail

        NEEDS_ATTN="${needsAttnDir}"
        SCRATCHPAD="${scratchpadPath}"

        # Skip if nothing staged
        if [ ! -d "$NEEDS_ATTN" ] || [ -z "$(${pkgs.coreutils}/bin/ls -A "$NEEDS_ATTN" 2>/dev/null)" ]; then
          ${pkgs.libnotify}/bin/notify-send -u low "Scratchpad Review (${name})" "No staged drafts to review. Skipping."
          exit 0
        fi

        # Build context: list all staged items
        STAGED_ITEMS=$(${pkgs.findutils}/bin/find "$NEEDS_ATTN" -mindepth 1 -maxdepth 1 -type d | ${pkgs.coreutils}/bin/sort)
        ITEM_COUNT=$(echo "$STAGED_ITEMS" | ${pkgs.coreutils}/bin/wc -l)

        REVIEW_PROMPT="You're reviewing $ITEM_COUNT staged scratchpad draft(s) for the '${name}' scratchpad that need your approval.

        Staged drafts are in \`$NEEDS_ATTN/\`. For each subdirectory, read its README.md and any draft files, then present the proposed action to the user.

        For each item, ask the user: **approve**, **modify**, or **abandon**.

        **On approval**:
        - For scheduled tasks: move the task file to \`${tasksDir}/pending/\`, walk through the /schedule permission interview (define allowedTools), and create the systemd timer+service
        - For one-off tasks: apply the drafted changes to their target locations
        - For todos: add the entry to \`${todoJsonPath}\`
        - **Remove the \`[STAGED]\` item line AND its \`>\` annotation line(s)** from \`$SCRATCHPAD\`
        - Delete the staging subdirectory

        **On abandon/reject**:
        - **Remove the \`[STAGED]\` item line AND its \`>\` annotation line(s)** from \`$SCRATCHPAD\`
        - Delete the staging subdirectory

        **On modify**: discuss changes with the user, update the draft, then re-present for approval.

        After processing all items, clean up empty directories in \`$NEEDS_ATTN/\`.

        Let's start reviewing."

        claude --model "${inst.model}" "$REVIEW_PROMPT"
      '';

      agentTask = pkgs.writeText "${agentTaskName}.md" ''
        ---
        summary: Triage and annotate ${name} scratchpad items
        schedule: "${inst.agentSchedule}"
        recurring: true
        model: ${inst.model}
        tags: ${tagsYaml}
        allowedTools:
        ${allowedToolsYaml}
        ---

        # Scratchpad Triage (${name})

        ## Context
        The ${name} scratchpad at `${scratchpadPath}` is a quick-capture
        inbox for ideas and action items. This task triages unprocessed items
        and stages draft actions for human review.

        ## Steps

        1. **Read context**: Read scratchpad.md, todo.json${contextListStr}, and list existing
           pending scheduled tasks. Understand current state and what's already
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

           b. **Stage draft work** into `${needsAttnDir}/<date>_<slug>/`:
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
        - Each staged item has a corresponding directory in `${needsAttnDir}/`
        - No original files were modified (only scratchpad.md and needs-attention/ contents)
      '';

      reviewTask = pkgs.writeText "${reviewTaskName}.md" ''
        ---
        summary: Interactive review of staged ${name} scratchpad drafts
        schedule: "${inst.reviewSchedule}"
        recurring: true
        model: ${inst.model}
        tags: ${tagsYaml}
        allowedTools:
          - "Bash(${lib.getExe inst.terminal} -e:${reviewWrapper})"
        ---

        # Scratchpad Review (${name})

        ## Context
        The scratchpad agent triages items and stages drafts into
        `${needsAttnDir}/`. This task opens an interactive terminal
        session so the user can review, approve, modify, or reject each staged draft.

        ## Steps
        1. Launch terminal with the review wrapper script
        2. The wrapper skips automatically if nothing is staged

        ## Success Criteria
        - Terminal opens with an interactive Claude session (or skips cleanly if empty)
      '';
    in
    {
      inherit
        precheck
        reviewWrapper
        agentTask
        reviewTask
        scratchpadPath
        todoJsonPath
        needsAttnDir
        agentTaskName
        reviewTaskName
        ;
    };
in
{
  options.${namespace}.cli.claude-code.scheduling.scratchpads = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          enable = mkBoolOpt true "Whether this scratchpad instance is active";

          targetDir = mkOption {
            type = types.str;
            description = "Working directory this scratchpad relates to (for context reads and symlink placement)";
          };

          contextFiles = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Relative paths within targetDir to grant additional Read access to (e.g., [\"Work/CLAUDE.md\"])";
          };

          agentSchedule = mkOption {
            type = types.str;
            default = "Mon..Fri *-*-* 08..21:00:00";
            description = "Systemd OnCalendar for the autonomous triage agent";
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

          tags = mkOption {
            type = types.listOf types.str;
            default = [
              "triage"
              "scratchpad"
            ];
            description = "Tags for the task file frontmatter (instance name is appended automatically)";
          };
        };
      }
    );
    default = { };
    description = "Per-directory scratchpad triage and review instances";
  };

  config =
    let
      cfg = config.${namespace}.cli.claude-code;
      tasksDir = cfg.scheduling.tasksDir;
      enabledScratchpads = filterAttrs (_: inst: inst.enable) cfg.scheduling.scratchpads;
      instances = mapAttrs (mkScratchpadInstance tasksDir) enabledScratchpads;
    in
    mkIf (cfg.enable && cfg.scheduling.enable && enabledScratchpads != { }) {
      home.activation.setupScratchpadAgents = lib.hm.dag.entryAfter [ "setupSchedulingDirs" ] ''
        ${concatStringsSep "\n" (
          mapAttrsToList (
            name: inst:
            let
              i = instances.${name};
            in
            ''
              run mkdir -p "${i.needsAttnDir}"
              if [ ! -f "${i.scratchpadPath}" ]; then
                run touch "${i.scratchpadPath}"
              fi
              if [ ! -f "${i.todoJsonPath}" ]; then
                run bash -c 'printf "[]" > "${i.todoJsonPath}"'
              fi
              run mkdir -p "${inst.targetDir}"
              run ln -sf "${i.scratchpadPath}" "${inst.targetDir}/${name}-scratchpad.md"
              run ln -sf "${i.todoJsonPath}" "${inst.targetDir}/${name}-todos.json"
              if [ ! -f "${tasksDir}/pending/${i.agentTaskName}.md" ]; then
                run cp "${i.agentTask}" "${tasksDir}/pending/${i.agentTaskName}.md"
              fi
              if [ ! -f "${tasksDir}/pending/${i.reviewTaskName}.md" ]; then
                run cp "${i.reviewTask}" "${tasksDir}/pending/${i.reviewTaskName}.md"
              fi
            ''
          ) enabledScratchpads
        )}
      '';

      systemd.user.services = lib.foldr lib.recursiveUpdate { } (
        mapAttrsToList (
          name: inst:
          let
            i = instances.${name};
          in
          {
            ${i.agentTaskName} = {
              Unit = {
                Description = "Scratchpad agent (${name}) — triage and annotate";
                After = [ "graphical-session.target" ];
              };
              Service = {
                Type = "oneshot";
                WorkingDirectory = builtins.replaceStrings [ "$HOME" ] [ "%h" ] tasksDir;
                ExecStart = "${i.precheck}";
                TimeoutStartSec = "10m";
                Environment = [
                  "PATH=${servicePath}:/run/current-system/sw/bin:%h/.nix-profile/bin"
                ];
              };
            };

            ${i.reviewTaskName} = {
              Unit = {
                Description = "Scratchpad review (${name}) — interactive draft review";
                After = [ "graphical-session.target" ];
              };
              Service = {
                Type = "oneshot";
                WorkingDirectory = builtins.replaceStrings [ "$HOME" ] [ "%h" ] tasksDir;
                ExecStart = "${lib.getExe inst.terminal} -e ${i.reviewWrapper}";
                TimeoutStartSec = "2h";
                Environment = [
                  "PATH=${servicePath}:/run/current-system/sw/bin:%h/.nix-profile/bin"
                ];
              };
            };
          }
        ) enabledScratchpads
      );

      systemd.user.timers = lib.foldr lib.recursiveUpdate { } (
        mapAttrsToList (
          name: inst:
          let
            i = instances.${name};
          in
          {
            ${i.agentTaskName} = {
              Unit.Description = "Timer for scratchpad agent (${name})";
              Timer = {
                OnCalendar = inst.agentSchedule;
                Persistent = true;
              };
              Install.WantedBy = [ "timers.target" ];
            };

            ${i.reviewTaskName} = {
              Unit.Description = "Timer for scratchpad review (${name})";
              Timer = {
                OnCalendar = inst.reviewSchedule;
                Persistent = true;
              };
              Install.WantedBy = [ "timers.target" ];
            };
          }
        ) enabledScratchpads
      );
    };
}
