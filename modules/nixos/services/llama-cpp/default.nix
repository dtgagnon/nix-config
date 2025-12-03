{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.llama-cpp;
in
{
  options.${namespace}.services.llama-cpp = {
    enable = mkBoolOpt false "Enable llama.cpp for local LLM serving with llama-swap";
    package = mkOpt types.package pkgs.llama-cpp "The default package to use for llama-cpp";
    host = mkOpt types.str "100.100.2.1" "Host address to bind the llama.cpp server";
    port = mkOpt types.int 11343 "Port for the llama.cpp server";
    modelsPath = mkOpt types.str "/persist/var/lib/llama-cpp/models" "Path to store GGUF models";
    swapThreshold = mkOpt types.float 0.8 "VRAM usage threshold (0.0-1.0) before swapping models";
    threads = mkOpt (types.nullOr types.int) null "Number of threads to use (null = auto-detect)";
    defaultContextSize = mkOpt types.int 16384 "Default context size for models";
  };

  config = mkIf cfg.enable {
    services.llama-cpp = {
      enable = true;
      host = "100.100.2.1";
      port = cfg.port;
      # extraFlags = [ ];
    };

    services.llama-swap = {
      enable = true;
      port = cfg.port + 1;
      # settings = { };
    };
  };
}
