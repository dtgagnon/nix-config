{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    types
    getExe
    ;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.audio-record;

  recordScript = pkgs.writeShellScriptBin "audio-record-toggle" ''
    set -euo pipefail

    RECORD_DIR="${cfg.outputDir}"
    PID_FILE="''${XDG_RUNTIME_DIR:-/tmp}/audio-record.pid"
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    OUTPUT_FILE="$RECORD_DIR/recording-$TIMESTAMP.${cfg.format}"

    # Build ffmpeg input arguments based on configuration
    INPUTS=""
    FILTER=""
    INPUT_COUNT=0

    ${
      if cfg.captureSystemAudio then
        ''
          INPUTS="$INPUTS -f pulse -i default.monitor"
          INPUT_COUNT=$((INPUT_COUNT + 1))
        ''
      else
        ""
    }

    ${
      if cfg.captureMicrophone then
        ''
          INPUTS="$INPUTS -f pulse -i default"
          INPUT_COUNT=$((INPUT_COUNT + 1))
        ''
      else
        ""
    }

    if [[ $INPUT_COUNT -eq 0 ]]; then
      ${
        if cfg.notifications then
          ''${getExe pkgs.libnotify} "Audio Record" "Error: No audio sources configured" -u critical''
        else
          ""
      }
      exit 1
    elif [[ $INPUT_COUNT -eq 2 ]]; then
      FILTER="-filter_complex [0:a][1:a]amix=inputs=2:duration=longest"
    fi

    # Determine encoder based on format
    case "${cfg.format}" in
      opus)
        ENCODER="-c:a libopus -b:a ${cfg.bitrate}"
        ;;
      mp3)
        ENCODER="-c:a libmp3lame -b:a ${cfg.bitrate}"
        ;;
      flac)
        ENCODER="-c:a flac"
        ;;
      *)
        ENCODER="-c:a libopus -b:a ${cfg.bitrate}"
        ;;
    esac

    # Check if already recording
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      # Stop recording
      PID=$(cat "$PID_FILE")
      kill -INT "$PID" 2>/dev/null || true
      rm -f "$PID_FILE"

      # Find the most recent recording file
      LAST_FILE=$(ls -t "$RECORD_DIR"/recording-*.${cfg.format} 2>/dev/null | head -1)
      ${
        if cfg.notifications then
          ''${getExe pkgs.libnotify} "Recording Stopped" "Saved: ''${LAST_FILE##*/}" -i audio-x-generic''
        else
          ""
      }
    else
      # Start recording
      mkdir -p "$RECORD_DIR"

      # shellcheck disable=SC2086
      ${getExe pkgs.ffmpeg} -y $INPUTS $FILTER $ENCODER "$OUTPUT_FILE" </dev/null &>/dev/null &
      echo $! > "$PID_FILE"

      ${
        if cfg.notifications then
          ''${getExe pkgs.libnotify} "Recording Started" "Capturing audio to $RECORD_DIR" -i audio-input-microphone''
        else
          ""
      }
    fi
  '';
in
{
  options.${namespace}.services.audio-record = {
    enable = mkEnableOption "Audio recording toggle for capturing mic and system audio";

    outputDir = mkOpt types.str "\${HOME}/Recordings" "Directory to save recordings";

    format = mkOpt (types.enum [
      "opus"
      "mp3"
      "flac"
    ]) "opus" "Output audio format";

    bitrate = mkOpt types.str "96k" "Audio bitrate for lossy formats (opus, mp3)";

    keybind =
      mkOpt (types.nullOr types.str) "$mod_SHIFT, R"
        "Hyprland keybind for toggle recording (null to disable)";

    captureSystemAudio = mkBoolOpt true "Capture system audio output (what you hear)";

    captureMicrophone = mkBoolOpt true "Capture microphone input (what you say)";

    notifications = mkBoolOpt true "Show desktop notifications on start/stop";
  };

  config = mkIf cfg.enable {
    home.packages = [ recordScript ];

    # Add Hyprland keybind if configured and hyprland is enabled
    spirenix.desktop.hyprland.extraKeybinds.bind =
      lib.mkIf (cfg.keybind != null && config.${namespace}.desktop.hyprland.enable)
        [
          "${cfg.keybind}, exec, ${getExe recordScript}"
        ];
  };
}
