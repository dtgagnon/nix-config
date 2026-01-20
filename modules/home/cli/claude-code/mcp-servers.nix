{
  lib,
  config,
  namespace,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.${namespace}.cli.claude-code;
in
{
  config = mkIf cfg.enable {
    # Declare secrets in home-manager sops (userspace only)
    sops.secrets = {
      n8n_access_token = { };
      ref_api = { };
      github_read_token = { };
      mxroute-env = { };
    };

    programs.claude-code.mcpServers = mkMerge [
      {
        nixos = {
          type = "stdio";
          command = "nix";
          args = [
            "run"
            "github:utensils/mcp-nixos"
            "--"
          ];
        };
        mxroute = {
          type = "stdio";
          command = "nix";
          args = [
            "run"
            "github:dtgagnon/nix-config#mcp-mxroute"
            "--"
          ];
        };
        ref = {
          type = "http";
          # Claude Code will expand ${REF_API_KEY} at runtime
          url = "https://api.ref.tools/mcp?apiKey=\${REF_API_KEY}";
        };
        github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp/";
          # Claude Code will expand ${GITHUB_READ_TOKEN} at runtime
          headers.Authorization = "Bearer \${GITHUB_READ_TOKEN}";
        };
      }
      (mkIf config.${namespace}.apps.office.libreoffice.enable {
        libreoffice = {
          type = "stdio";
          command = "nix";
          args = [
            "run"
            "github:dtgagnon/nix-config#mcp-libreoffice"
            "--"
          ];
        };
      })
      (mkIf (osConfig.${namespace}.services.n8n.enable or false) {
        n8n-mcp = {
          type = "stdio";
          command = "npx";
          args = [
            "-y"
            "supergateway"
            "--streamableHttp"
            "http://localhost:5678/mcp-server/http"
            "--header"
            "authorization:Bearer \${N8N_ACCESS_TOKEN}"
          ];
        };
      })
    ];
  };
}
