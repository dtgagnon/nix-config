{
  options
, config
, lib
, pkgs
, namespace
, ...
}:
with lib;
with lib.${namespace};
let cfg = config.${namespace}.tools.general;
in {
  options.${namespace}.tools.general = with types; {
    enable = mkBoolOpt false "Whether or not to enable common cli utilities.";
  };

  config = mkIf cfg.enable {
    # sn.home.configFile."wgetrc".text = "";

    environment.systemPackages = with pkgs; [
      killall
      unzip
      file
      jq
      clac
      wget
      glow
    ];
  };
}
