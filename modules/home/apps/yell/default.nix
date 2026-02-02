{ lib
, pkgs
, config
, inputs
, namespace
, ...
}:
let
  inherit (lib) mkEnableOption mkIf getExe;
  inherit (pkgs.stdenv.hostPlatform) system;
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
      # Use VAD Gate in PTT mode (true = silence is filtered out even when button held)
      vad_in_ptt = true

      [vad]
      # Speech probability threshold (0.0-1.0)
      # Higher = less sensitive, fewer false positives
      # Lower = more sensitive, may trigger on background noise
      threshold = 0.45

      # Minimum silence duration in milliseconds before speech ends
      # Lower = faster response, may cut off slow speech
      # Higher = more tolerance for pauses
      min_silence_duration_ms = 700

      # Minimum speech duration in milliseconds to be valid
      # Filters out very short audio artifacts
      min_speech_duration_ms = 500

      [transcription]
      # Model type (currently only "parakeet" supported)
      model = "parakeet"
      # Language code (currently only "en" supported)
      language = "en"
      # Transcription timeout in seconds
      timeout_sec = 30

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
      # --- Global LLM Settings ---
      # Custom Instructions (Define your preferences). These are appended to the system prompt.
      instructions = "Always use American English spelling. Be concise. Use markdown compliant formatting."

      # --- Multi-Model Architecture ---
      # The system relies on two stages:
      # 1. Router: Fast, zero-shot classification (Dictate vs Command vs Flush)
      # 2. Processor: Smart rewriting and formatting for commands

      [llm.router]
      # Provider: openai, anthropic, ollama, open-router, llama-cpp, google
      provider = "ollama"
      # Model: Should be small and fast (e.g., functiongemma, llama3.2:1b)
      model = "yell-functiongemma"
      api_base = "http://localhost:11434/v1"
      api_key = "ollama"

      [llm.processor]
      # Provider: Can be different from router (e.g., Anthropic for intelligence)
      provider = "ollama"
      # Model: Should be capable of following complex rewriting instructions
      model = "gemma3n:e4b"
      api_base = "http://localhost:11434/v1"
      api_key = "ollama"

      [logging]
      # Log level: trace, debug, info, warn, error
      # - trace: Very verbose, all details
      # - debug: Detailed information for debugging
      # - info: General informational messages (recommended)
      # - warn: Warning messages
      # - error: Error messages only
      level = "debug"

      # Log format: text or json
      # - text: Human-readable format (recommended for terminal)
      # - json: Machine-readable format (recommended for log aggregation)
      format = "text"
    '';
  };
}
