{
  lib,
  pkgs,
  config,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.spirenix.desktop.hyprland;

  # Auto-fit scrolling layout columns when ≤ 4 on a workspace.
  # Explicitly sets all columns to 1/n width so they fill the screen evenly.
  # Beyond 4 columns, the default column_width (0.25) causes natural overflow/scrolling.
  scrollAutofitScript = pkgs.writeShellScriptBin "hypr-scroll-autofit" ''
    MAX_COLS=4
    JQ=${lib.getExe pkgs.jq}
    LOG=/tmp/hypr-scroll-autofit.log
    LAST_COUNT=""
    LAST_ADDR=""

    log() { echo "[$(date +%H:%M:%S.%3N)] $*" >> "$LOG"; }

    log "=== autofit script started ==="

    autofit() {
      local ws count
      ws=$(hyprctl activeworkspace -j | $JQ '.id')
      count=$(hyprctl clients -j | $JQ \
        "[.[] | select(.workspace.id == $ws and .floating == false and .mapped == true)] | [.[].at[0]] | unique | length")

      # Skip if column count hasn't changed
      if [ "$count" = "$LAST_COUNT" ]; then
        return
      fi
      LAST_COUNT="$count"

      log "ws=$ws cols=$count"

      if [ "$count" -ge 2 ] && [ "$count" -le 4 ]; then
        log "fitting all (count=$count)"; hyprctl dispatch layoutmsg "fit all"
      elif [ "$count" -gt 4 ]; then
        log "resizing all -> 0.25";  hyprctl dispatch layoutmsg "colresize all 0.25"
      else
        log "no resize (count=$count)"
      fi
    }

    ${lib.getExe pkgs.socat} -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while IFS= read -r line; do
      case "$line" in
        openwindow*|closewindow*|movewindow*|changefloatingmode*|workspace'>>'*)
          log "event: $line"
          sleep 0.15
          autofit
          ;;
        activewindowv2'>>'*)
          # Only run autofit when the focused window actually changes (not title updates).
          # activewindowv2 format: activewindowv2>>ADDR
          addr="''${line#*>>}"
          if [ "$addr" != "$LAST_ADDR" ]; then
            LAST_ADDR="$addr"
            autofit
          fi
          ;;
      esac
    done
  '';
in
{
  config = mkIf cfg.enable {
    spirenix.desktop.hyprland.extraSettings = {
      exec-once =
        let
          execCmds = (
            [
              "gnome-keyring-daemon --start --components=secrets"
              # "blueman-applet"
              "playerctld daemon"
              "solaar --window hide --battery-icons regular"
            ]
            ++ lib.optional (cfg.layout == "scrolling") (lib.getExe scrollAutofitScript)
            ++ cfg.extraExec
          );
          # Add monitor init when PiP is enabled
          pipExecCmds =
            if osConfig.spirenix.hardware.monitors.pip.enable or false then
              execCmds ++ [ "hypr-monitor-init" ]
            else
              execCmds;
        in
        if (osConfig.programs.hyprland.withUWSM or false) then
          map (c: "uwsm app -- ${c}") pipExecCmds
        else
          pipExecCmds;

      monitor = cfg.monitors ++ [
        # "Virtual-1,7680x2160,0x0,1"
        ",preferred,auto,1"
        #TODO: Figure out if this should be used or not `",preferred,auto,1"`
      ];

      general = {
        gaps_in = 3;
        gaps_out = 5;
        border_size = 3;
        layout = cfg.layout;
      };

      decoration = {
        rounding = 8;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        blur = {
          enabled = true;
          ignore_opacity = false;
          passes = 2;
          popups = true;
          size = 5;
          special = true;
        };
        shadow = {
          range = 30;
          render_power = 3;
        };
      };

      animations = {
        # bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        bezier = "myBezier, 0.3, 0, 0, 1";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 5, myBezier"
          "workspaces, 1, 6, myBezier, slidevert"
          "specialWorkspace, 1, 6, default, fade"
        ];
      };

      binds.allow_workspace_cycles = true;

      input = {
        # keyboard
        kb_layout = "us";
        repeat_delay = 200;
        repeat_rate = 100;
        # mouse
        accel_profile = "flat";
        follow_mouse = 1;
        sensitivity = 0;
        # misc
        touchpad.disable_while_typing = true;
      };

      misc = {
        #TODO: new_window_takes_over_fullscreen = 2; # Deprecated by PR #12033 (Nov 2025). Replacement is 'misc:on_focus_under_fullscreen'
        initial_workspace_tracking = 0;
        disable_hyprland_logo = true;
        disable_autoreload = true;
      };

      debug = {
        # Keep stdout/stderr logs enabled so short startup banners and warnings are retained
        disable_logs = false;
      };

      master = {
        new_on_top = true;
        new_status = "master";
        mfact = 0.55;
        special_scale_factor = 1;
      };

      dwindle = {
        pseudotile = "yes";
        preserve_split = "yes";
        special_scale_factor = 1;
      };

      scrolling = mkIf (cfg.layout == "scrolling") {
        fullscreen_on_one_column = 1;
        column_width = 0.25;
        focus_fit_method = 1;
        follow_focus = 1;
        follow_min_visible = 0.4;
        explicit_column_widths = " 0.25, 0.333, 0.5, 0.667, 0.75, 1.0";
        direction = "right";
      };
    };
  };
}
