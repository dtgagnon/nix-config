{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types mkEnableOption mkOption;
  cfg = config.${namespace}.apps.office.libreoffice;
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
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs."libreoffice-${cfg.branch}" ] ++ cfg.extraOfficePkgs;
  };
}
