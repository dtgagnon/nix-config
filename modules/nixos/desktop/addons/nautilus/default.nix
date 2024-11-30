{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.nautilus;
in
{
  options.${namespace}.desktop.addons.nautilus = {
    enable = mkBoolOpt false "Whether to enable the gnome file manager.";
  };

  config = mkIf cfg.enable {
    # Enable support for browsing samba shares.
    services.gvfs.enable = true;
    networking.firewall.extraCommands = "iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns";
    
    environment.systemPackages = [ pkgs.nautilus ];
  };
}
