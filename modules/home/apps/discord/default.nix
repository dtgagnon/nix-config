{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.discord;
in
{
  options.${namespace}.apps.discord = {
    enable = mkBoolOpt false "Enable Discord module";
  };

  config = mkIf cfg.enable {
    programs.vesktop = {
      enable = true;
      vencord.useSystem = true;
      settings = {
        discordBranch = "stable";
        hardwareAcceleration = true;
        tray = true;
        minimizeToTray = true;
        arRPC = true;
        splashTheming = true;
        splashBackground = "#2c2d32";
      };
    };

    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/discord" = "vesktop.desktop";
    };

    spirenix.preservation.directories = [
      ".config/vesktop"
    ];
  };
}
