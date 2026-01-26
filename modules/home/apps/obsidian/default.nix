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
  cfg = config.${namespace}.apps.obsidian;
in
{
  options.${namespace}.apps.obsidian = {
    enable = mkBoolOpt false "Enable Obsidian module";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.obsidian ];

    spirenix.preservation.directories = [
      ".config/obsidian"
    ];
  };
}