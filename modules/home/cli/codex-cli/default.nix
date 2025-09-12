{ lib
, pkgs
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

      # written to config.toml
      # settings = {
      #   projects = {
      #     "/home/dtgagnon/nix-config/nixos" = { "trust_level" = "trusted"; };
      #     "/hom"
      #   };
      #   tools."web_search" = true;
      #   mcp_servers = {
      #     nixos = {
      #       command = "nix";
      #       args = [ "run" "github:utensils/mcp-nixos" "--" ];
      #     };
      #     ref = {
      #       command = "npx";
      #       args = [ "-y" "ref-tools-mcp@latest" ];
      #       env = {
      #         "API_KEY" = "value";
      #       };
      #     };
      #   };
      #
      #   profile = {
      #     default = {
      #       # model = "gpt-5";
      #       # model_provider = "openai";
      #       # baseURL = "";
      #       # envKey = "";
      #
      #     };
      #     local = {
      #       model = "gpt-oss:20b";
      #       model_provider = "ollama";
      #       model_providers = {
      #         ollama = {
      #           name = "Ollama";
      #           baseURL = "http://127.0.0.1:11434/v1";
      #         };
      #       };
      #     };
      #   };
      # };

      # define global AGENTS.md
      # custom-instructions = ''
      #
      # '';
    };

    home = {
      packages = with pkgs; [
        nodejs # For mcp servers that rely on npx
      ];
      sessionVariables = {
        "CODEX_HOME" = lib.mkForce "~/.config/.codex";
      };
    };
  };
}
