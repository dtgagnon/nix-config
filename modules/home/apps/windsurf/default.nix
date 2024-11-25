{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.windsurf;
in
{
  options.${namespace}.apps.windsurf = {
    enable = mkBoolOpt false "Enable windsurf module";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.spirenix.windsurf ];

    spirenix.user.home.persistHomeDirs = [
      ".config/Windsurf"  # Future XDG config location
      ".windsurf"         # Current data directory
      ".codeium"          # Codeium data directory
    ];
  };
}
