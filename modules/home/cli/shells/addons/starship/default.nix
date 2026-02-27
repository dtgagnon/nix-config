{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.shells.addons.starship;
in
{
  options.${namespace}.cli.shells.addons.starship = {
    enable = mkBoolOpt false "Enables starship cross-shell prompt";
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      settings = {
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red) ";
          vicmd_symbol = "[](bold blue) ";
        };
      };
    };
  };
}
