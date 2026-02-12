{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkMerge types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.nfs;
in
{
  options.${namespace}.services.nfs = {
    enable = mkBoolOpt false "Enable NFS client and/or server functionality";

    mounts = mkOpt (types.attrsOf (types.submodule {
      options = {
        server = mkOpt types.str "" "NFS server address (IP or hostname)";
        remotePath = mkOpt types.str "" "Remote export path on the NFS server";
        mountPoint = mkOpt types.str "" "Local directory where the share will be mounted";
        extraOptions = mkOpt (types.listOf types.str) [ ] "Additional mount options";
      };
    })) { } "NFS client mounts to configure";

    exports = mkOpt (types.listOf types.str) [ ] "NFS export lines for /etc/exports";
    openFirewall = mkBoolOpt false "Open firewall ports for NFS server";
  };

  config = mkIf cfg.enable (
    let
      mountConfigs = lib.attrValues cfg.mounts;
      hasMounts = mountConfigs != [ ];
      hasExports = cfg.exports != [ ];
    in
    mkMerge [
      # Client: mount remote NFS shares
      (mkIf hasMounts {
        # Ensure NFS client utilities are available
        boot.supportedFilesystems = [ "nfs" ];

        # Create mount points via tmpfiles
        systemd.tmpfiles.rules = lib.flatten (
          lib.mapAttrsToList
            (_name: mountCfg: [
              "d ${mountCfg.mountPoint} 0755 root root -"
            ])
            cfg.mounts
        );

        # Configure filesystem mounts with automount
        fileSystems = lib.mkMerge (
          lib.mapAttrsToList
            (_name: mountCfg: {
              ${mountCfg.mountPoint} = {
                device = "${mountCfg.server}:${mountCfg.remotePath}";
                fsType = "nfs";
                options = [
                  "x-systemd.automount"
                  "x-systemd.idle-timeout=300"
                  "soft"
                  "noatime"
                  "_netdev"
                ] ++ mountCfg.extraOptions;
              };
            })
            cfg.mounts
        );
      })

      # Server: export local directories via NFS
      (mkIf hasExports {
        services.nfs.server = {
          enable = true;
          exports = lib.concatStringsSep "\n" cfg.exports;
        };

        networking.firewall = mkIf cfg.openFirewall {
          allowedTCPPorts = [ 2049 ];
          allowedUDPPorts = [ 2049 ];
        };
      })
    ]
  );
}
