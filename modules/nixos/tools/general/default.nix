{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.tools.general;
in
{
  options.${namespace}.tools.general = {
    enable = mkBoolOpt false "Whether or not to enable common cli utilities.";
  };

  config = mkIf cfg.enable {
    # sn.home.configFile."wgetrc".text = "";

    environment.systemPackages = with pkgs; [
      ## Text Utilities
      ripgrep
      jq

      ## Process Utilities
      killall

      ## Files
      unzip
      file

      ## Network Utilities
      wget

      ## Editor Utilities
      glow

      ## Misc Utilities
      clac
    ];
  };
}
