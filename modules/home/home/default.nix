{
  lib,
  config,
  options,
  namespace,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf mkAliasDefinitions types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.home;
in
{
  options.${namespace}.home = {
    enable = mkBoolOpt false "Enable home-manager";

    persistHomeDirs =
      mkOpt (types.listOf types.str) [ ]
        "Declare additional user home directories to persist";
    persistHomeFiles =
      mkOpt (types.listOf types.str) [ ]
        "Declare additional user home files to persist";
  };

  config = mkIf cfg.enable {
    programs.home-manager.enable = true;
    home.stateVersion = lib.mkDefault (osConfig.system.stateVersion or "24.05");

    # spirenix.home = {
    #   persistHomeDirs = [ "dir1" "dir2" "testdir3" ];
    #   persistHomeFiles = cfg.persistHomeFiles;
    # };

    # home.persistence."/persist/home/${config.spirenix.user.name}" = {
    #   directories = [
    #     "Documents"
    #     "Downloads"
    #     "Music"
    #     "Pictures"
    #     "Videos"
    #     ".ssh"
    #     ".config"
    #     ".cache"
    #     ".local"
    #     "nix-config"
    #   ] ++ cfg.persistHomeDirs;
    #   files = [
    #     ".screenrc"
    #   ] ++ cfg.persistHomeFiles;
    #   allowOther = true;
    # };
  };
}
