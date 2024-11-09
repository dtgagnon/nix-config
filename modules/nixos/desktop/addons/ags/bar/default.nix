{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types getExe;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.ags.bar;

  bar = pkgs.runCommandNoCC "spirenix-ags-bar" { } ''
    mkdir -p $out
    cp -r ${./src}/* $out/
    rm -rf $out/css/index.css
    mkdir -p $out/css
    ${lib.getExe pkgs.sassc}/bin/sassc $out/sass/index.scss $out/css/index.css
    rm -rf $out/styles/sass
  '';
in
{
  options.${namespace}.desktop.addons.ags.bar = {
    enable = mkBoolOpt false "AGS Bar";
    package = mkOpt types.package pkgs.ags "The package to use for AGS";
  };

  config = mkIf cfg.enable {
    spirenix = {
      desktop.hyprland.settings = {
        exec-once = [ "${getExe cfg.package} --config ${bar}/config.js" ];
      };
    };
  };
}
