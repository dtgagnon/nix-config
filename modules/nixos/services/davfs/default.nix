{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.davfs;
in
{
  options.${namespace}.services.davfs = {
    enable = mkBoolOpt false "Enable the mount.davfs daemon";
    extraSettings = mkOpt types.attrs { } "An attribute set containing addition configuration for davfs2";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.davfs2 ];
    services.davfs2 = {
      enable = true;
      davUser = "davfs2";
      davGroup = "davfs2";
      settings = { } // cfg.extraSettings;
    };
  };
}
