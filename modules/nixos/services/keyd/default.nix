{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.${namespace}.services.keyd;
in
{
  options.${namespace}.services.keyd = {
    enable = mkEnableOption "keyd";
    keyboards = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "A set of keyboards and their key mappings.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.keyd ];

    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings = {
          main = {
            capslock = null;
            esc = "overload(symbols, esc)";
          };
          symbols = {
            t = "`";
            h = "~";
          };
        };
      };
    };
  };
}
