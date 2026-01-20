{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types mkEnableOption mkOption;
  cfg = config.${namespace}.apps.office.libreoffice;
  mcp-libreoffice = pkgs.${namespace}.mcp-libreoffice;
in
{
  options.${namespace}.apps.office.libreoffice = {
    enable = mkEnableOption "LibreOffice suite";
    branch = mkOption {
      default = "fresh";
      type = types.enum [ "fresh" "still" ];
      description = "Choose LibreOffice branch (fresh or still)";
    };
    extraOfficePkgs = mkOption {
      default = [ ];
      type = types.listOf types.package;
      description = "Additional packages (e.g., dictionaries)";
    };
    mcpExtension = mkEnableOption "MCP extension for AI assistant integration";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs."libreoffice-${cfg.branch}" ] ++ cfg.extraOfficePkgs;

    # Symlink MCP extension to user's LibreOffice extensions directory
    home.file = mkIf cfg.mcpExtension {
      ".local/share/libreoffice/extensions/libreoffice-mcp-extension.oxt".source =
        "${mcp-libreoffice}/share/libreoffice/extensions/libreoffice-mcp-extension.oxt";
    };
  };
}
