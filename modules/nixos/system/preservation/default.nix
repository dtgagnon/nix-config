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
in
{
  options.${namespace}.system.preservation = {
    enable = mkBoolOpt false "Enable the preservation impermanence framework";
    extraUser = {
      user = mkOpt types.str "" "Declare additional users";
      homeDirs = mkOpt (types.listOf types.str) [ ] "Declare extra user home directories to persist";
      homeFiles = mkOpt (types.listOf types.str) [ ] "Declare extra user home files to persist";
    };
    extraSysDirs = mkOpt (types.listOf types.str) [ ] "Declare additional system directories to persist";
    extraSysFiles = mkOpt (types.listOf types.str) [ ] "Declare additional system files to persist";
    extraHomeDirs = mkOpt (types.listOf types.str) [ ] "Declare additional user home directories to persist";
    extraHomeFiles = mkOpt (types.listOf types.str) [ ] "Declare additional user home files to persist";
  };

  config = mkIf cfg.enable {
    fileSystems."/persist".neededForBoot = true;

    preservation = {
      enable = true;
      preserveAt."/persist" = {

        # Preserve system directories
        directories = [
          "/etc/secureboot"
          "/etc/ssh"
          "/etc/greetd"
          "/var/lib/bluetooth"
          "/var/lib/fprint"
          "/var/lib/fwupd"
          { directory = "/var/lib/libvirt"; user = "qemu-libvirtd"; group = "qemu-libvirtd"; mode = "0750"; }
          { directory = "/var/lib/qemu"; user = "qemu-libvirtd"; group = "qemu-libvirtd"; mode = "0750"; }
          "/var/lib/power-profiles-daemon"
          "/var/lib/systemd/coredump"
          "/var/lib/systemd/rfkill"
          "/var/lib/systemd/timers"
          "/var/log"
          { directory = "/var/lib/nixos"; inInitrd = true; }
          { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "0754"; }
        ] ++ cfg.extraSysDirs;

        # preserve system files
        files = [
          { file = "/etc/machine-id"; inInitrd = true; how = "symlink"; configureParent = true; }
          { file = "/etc/ssh/ssh_host_ed25519_key"; mode = "0600"; how = "symlink"; configureParent = true; }
          { file = "/etc/ssh/ssh_host_ed25519_key.pub"; mode = "0644"; how = "symlink"; configureParent = true; }
          "/var/lib/usbguard/rules.conf"

          # creates a symlink on the volatile root
          # creates an empty directory on the persistent volume, i.e. /persistent/var/lib/systemd
          # does not create an empty file at the symlink's target (would require `createLinkTarget = true`)
          { file = "/var/lib/systemd/random-seed"; how = "symlink"; inInitrd = true; configureParent = true; }
        ] ++ cfg.extraSysFiles;

        # preserve user-specific files, implies ownership
        users = mkMerge [
          # Persisting directories and files to apply to all users.
          (builtins.foldl' lib.recursiveUpdate { }
            (map
              (user: {
                ${user} = {
                  directories = [
                    "Apps"
                    "Documents"
                    "Downloads"
                    "Games"
                    "Music"
                    "Pictures"
                    "Sync"
                    "Videos"
                    ".config/syncthing"
                    ".local/state/nix"
                    ".local/state/nvim"
                    ".local/state/syncthing"
                    ".local/state/wireplumber"
                    { directory = ".pki"; mode = "0700"; }
                    { directory = ".ssh"; mode = "0700"; }
                    { directory = ".zen"; mode = "0700"; }
                  ] ++ cfg.extraHomeDirs;
                  files = [
                    ".histfile"
                  ] ++ cfg.extraHomeFiles;
                };
              })
              (snowfallHostUserList host)
            )
          )

          # Additional persisting directories and files to be defined for each user.
          {
            admin = {
              directories = [
                ".local/share/direnv"
                ".local/share/zoxide"
              ] ++ cfg.extraHomeDirs;
              files = [ ] ++ cfg.extraHomeFiles;
            };
            dtgagnon = {
              directories = [
                "myVMs"
                "nix-config"
                "proj"
                ".config"
                ".config/discord"
                ".config/hypr"
                ".config/obsidian"
                ".config/rofi"
                ".config/syncthing"
                ".config/VSCodium"
                ".local/share/activitywatch"
                ".local/share/bottles"
                ".local/share/direnv"
                # ".local/share/fish"
                ".local/share/keyrings"
                ".local/share/rofi"
                ".local/share/zoxide"
                ## Testing the below if I want to keep them
                ".claude"
                { directory = ".gnupg"; mode = "0700"; }
                ".icons"
                ".vscode-oss"
                "vm-share"
                "vfio-vm-info"
              ] ++ cfg.extraHomeDirs;
              files = [ ".claude.json" ] ++ cfg.extraHomeFiles;
            };
            root = {
              # specify user home when it is not `/home/${user}`
              home = "/root";
              directories = [
                { directory = ".ssh"; mode = "0700"; }
              ];
            };
            ${cfg.extraUser.user} = {
              directories = [ ] ++ cfg.extraUser.homeDirs;
              files = [ ] ++ cfg.extraUser.homeFiles;
            };
          }
        ];
      };
    };

    # systemd-machine-id-commit.service would fail, but it is not relevant
    # in this specific setup for a persistent machine-id so we disable it
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    # change default systemd-machine-id-commit service to commit the transient ID to the persistent volume instead
    systemd.services.systemd-machine-id-commit = {
      unitConfig.ConditionPathIsMountPoint = [
        ""
        "/persistent/etc/machine-id"
      ];
      serviceConfig.ExecStart = [
        ""
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
          (snowfallHostUserList host)
        )
      );
  };
}
