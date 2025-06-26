{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.gemini-cli;
in
{
  options.${namespace}.cli.gemini-cli = {
    enable = mkBoolOpt false "Enable the Google Gemini AI CLI tool";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.gemini-cli ];
  };
}
