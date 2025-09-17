{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.desktop.addons.hellwal;
in
{
  options.${namespace}.desktop.addons.hellwal = {
    enable = mkEnableOption "Enable Hellwal wallpaper management.";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.spirenix.hellwal ];

    # # Create systemd user service for hellwal
    # systemd.user.services.hellwal = {
    #   Unit = {
    #     Description = "Hellwal wallpaper management service";
    #     After = "graphical-session.target";
    #     PartOf = "graphical-session.target";
    #   };
    #
    #   Service = {
    #     ExecStart = "${pkgs.hellwal}/bin/hellwal --dir ${cfg.wallpaperDir} ${lib.optionalString cfg.randomize "--random"} --interval ${toString cfg.interval}";
    #     Restart = "on-failure";
    #   };
    #
    #   Install = {
    #     WantedBy = ["graphical-session.target"];
    #   };
    # };
  };
}
