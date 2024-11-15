{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.system.impermanence;
in
{
  options.${namespace}.system.impermanence = {
    enable = mkBoolOpt false "Enable impermanence";
    extraDirs = mkOpt (types.listOf types.str) [ ] "Declare additional directories to persist";
    extraFiles = mkOpt (types.listOf types.str) [ ] "Declare additional files to persist";
  };

  config = mkIf cfg.enable {
    fileSystems."/persist".neededForBoot = true;
    environment.persistence."/persist/system" = {
      hideMounts = true;
      directories = [
        "/etc/nixos"
        "/etc/NetworkManager/system-connections"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/log"
        { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "0760"; }
      ] ++ cfg.extraDirs;
      files = [
        "/etc/machine-id"
        { file = "/var/keys/secret_file"; parentDirectory = { mode = "0700"; }; }
      ] ++ cfg.extraFiles;
    };
  };
}
