{ lib
, host
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkMerge types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt snowfallHostUserList;
  cfg = config.${namespace}.system.preservation;

  users = snowfallHostUserList host;

  # Helper to extract the name from an item (string or attrset)
  itemName = item:
    if builtins.isString item then item
    else item.directory or item.file or "";

  # Apply exclusions to a list of items
  applyExclusions = items: exclusions:
    lib.filter (item: !(lib.elem (itemName item) exclusions)) items;

  # Tier definitions - progressively include more items
  tierSystemDirs = {
    minimal = [
      { directory = "/var/lib/nixos"; inInitrd = true; }
      "/var/lib/systemd/coredump"
      "/var/lib/systemd/rfkill"
      "/var/lib/systemd/timers"
      "/var/log"
    ];
    server = tierSystemDirs.minimal;
    full = tierSystemDirs.server ++ [
      "/etc/secureboot"
      "/etc/greetd"
      "/var/lib/bluetooth"
      "/var/lib/fprint"
      "/var/lib/fwupd"
      { directory = "/var/lib/libvirt"; user = "qemu-libvirtd"; group = "qemu-libvirtd"; mode = "0750"; }
      { directory = "/var/lib/qemu"; user = "qemu-libvirtd"; group = "qemu-libvirtd"; mode = "0750"; }
      "/var/lib/power-profiles-daemon"
      { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "0754"; }
    ];
  };

  tierSystemFiles = {
    minimal = [
      { file = "/etc/machine-id"; inInitrd = true; how = "symlink"; configureParent = true; }
      { file = "/etc/ssh/ssh_host_ed25519_key"; mode = "0600"; how = "symlink"; createLinkTarget = true; }
      { file = "/etc/ssh/ssh_host_ed25519_key.pub"; mode = "0644"; how = "symlink"; createLinkTarget = true; }
      { file = "/var/lib/systemd/random-seed"; how = "symlink"; inInitrd = true; configureParent = true; }
    ];
    server = tierSystemFiles.minimal;
    full = tierSystemFiles.server ++ [
      "/var/lib/usbguard/rules.conf"
    ];
  };

  tierHomeDirs = {
    minimal = [
      { directory = ".ssh"; mode = "0700"; }
    ];
    server = tierHomeDirs.minimal ++ [
      { directory = ".pki"; mode = "0700"; }
      { directory = ".gnupg"; mode = "0700"; }
      ".local/state/nix"
    ];
    full = tierHomeDirs.server ++ [
      "Apps"
      "Documents"
      "Downloads"
      "Games"
      "Music"
      "Pictures"
      "Sync"
      "Videos"
      ".config/syncthing"
      ".local/state/nvim"
      ".local/state/syncthing"
      ".local/state/wireplumber"
      { directory = ".zen"; mode = "0700"; }
    ];
  };

  tierHomeFiles = {
    minimal = [
      ".histfile"
    ];
    server = tierHomeFiles.minimal;
    full = tierHomeFiles.server;
  };

  # Get effective items for current tier with exclusions applied
  effectiveSystemDirs = applyExclusions tierSystemDirs.${cfg.tier} cfg.exclude.systemDirs ++ cfg.extraSysDirs;
  effectiveSystemFiles = applyExclusions tierSystemFiles.${cfg.tier} cfg.exclude.systemFiles ++ cfg.extraSysFiles;
  effectiveHomeDirs = applyExclusions tierHomeDirs.${cfg.tier} cfg.exclude.homeDirs ++ cfg.extraHomeDirs;
  effectiveHomeFiles = applyExclusions tierHomeFiles.${cfg.tier} cfg.exclude.homeFiles ++ cfg.extraHomeFiles;

  # User submodule for per-user configuration
  userSubmodule = types.submodule {
    options = {
      home = mkOpt (types.nullOr types.str) null "Home directory (if not /home/<user>)";
      directories = mkOpt (types.listOf (types.either types.str types.attrs)) [ ] "User-specific directories";
      files = mkOpt (types.listOf (types.either types.str types.attrs)) [ ] "User-specific files";
    };
  };

in
{
  options.${namespace}.system.preservation = with types; {
    enable = mkBoolOpt false "Enable the preservation impermanence framework";

    # Simple tier selection (default = "full" for backward compat)
    tier = mkOpt (enum [ "minimal" "server" "full" ]) "full" ''
      Persistence tier:
      - minimal: Core system only (machine-id, nixos, logs, ssh keys)
      - server: Minimal + common server needs (no GUI/desktop apps)
      - full: Everything (current behavior, default)
    '';

    # Exclusions - remove specific items from tier defaults
    exclude = {
      systemDirs = mkOpt (listOf str) [ ] "System directories to exclude from tier defaults";
      systemFiles = mkOpt (listOf str) [ ] "System files to exclude from tier defaults";
      homeDirs = mkOpt (listOf str) [ ] "Home directories to exclude from tier defaults";
      homeFiles = mkOpt (listOf str) [ ] "Home files to exclude from tier defaults";
    };

    # Per-user configuration (replaces hardcoded user blocks)
    users = mkOpt (attrsOf userSubmodule) { } "Per-user persistence configuration";

    # Existing options (kept for compatibility)
    extraUser = {
      user = mkOpt str "" "Declare additional users";
      homeDirs = mkOpt (listOf (either str attrs)) [ ] "Declare extra user home directories to persist";
      homeFiles = mkOpt (listOf (either str attrs)) [ ] "Declare extra user home files to persist";
    };
    extraSysDirs = mkOpt (listOf (either str attrs)) [ ] "Declare additional system directories to persist";
    extraSysFiles = mkOpt (listOf (either str attrs)) [ ] "Declare additional system files to persist";
    extraHomeDirs = mkOpt (listOf (either str attrs)) [ ] "Declare additional user home directories to persist";
    extraHomeFiles = mkOpt (listOf (either str attrs)) [ ] "Declare additional user home files to persist";
  };

  config = mkIf cfg.enable {
    fileSystems."/persist".neededForBoot = true;

    preservation = {
      enable = true;
      preserveAt."/persist" = {

        # Preserve system directories based on tier
        directories = effectiveSystemDirs;

        # Preserve system files based on tier
        files = effectiveSystemFiles;

        # Preserve user-specific files, implies ownership
        users = mkMerge [
          # Apply tier defaults to all users from snowfallHostUserList
          (builtins.foldl' lib.recursiveUpdate { }
            (map
              (user: {
                ${user} = {
                  directories = effectiveHomeDirs;
                  files = effectiveHomeFiles;
                };
              })
              users
            )
          )

          # Per-user configurations from cfg.users option
          (builtins.mapAttrs
            (username: userCfg: {
              directories = userCfg.directories;
              files = userCfg.files;
            } // lib.optionalAttrs (userCfg.home != null) {
              home = userCfg.home;
            })
            cfg.users
          )

          # Root user special case (home is /root)
          {
            root = {
              home = "/root";
              directories = [
                { directory = ".ssh"; mode = "0700"; }
              ];
            };
          }

          # Legacy extraUser support (kept for compatibility)
          (lib.optionalAttrs (cfg.extraUser.user != "") {
            ${cfg.extraUser.user} = {
              directories = cfg.extraUser.homeDirs;
              files = cfg.extraUser.homeFiles;
            };
          })
        ];
      };
    };

    # systemd-machine-id-commit.service would fail, but it is not relevant
    # in this specific setup for a persistent machine-id so we disable it
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    # change default systemd-machine-id-commit service to commit the transient ID to the persistent volume instead
    systemd.services.systemd-machine-id-commit = {
      unitConfig.ConditionPathIsMountPoint = [
        "/persist/etc/machine-id"
      ];
      serviceConfig.ExecStart = [
        "systemd-machine-id-setup --commit --root /persist"
      ];
    };

    # Create some directories with custom permissions.
    #
    # In this configuration the path `/home/butz/.local` is not an immediate parent
    # of any persisted file, so it would be created with the systemd-tmpfiles default
    # ownership `root:root` and mode `0755`. This would mean that the user `butz`
    # could not create other files or directories inside `/home/butz/.local`.
    #
    # Therefore systemd-tmpfiles is used to prepare such directories with
    # appropriate permissions.
    #
    # Note that immediate parent directories of persisted files can also be
    # configured with ownership and permissions from the `parent` settings if
    # `configureParent = true` is set for the file.
    systemd.tmpfiles.settings.preservation =
      (builtins.foldl' lib.recursiveUpdate { }
        (map
          (username: {
            "/home/${username}/.config".d = { user = "${username}"; group = "users"; mode = "0755"; };
            "/home/${username}/.local".d = { user = "${username}"; group = "users"; mode = "0755"; };
            "/home/${username}/.local/share".d = { user = "${username}"; group = "users"; mode = "0755"; };
            "/home/${username}/.local/state".d = { user = "${username}"; group = "users"; mode = "0755"; };
          })
          users
        )
      );
  };
}
