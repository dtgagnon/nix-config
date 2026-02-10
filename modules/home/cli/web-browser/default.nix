{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.cli.web-browser;
in
{
  options.${namespace}.cli.web-browser = {
    enable = mkBoolOpt false "Enable TUI web browser module";
    browser = mkOpt (types.enum [ "lynx" "w3m" "elinks" "browsh"]) "elinks" "Select TUI browser to install: lynx, w3m, or elinks";
  };

  config = mkIf cfg.enable {
    home = {
      packages =
        if cfg.browser == "browsh" then [ pkgs.browsh pkgs.firefox ]
        else [ (if cfg.browser == "lynx" then pkgs.lynx
                else if cfg.browser == "w3m" then pkgs.w3m
                else pkgs.elinks) ];
    };
  };
}
