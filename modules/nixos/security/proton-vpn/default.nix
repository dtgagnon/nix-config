{ 
  lib,
  pkgs,
  config,
  namespace, 
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.security.protonvpn;
in {
  options.${namespace}.security.protonvpn = {
    enable = mkBoolOpt false "Enable ProtonVPN";
    username = mkOpt types.str "Your ProtonVPN username";
    passwordFile = mkOpt types.path "Path to the file containing your ProtonVPN password";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      protonvpn-gui
      networkmanagerapplet
    ];
  };
}