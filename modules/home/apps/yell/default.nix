{ lib
, config
, inputs
, system
, namespace
, ...
}:
let
  inherit (lib) mkEnableOption mkIf getExe;
  cfg = config.${namespace}.apps.yell;
  yellPackage = inputs.yell.packages.${system}.default;
in
{
  options.${namespace}.apps.yell = {
    enable = mkEnableOption "Enable Yell transcription app";
  };

  config = mkIf cfg.enable {
    home.packages = [ yellPackage ];

    systemd.user.services.yell = {
      Unit = {
        Description = "Yell voice transcription daemon";
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${getExe yellPackage}";
        Restart = "on-failure";
        RestartSec = "5s";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    xdg.configFile."yell/config.toml".text = ''
      # Yell Daemon Configuration File
      # Copy this to ~/.config/yell/config.toml to customize settings

      [audio]
      # Audio input device name (or "default" for system default)
      input_device = "default"
      # "ptt" or "vad"
      input_mode = "ptt"
      # Target sample rate for processing (16kHz recommended)
      sample_rate = 16000
      # Clears buffer upon PTT tap when true
      clear_buffer_on_start = false
      # Dump audio to disk for debugging (debug_input.wav, debug_output.wav)
      # WARNING: Creates large files!
      dump_audio = false

      [vad]
      # Speech probability threshold (0.0-1.0)
      # Higher = less sensitive, fewer false positives
      # Lower = more sensitive, may trigger on background noise
      threshold = 0.5

      # Minimum silence duration in milliseconds before speech ends
      # Lower = faster response, may cut off slow speech
      # Higher = more tolerance for pauses
      min_silence_duration_ms = 500

      # Minimum speech duration in milliseconds to be valid
      # Filters out very short audio artifacts
      min_speech_duration_ms = 1000

      [transcription]
      # Model type (currently only "parakeet" supported)
      model = "parakeet"
      # Language code (currently only "en" supported)
      language = "en"
      # Transcription timeout in seconds
      timeout_s = 30

      [formatter]
      # Auto-capitalize first letter after punctuation (.!?\n)
      auto_capitalize = true
      # Add trailing space after injected text
      trailing_space = true

      [ipc]
      # Unix socket path
      # "auto" = use $XDG_RUNTIME_DIR/yell.sock (recommended)
      # Or specify absolute path like "/tmp/yell.sock"
      socket_path = "auto"

      [llm]
      # API Base URL (default: ollama local)
      # For OpenAI: https://api.openai.com/v1
      api_base = "http://localhost:11434/v1"

      # API Key (default: "ollama")
      # For OpenAI: sk-...
      api_key = "ollama"

      # Model name
      # For OpenAI: gpt-5-nano
      model = "gemma3:4b"

      # System Prompt
      system_prompt = "You are a semantic text router for a dictation app. Your job is to manage a text buffer based on user input. Output valid JSON only."


      [logging]
      # Log level: trace, debug, info, warn, error
      # - trace: Very verbose, all details
      # - debug: Detailed information for debugging
      # - info: General informational messages (recommended)
      # - warn: Warning messages
      # - error: Error messages only
      level = "info"

      # Log format: text or json
      # - text: Human-readable format (recommended for terminal)
      # - json: Machine-readable format (recommended for log aggregation)
      format = "text"
    '';
  };
}
