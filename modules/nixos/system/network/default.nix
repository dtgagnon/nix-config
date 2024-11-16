{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.system.network;
in
{
  options.${namespace}.system.network = {
    enable = mkBoolOpt false "Whether or not to enable networking support";
    hosts = mkOpt types.attrs { } "An attribute set to merge with `networking.hosts`";
  };

  config = mkIf cfg.enable {
    spirenix.user.extraGroups = [ "networkmanager" ];
    
    networking = {
      firewall.enable = true;
      firewall.allowedTCPPorts = [ ... ];
      firewall.allowedUDPPorts = [ ... ];

      hosts = {
        "127.0.0.1" = [ "local.test" ] ++ (cfg.hosts."127.0.0.1" or [ ]);
      } // cfg.hosts;

      useDHCP = lib.mkDefault true;
      networkmanager = {
        enable = true;
        dhcp = "internal";
      };
    };

    # Fixes an issue that normally causes nixos-rebuild to fail.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
