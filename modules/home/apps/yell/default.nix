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
    services.yell = {
      enable = true;
      settings = {
        audio = {
          input_mode = "ptt";
          vad_in_ptt = true;
          auto_inject = true;
          auto_inject_silence_ms = 3000;
          min_snr = -10.0;
        };
        vad = {
          threshold = 0.5;
          min_silence_duration_ms = 300;
          min_speech_duration_ms = 200;
        };
        transcription = {
          model = "parakeet";
          timeout_secs = 30;
        };
        formatter = {
          auto_capitalize = true;
          trailing_space = true;
        };
        llm = {
          router = {
            provider = "ollama";
            model = "yell-functiongemma";
          };
          processor = {
            provider = "ollama";
            model = "gemma3n:e4b";
          };
        };
      };
    };

    # systemd.user.services.yell = {
    #   Unit = {
    #     Description = "Yell voice transcription daemon";
    #     After = [ "graphical-session.target" ];
    #     BindsTo = [ "graphical-session.target" ];
    #   };
    #
    #   Service = {
    #     Type = "simple";
    #     ExecStart = "${getExe yellPackage}";
    #     Restart = "on-failure";
    #     RestartSec = "5s";
    #   };
    #
    #   Install = {
    #     WantedBy = [ "graphical-session.target" ];
    #   };
    # };

    # xdg.configFile."yell/config.toml".text = ''
    #   [audio]
    #   # input_device (string) - audio input device name
    #   # input_mode (string enum: ptt, vad) - input capture mode
    #   # vad_in_ptt (bool) - filter silence in PTT mode
    #   # auto_inject (bool) - inject after silence in PTT; requires vad_in_ptt
    #   # auto_inject_silence_ms (int) - silence threshold before auto-inject
    #   # sample_rate (int) - processing sample rate in Hz
    #   # clear_buffer_on_start (bool) - clear buffer on PTT tap
    #   # dump_audio (bool) - write debug WAV files to disk
    #   input_device = "default"
    #   input_mode = "ptt"
    #   vad_in_ptt = true
    #   auto_inject = true
    #   auto_inject_silence_ms = 3000
    #   sample_rate = 16000
    #   clear_buffer_on_start = false
    #   dump_audio = false
    #
    #   [vad]
    #   # threshold (float 0.0-1.0) - speech detection sensitivity
    #   # min_silence_duration_ms (int) - silence before speech ends
    #   # min_speech_duration_ms (int) - minimum valid speech length
    #   threshold = 0.45
    #   min_silence_duration_ms = 700
    #   min_speech_duration_ms = 500
    #
    #   [transcription]
    #   # model (string) - transcription engine
    #   # language (string) - language code
    #   # timeout_sec (int) - max transcription time
    #   model = "parakeet"
    #   language = "en"
    #   timeout_sec = 30
    #
    #   [formatter]
    #   # auto_capitalize (bool) - capitalize after sentence punctuation
    #   # trailing_space (bool) - append space after injected text
    #   auto_capitalize = true
    #   trailing_space = true
    #
    #   [ipc]
    #   # socket_path (string) - "auto" or absolute path to unix socket
    #   socket_path = "auto"
    #
    #   [llm]
    #   # instructions (string) - appended to system prompt
    #   instructions = "Always use American English spelling. Be concise. Use markdown compliant formatting."
    #
    #   [llm.router]
    #   # Fast classifier: Dictate vs Command vs Flush
    #   # provider (string enum: openai, anthropic, ollama, open-router, llama-cpp, google) - LLM provider
    #   # model (string) - small/fast model name
    #   # api_base (string) - provider API endpoint
    #   # api_key (string) - provider API key
    #   provider = "ollama"
    #   model = "yell-functiongemma"
    #   api_base = "http://localhost:11434/v1"
    #   api_key = "ollama"
    #
    #   [llm.processor]
    #   # Rewriter for command output formatting
    #   # provider (string enum: openai, anthropic, ollama, open-router, llama-cpp, google) - LLM provider
    #   # model (string) - capable model for complex instructions
    #   # api_base (string) - provider API endpoint
    #   # api_key (string) - provider API key
    #   provider = "ollama"
    #   model = "gemma3n:e4b"
    #   api_base = "http://localhost:11434/v1"
    #   api_key = "ollama"
    #
    #   [logging]
    #   # level (string enum: trace, debug, info, warn, error) - log verbosity
    #   # format (string enum: text, json) - log output format
    #   level = "debug"
    #   format = "text"
    # '';
  };
}
