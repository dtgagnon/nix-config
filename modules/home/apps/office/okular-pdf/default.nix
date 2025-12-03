{ 
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.office.okular-pdf;
in
{
  options.${namespace}.apps.office.okular-pdf = {
    enable = mkBoolOpt false "Okular PDF viewer";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.kdePackages.okular ];

    xdg.mimeApps.defaultApplications = {
      "application/pdf" = "org.kde.okular.desktop";
    };
  };
}