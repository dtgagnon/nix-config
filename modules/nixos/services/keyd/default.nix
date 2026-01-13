{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption optionals types;
  cfg = config.${namespace}.services.keyd;
  keyboardCfg = config.${namespace}.hardware.keyboard;
  mouseCfg = config.${namespace}.hardware.mouse;
  keyboardIds =
    if keyboardCfg.enable then
      (if keyboardCfg.ids == [ ] then [ "*" ] else keyboardCfg.ids)
    else
      [ ];
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
        ids = keyboardIds ++ optionals mouseCfg.enable mouseCfg.ids;
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
