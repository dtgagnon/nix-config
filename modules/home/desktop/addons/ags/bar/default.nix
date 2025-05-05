{ lib
, pkgs
, config
, inputs
, system
, namespace
, ...
}:
let
  inherit (lib) mkIf types getExe;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.ags.bar;

  bar = pkgs.runCommandNoCC "spirenix-ags-bar" {
    nativeBuildInputs = [ pkgs.sassc ];
  } ''
    # Create output structure
    mkdir -p $out/css
    
    # Copy config.js and necessary files
    cp ${./src}/config.js $out/
    
    # Ensure assets directory is copied
    mkdir -p $out/assets
    cp -r ${./src}/assets/* $out/assets/
    
    # Copy components and util directories
    mkdir -p $out/components $out/util
    cp -r ${./src}/components/* $out/components/
    cp -r ${./src}/util/* $out/util/
    
    # Compile SASS to CSS
    sassc ${./src}/sass/index.scss $out/css/index.css
  '';
in
{
  options.${namespace}.desktop.addons.ags.bar = {
    enable = mkBoolOpt false "AGS Bar";
    package = mkOpt types.package inputs.ags.packages.${system}.default "The package to use for AGS";
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    spirenix = {
      desktop.hyprland.extraExec = [ "${getExe cfg.package} --config ${bar}/config.js" ];
    };
  };
}
