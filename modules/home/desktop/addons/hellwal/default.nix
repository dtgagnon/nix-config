{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.hellwal;
in
{
  options.${namespace}.desktop.addons.hellwal = {
    enable = mkBoolOpt false "Whether to enable Hellwal wallpaper management.";

    # Basic configuration options
    wallpaperDir = mkOpt types.path "${config.home.homeDirectory}/Pictures/wallpapers" "Directory containing wallpapers.";
    interval = mkOpt types.int 3600 "Interval in seconds between wallpaper changes.";
    randomize = mkBoolOpt true "Whether to select wallpapers randomly.";
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
