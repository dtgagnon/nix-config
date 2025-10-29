{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  cfg = config.${namespace}.cli.claude-code;
in
{
  config = mkIf cfg.enable {
    # Declare secrets in home-manager sops (userspace only)
    sops.secrets = {
      ref_api = { };
    };

    programs.claude-code.mcpServers = {
      nixos = {
        transport = "stdio";
        command = "nix";
        args = [ "run" "github:utensils/mcp-nixos" "--" ];
      };
      ref = {
        type = "http";
        # Use '' to escape $ - becomes ${REF_API_KEY} at runtime
        url = "https://api.ref.tools/mcp?apiKey=${config.sops.placeholder.ref_api}";
      };
      github = {
        type = "http";
        url = "https://api.githubcopilot.com/mcp/";
        # Use '' to escape $ - becomes ${GITHUB_READ_TOKEN} at runtime
        headers.Authorization = "Bearer XYZ123"; # ${config.sops.placeholder.github_read_token}
      };
    };
  };
}
