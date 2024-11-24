{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    types
    optionalString
    concatLines
    attrValues
    ;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.system.impermanence;
  user = config.home-manager.users.${config.${namespace}.user.name}.${namespace}.user;
in
{
  options.${namespace}.system.impermanence = {
    enable = mkBoolOpt false "Enable impermanence";
    extraSysDirs = mkOpt (types.listOf types.str) [ ] "Declare additional system directories to persist";
    extraSysFiles = mkOpt (types.listOf types.str) [ ] "Declare additional system files to persist";
    extraHomeDirs = mkOpt (types.listOf types.str) [ ] "Declare additional user home directories to persist";
    extraHomeFiles = mkOpt (types.listOf types.str) [ ] "Declare additional user home files to persist";
  };

  config = mkIf cfg.enable {
    programs.fuse.userAllowOther = true;
    fileSystems."/persist".neededForBoot = true;
    environment.persistence."/persist" = {
      hideMounts = false;
      directories = [
        "/etc/nixos"
        "/etc/ssh"
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/sops-nix"
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
        {
          directory = "/var/lib/colord";
          user = "colord";
          group = "colord";
          mode = "u=rwx,g=rx,o=";
        }
      ] ++ cfg.extraSysDirs;
      files = [
        "/etc/machine-id"
        { file = "/var/keys/secret_file"; parentDirectory = { mode = "0700"; }; }
      ] ++ cfg.extraSysFiles;

      users.${user.name} = {
        directories = [
          "nix-config"
          "Documents"
          "Downloads"
          "Music"
          "Pictures"
          "Videos"
          ".windsurf"
          ".codeium"
          ".mozilla"
          ".config"
          ".local"
          ".local/share/direnv"
          ".ssh"
        ] ++ snowfallorg.users.${user.name}.home.config.${namespace}.home.persistHomeDirs ++ cfg.extraHomeDirs;
        files = [
          # common user files to persist
        ];
	# ++ config.spirenix.home.extraOptions.persistHomeFiles ++ cfg.extraHomeFiles;
      };
    };

    #NOTE: v v v The below systemd script is needed to create root paths for users' home directories, due to home-manager permissions contraints
    # system.activationScripts.persistent-dirs.text =
    #   let
    #     mkHomePersist =
    #       user:
    #       optionalString user.createHome ''
    #         mkdir -p /persist/${user.home}
    #         chown ${user.name}:${user.group} /persist/${user.home}
    #         chmod ${user.homeMode} /persist/${user.home}
    #       '';
    #     users = attrValues config.users.users;
    #   in
    #   concatLines (map mkHomePersist users);


    #NOTE: ^ ^ ^ The above is necessary for home-manager impermanence module to function

    #NOTE: v v v The below systemd script is needed to create root paths for users' home directories, due to home-manager permissions contraints
    # systemd.services."persist-home-create-root-paths" =
    #   let
    #     persistentHomesRoot = "/persist/home";
    #     listOfCommands = l.mapAttrsToList
    #       (_: user:
    #         let
    #           userHome = l.escapeShellArg (persistentHomesRoot + user.home);
    #         in
    #         ''
    #           if [[ ! -d ${userHome} ]]; then
    #               echo "Persistent home root folder '${userHome}' not found, creating..."
    #               mkdir -p --mode=${user.homeMode} ${userHome}
    #               chown ${user.name}:${user.group} ${userHome}
    #           fi
    #         '')
    #       (l.filterAttrs (_: user: user.createHome == true) config.users.users);

    #     stringOfCommands = l.concatLines listOfCommands;
    # in {
    #     script = stringOfCommands;
    #     unitConfig = {
    #         Description = "Ensure users' home folders exist in the persistent filesystem";
    #         PartOf = [ "local-fs.target" ];
    #         # The folder creation should happen after the persistent home path is mounted.
    #         After = [ "persist-home.mount" ];
    #     };

    #     serviceConfig = {
    #         Type = "oneshot";
    #         StandardOutput = "journal";
    #         StandardError = "journal";
    #     };

    #     # [Install]
    #     wantedBy = [ "local-fs.target" ];

    # };

    # boot.initrd.systemd.services.rollback = {
    #   description = "Rollback BTRFS root subvolume to a pristine state";
    #   unitConfig.DefaultDependencies = "no";
    #   serviceConfig.Type = "oneshot";
    #   wantedBy = [ "initrd.target" ];
    #   after = [ "systemd-cryptsetup@crypted.service" ];
    #   before = [ "sysroot.mount" ];

    # Disk wiping script for impermanence
    boot.initrd.postDeviceCommands = lib.mkAfter ''
      mkdir /btrfs_tmp
      mount /dev/root_vg/root /btrfs_tmp
      if [[ -e /btrfs_tmp/root ]]; then
      	mkdir -p /btrfs_tmp/old_roots
      	timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
      	mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
      fi

      delete_subvolume_recursively() {
      	IFS=$'\n'
      	for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
      		delete_subvolume_recursively "/btrfs_tmp/$i"
      	done
      	btrfs subvolume delete "$1"
      }

      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
      	delete_subvolume_recursively "$i"
      done

      btrfs subvolume create /btrfs_tmp/root
      umount /btrfs_tmp
    '';
  };
}
