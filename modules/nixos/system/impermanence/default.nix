{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.system.impermanence;
  user = config.${namespace}.user.name;
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
    fileSystems."/persist".neededForBoot = true;
    environment.persistence."/persist/system" = {
      hideMounts = true;
      directories = [
        "/etc/nixos"
        "/etc/ssh"
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/sops-nix"
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
        { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
      ] ++ cfg.extraSysDirs;
      files = [
        "/etc/machine-id"
        { file = "/var/keys/secret_file"; parentDirectory = { mode = "0700"; }; }
      ] ++ cfg.extraSysFiles;

      users.${user} = {
        directories = [
          "proj"
          "Documents"
          "Pictures"
          "Downloads"
          ".ssh"
          ".local/share/direnv"
          ".config/sops"
          "nix-config"
        ] ++ cfg.extraHomeDirs;
        files = [
          ".screenrc"
          "keys.txt"
        ] ++ cfg.extraHomeFiles;
      };
    };
    programs.fuse.userAllowOther = true;

    # Disk wiping script for impermanence
    boot.initrd.systemd.services.rollback = {
      description = "Rollback BTRFS root subvolume to a pristine state";
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      wantedBy = [ "initrd.target" ];
      after = [ "systemd-cryptsetup@crypted.service" ];
      before = [ "sysroot.mount" ];

      script = ''
		vgchange -ay pool
		mkdir -p /btrfs_tmp
		mount /dev/pool/root /btrfs_tmp

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
  };
}