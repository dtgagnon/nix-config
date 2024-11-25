{
  lib,
  config,
  namespace,
  ...
}: 
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.hardware.storage.disko;

  # For ZFS: Create datasets for each path with custom options  
  # Example: root -> /, nix -> /nix, persist -> /persist
  # Each dataset inherits the specified ZFS options (compression, atime, etc)
  mkFsConfig = fs: let
    zfsDatasets = builtins.listToAttrs (map (path: {
      name = path;
      value = {
        mountpoint = if path == "root" then "/" else "/${path}";
      } // cfg.partitioning.subvolumes.zfsOptions;
    }) cfg.partitioning.subvolumes.paths);
    
    # For Btrfs: Create subvolumes for each path with custom mount options
    # Example: /root -> /, /nix -> /nix, /persist -> /persist
    # Each subvolume can have its own mount options (noatime, compress, etc)
    btrfsSubvolumes = builtins.listToAttrs (map (path: {
      name = "/${path}";
      value = {
        mountpoint = if path == "root" then "/" else "/${path}";
        mountOptions = cfg.partitioning.subvolumes.btrfsOptions.${path} or [];
      };
    }) cfg.partitioning.subvolumes.paths);
  in
    # First branch: ZFS configuration
    if fs == "zfs" then {
      type = "zfs";
      pool = "rpool";
      # Only create datasets if subvolumes are enabled
      datasets = mkIf cfg.partitioning.subvolumes.enable zfsDatasets;
    }
    # Second branch: Btrfs configuration
    else if fs == "btrfs" then {
      type = "btrfs";
      extraArgs = ["-f"];
      # Only create subvolumes if enabled
      subvolumes = mkIf cfg.partitioning.subvolumes.enable btrfsSubvolumes;
    }
    # Third branch: Basic filesystem (ext4)
    else {
      type = "filesystem";
      format = fs;
      mountpoint = "/";
    };
in {
  options.${namespace}.hardware.storage.disko = {
    enable = mkBoolOpt false "Whether to enable disk configuration with disko";
    device = mkOpt types.str "/dev/nvme0n1" "Target disk device path";
    
    partitioning = {
      enable = mkBoolOpt true "Whether to enable disk partitioning";
      efiSize = mkOpt types.str "512M" "Size of EFI system partition";
      bootSize = mkOpt types.str "1M" "Size of boot partition";
      useLogicalVolumes = mkBoolOpt true "Whether to use LVM";
      rootFilesystem = mkOpt (types.enum ["btrfs" "zfs" "ext4"]) "btrfs" 
        "Root filesystem type to use (btrfs, zfs, or ext4)";
      
      # Filesystem-specific options
      subvolumes = {
        enable = mkBoolOpt true "Whether to create subvolumes/datasets";
        paths = mkOpt (types.listOf types.str) [
          "root"
          "nix"
          "persist"
        ] "Paths to create as subvolumes or datasets";
        
        # ZFS-specific options
        zfsOptions = mkOpt (types.attrsOf types.str) {
          compression = "zstd";
          atime = "off";
          xattr = "sa";
          acltype = "posixacl";
        } "ZFS dataset options";
        
        # Btrfs-specific options
        btrfsOptions = mkOpt (types.attrsOf (types.listOf types.str)) {
          root = [ ];
          nix = ["subvol=nix" "noatime"];
          persist = ["subvol=persist" "noatime"];
        } "Btrfs mount options per subvolume";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.partitioning.rootFilesystem != "zfs" || 
                   !cfg.partitioning.useLogicalVolumes;
        message = "ZFS should not be used with LVM as it provides its own volume management";
      }
      {
        assertion = cfg.partitioning.subvolumes.enable -> 
                   (cfg.partitioning.rootFilesystem != "ext4");
        message = "Subvolumes can only be used with btrfs or zfs";
      }
    ];

    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = cfg.device;
          content = {
            type = "gpt";
            partitions = {
              boot = {
                name = "boot";
                size = cfg.partitioning.bootSize;
                type = "EF02";
              };
              esp = {
                name = "ESP";
                size = cfg.partitioning.efiSize;
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              root = {
                name = "root";
                size = "100%";
                content = 
                  if cfg.partitioning.useLogicalVolumes then {
                    # If using LVM, create a physical volume
                    # The actual filesystem will be created in the logical volume below
                    type = "lvm_pv";
                    vg = "root_vg";
                  } else mkFsConfig cfg.partitioning.rootFilesystem;
              };
            };
          };
        };
      };

      # If using LVM, create the volume group and logical volumes
      # The filesystem configuration from mkFsConfig is applied here
      lvm_vg = mkIf cfg.partitioning.useLogicalVolumes {
        root_vg = {
          type = "lvm_vg";
          lvs = {
            root = {
              size = "100%FREE";
              content = mkFsConfig cfg.partitioning.rootFilesystem;
            };
          };
        };
      };
    };
  };
}