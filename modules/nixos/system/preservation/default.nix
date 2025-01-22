{ lib
, pkgs
, config
, namespace
, ...
}:
let 
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.spirenix.system.preservation;

  username = config.${namespace}.user.name;
in
{
  options.${namespace}.system.preservation = {
    enable = mkBoolOpt false "Enable the preservation impermanence framework";
    extraUser = mkOpt types.str "" "Declare additional users";
      homeDirs = mkOpt (types.listOf types.str) [ ] "Declare extra user home directories to persist";
      homeFiles = mkOpt (types.listOf types.str) [ ] "Declare extra user home files to persist";
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
          "/etc/greetd"
          "/var/lib/bluetooth"
          "/var/lib/fprint"
          "/var/lib/fwupd"
          "/var/lib/libvirt"
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
          { file = "/etc/machine-id"; inInitrd = true; }
          { file = "/etc/ssh/ssh_host_ed25519_key"; how = "symlink"; configureParent = true; }
          "/var/lib/usbguard/rules.conf"

          # creates a symlink on the volatile root
          # creates an empty directory on the persistent volume, i.e. /persistent/var/lib/systemd
          # does not create an empty file at the symlink's target (would require `createLinkTarget = true`)
          { file = "/var/lib/systemd/random-seed"; how = "symlink"; inInitrd = true; configureParent = true; }
        ] ++ cfg.extraSysFiles;

        # preserve user-specific files, implies ownership
        users = {
          ${username} = {
            directories = [
              { directory = ".ssh"; mode = "0700"; }
              "Apps"
              "nix-config"
              ".config/github-copilot"
              ".config/obsidian"
              ".config/syncthing"
              ".config/VSCodium"
              ".local/share/direnv"
              ".local/share/zoxide"
              ".local/state/nix"
              ".local/state/nvim"
              ".local/state/syncthing"
              ".local/state/wireplumber"
              ".codeium"
              ".mozilla"
              ".zen"
            ] ++ cfg.extraHomeDirs;
            files = [
              ".histfile"
            ] ++ cfg.extraHomeFiles;
          };
          ${cfg.extraUser} = {
            directories = [ ] ++ cfg.extraUser.homeDirs;
            files = [ ] ++ cfg.extraUser.homeFiles;
          };
          root = {
            # specify user home when it is not `/home/${user}`
            home = "/root";
            directories = [
              { directory = ".ssh"; mode = "0700"; }
            ];
          };
        };
      };
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
    systemd.tmpfiles.settings.preservation = {
      "/home/${username}/.config".d = { user = "${username}"; group = "users"; mode = "0755"; };
      "/home/${username}/.local".d = { user = "${username}"; group = "users"; mode = "0755"; };
      "/home/${username}/.local/share".d = { user = "${username}"; group = "users"; mode = "0755"; };
      "/home/${username}/.local/state".d = { user = "${username}"; group = "users"; mode = "0755"; };
    };
  };
}