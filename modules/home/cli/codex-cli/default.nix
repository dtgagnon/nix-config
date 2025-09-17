{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.${namespace}.cli.codex;
in
{
  options.${namespace}.cli.codex = {
    enable = mkEnableOption "Enable codex";
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        codex
        nodejs # for `npx` mcp servers
      ];
    };

    sops.templates."codex-config.toml" = {
      path = "${config.xdg.configHome}/codex/config.toml";
      content = ''
        model = "gpt-5-codex"

        [tools]
        web_search = true

        [mcp_servers.nixos]
            command = "nix"
            args = [ "run", "github:utensils/mcp-nixos", "--" ]
        [mcp_servers.Ref]
            command = "npx"
            args = [ "ref-tools-mcp@latest" ]
            env = { "REF_API_KEY" = "${config.sops.placeholder.ref_api}" }

        [projects."/home/dtgagnon/nix-config/nixos"]
        trust_level = "trusted"
      '';
    };

    # xdg.configFile."codex/config.toml".source = config.sops.templates."codex-config.toml".path;
    home.sessionVariables = {
      CODEX_HOME = "$HOME/.config/codex";
    };
  };
}
