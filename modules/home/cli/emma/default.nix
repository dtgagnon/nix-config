{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.${namespace}.cli.emma;
in
{
  options.${namespace}.cli.emma = {
    enable = mkEnableOption "emma email automation CLI";

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Settings passed through to programs.emma.settings";
    };
  };

  config = mkIf cfg.enable {
    programs.emma = {
      enable = true;
      settings = cfg.settings;
    };
  };
}
