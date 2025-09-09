{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.cli.codex;
in
{
  options.${namespace}.cli.codex = {
    enable = mkEnableOption "Enable codex";
  };

  config = mkIf cfg.enable {
    programs.codex = {
      enable = true;

      # # written to config.toml
      # settings = {
      #   model = "";
      #   model_provider = "";
      #   baseURL = "";
      #   envKey = "";
      # };
      #
      # # define global AGENTS.md
      # custom-instructions = ''
      #
      # '';
    };
  };
}
