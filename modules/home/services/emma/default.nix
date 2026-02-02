# modules/home/services/emma/default.nix
#
# Emma email automation service - LLM-powered email processing
# Integrates with notmuch (from mail service) for email access
{
  lib,
  config,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.services.emma;
in
{
  options.${namespace}.services.emma = {
    enable = mkBoolOpt false "Enable Emma email automation service";

    service.enable = mkBoolOpt true "Enable Emma background service (systemd)";

    llm = {
      provider = mkOpt lib.types.str "ollama" "LLM provider (ollama or anthropic)";
      model = mkOpt lib.types.str "qwen3:14b" "Model name for the LLM provider";
      maxTokens = mkOpt lib.types.int 1024 "Maximum tokens for LLM responses";
      temperature = mkOpt lib.types.float 0.3 "Temperature for LLM responses";
      ollamaBaseUrl = mkOpt lib.types.str "http://localhost:11434" "Ollama API base URL";
      ollamaContextLength = mkOpt lib.types.int 24576 "Context length for Ollama models";
    };

    digest = {
      enable = mkBoolOpt true "Enable digest generation";
      schedule = mkOpt (lib.types.listOf lib.types.str) [ "08:00" "20:00" ] "Times to generate digests (24h format)";
      periodHours = mkOpt lib.types.int 12 "Hours of emails to include in each digest";
      minEmails = mkOpt lib.types.int 1 "Minimum emails required before generating a digest";
      includeActionItems = mkBoolOpt true "Include pending action items in digests";
      format = mkOpt lib.types.str "markdown" "Output format (markdown, html, text)";
    };

    monitor = {
      enable = mkBoolOpt true "Enable email monitoring";
      autoClassify = mkBoolOpt true "Automatically classify emails using LLM";
      applyRules = mkBoolOpt true "Apply automation rules to emails";
      extractActions = mkBoolOpt true "Extract action items from emails";
    };

    pollingInterval = mkOpt lib.types.int 300 "Polling interval in seconds";
    batchSize = mkOpt lib.types.int 50 "Emails to process per batch";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.emma = {
        enable = true;

        settings = {
          llm = {
            provider = cfg.llm.provider;
            model = cfg.llm.model;
            maxTokens = cfg.llm.maxTokens;
            temperature = cfg.llm.temperature;
            ollamaBaseUrl = cfg.llm.ollamaBaseUrl;
            ollamaContextLength = cfg.llm.ollamaContextLength;
          };

          batchSize = cfg.batchSize;
          pollingInterval = cfg.pollingInterval;
        };

        service = {
          enable = cfg.service.enable;
          pollingInterval = cfg.pollingInterval;

          monitor = {
            enable = cfg.monitor.enable;
            autoClassify = cfg.monitor.autoClassify;
            applyRules = cfg.monitor.applyRules;
            extractActions = cfg.monitor.extractActions;
          };

          digest = {
            enable = cfg.digest.enable;
            schedule = cfg.digest.schedule;
            periodHours = cfg.digest.periodHours;
            minEmails = cfg.digest.minEmails;
            includeActionItems = cfg.digest.includeActionItems;
            delivery = [
              {
                type = "file";
                format = cfg.digest.format;
              }
            ];
          };
        };
      };

      ${namespace}.preservation.directories = [
        ".config/emma"
        ".local/share/emma"
      ];
    }
  ]);
}
