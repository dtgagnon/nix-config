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
  options.${namespace}.system.preservation = with types; {
    enable = mkBoolOpt false "Enable the preservation impermanence framework";
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

        # System directories
        directories = [
          "/etc/secureboot"
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
        ]
        # ++ lib.optional config.services.ollama.enable "/var/lib/ollama"
        # ++ lib.optional config.${namespace}.services.llama-cpp.enable "/var/lib/llama-cpp"
        ++ cfg.extraSysDirs;

        # System files
        files = [
          { file = "/etc/machine-id"; inInitrd = true; how = "symlink"; configureParent = true; }
          { file = "/etc/ssh/ssh_host_ed25519_key"; mode = "0600"; how = "symlink"; createLinkTarget = true; }
          { file = "/etc/ssh/ssh_host_ed25519_key.pub"; mode = "0644"; how = "symlink"; createLinkTarget = true; }
          "/var/lib/usbguard/rules.conf"

          # Symlink only; use createLinkTarget = true to also create the target file
          { file = "/var/lib/systemd/random-seed"; how = "symlink"; inInitrd = true; configureParent = true; }
        ] ++ cfg.extraSysFiles;

        # User files (ownership implied)
        users = mkMerge [
          # Applied to all users
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

          # Per-user additions
          {
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
                ".local/share/keyrings"
                ".local/share/rofi"
                ".local/share/zoxide"
                # TODO: evaluate if needed
                ".claude"
                { directory = ".gnupg"; mode = "0700"; }
                ".icons"
                ".thunderbird"
                ".vscode-oss"
                "vfio-vm-info"
              ] ++ cfg.extraHomeDirs;
              files = [ ".claude.json" ] ++ cfg.extraHomeFiles;
            };
            root = {
              home = "/root"; # non-standard home path
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

    # Not needed with persistent machine-id
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    # Commit transient ID to persistent volume
    systemd.services.systemd-machine-id-commit = {
      unitConfig.ConditionPathIsMountPoint = [
        "/persist/etc/machine-id"
      ];
      serviceConfig.ExecStart = [
        "systemd-machine-id-setup --commit --root /persist"
      ];
    };

    # Pre-create intermediate directories with correct ownership (otherwise tmpfiles defaults to root:root 0755).
    # Note: immediate parents of persisted files can use `configureParent = true` instead.
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
