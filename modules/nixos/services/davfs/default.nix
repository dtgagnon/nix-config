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
    mounts = mkOpt (types.attrsOf (types.submodule {
      options = {
        url = mkOpt types.str "" "WebDAV server URL to mount";
        mountPoint = mkOpt types.str "" "Local directory where the share will be mounted";
        username = mkOpt types.str "" "Username for WebDAV authentication and local user for mount ownership";
        passwordFile = mkOpt types.str "" "Path to file containing the password (can be a sops secret path like /run/secrets/...)";
        autoMount = mkBoolOpt false "Automatically mount at boot via systemd";
        extraOptions = mkOpt (types.listOf types.str) [ ] "Additional mount options";
      };
    })) { } "WebDAV mounts to configure";
  };

  config = mkIf cfg.enable (
    let
      mountConfigs = lib.attrValues cfg.mounts;
      hasMounts = mountConfigs != [ ];
    in
    lib.mkMerge [
      {
        environment.systemPackages = [ pkgs.davfs2 ];
        services.davfs2 = {
          enable = true;
          davUser = "davfs2";
          davGroup = "davfs2";
          settings = { } // cfg.extraSettings;
        };
      }

      (mkIf hasMounts {
        # Add users to davfs2 group so they can mount
        users.users = lib.mkMerge (
          lib.mapAttrsToList
            (name: mountCfg: {
              ${mountCfg.username}.extraGroups = [ "davfs2" ];
            })
            cfg.mounts
        );

        # Create mount points for all configured mounts
        systemd.tmpfiles.rules = lib.flatten (
          lib.mapAttrsToList
            (name: mountCfg:
              let
                userCfg = config.users.users.${mountCfg.username};
                gid = userCfg.group;
              in
              [ "d ${mountCfg.mountPoint} 0755 ${mountCfg.username} ${gid} -" ]
            )
            cfg.mounts
        );

        # Configure filesystem mounts
        fileSystems = lib.mkMerge (
          lib.mapAttrsToList
            (name: mountCfg:
              let
                userCfg = config.users.users.${mountCfg.username};
                uid = userCfg.uid;
                gid = userCfg.group;
                # For automount: systemd mounts as root with specific uid/gid
                # For manual mount: user mounts it themselves (no uid/gid needed)
                baseOptions = [
                  "file_mode=0644"
                  "dir_mode=0755"
                  "_netdev"
                ];
                autoMountOptions = [
                  "uid=${toString uid}"
                  "gid=${gid}"
                  "x-systemd.automount"
                  "x-systemd.idle-timeout=300"
                  "x-systemd.requires=davfs-secrets-setup.service"
                  "x-systemd.after=davfs-secrets-setup.service"
                  "x-systemd.device-timeout=10s"
                ];
                manualMountOptions = [
                  "noauto"
                  "user"
                ];
              in
              {
                ${mountCfg.mountPoint} = {
                  device = mountCfg.url;
                  fsType = "davfs";
                  options = baseOptions
                    ++ (if mountCfg.autoMount then autoMountOptions else manualMountOptions)
                    ++ mountCfg.extraOptions;
                };
              }
            )
            cfg.mounts
        );

        # Generate davfs2 secrets file at runtime
        systemd.services.davfs-secrets-setup = {
          description = "Setup davfs2 credentials";
          wantedBy = [ "multi-user.target" ];
          before = [ "remote-fs.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            mkdir -p /etc/davfs2
            > /etc/davfs2/secrets
            ${lib.concatStringsSep "\n" (
              lib.mapAttrsToList
                (name: mountCfg:
                  if mountCfg.passwordFile != "" then
                    ''
                      password=$(cat ${mountCfg.passwordFile})
                      echo "${mountCfg.mountPoint} ${mountCfg.username} $password" >> /etc/davfs2/secrets
                    ''
                  else
                    ""
                )
                cfg.mounts
            )}
            chmod 0600 /etc/davfs2/secrets
          '';
        };
      })
    ]
  );
}
