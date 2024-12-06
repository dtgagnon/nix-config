{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.syncthing;
in
{
  options.${namespace}.services.syncthing = {
    enable = mkBoolOpt false "Enable Syncthing service";
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      passwordFile = config.sops.secrets."syncthing-webui-password".path;
      guiAddress = "127.0.0.1:8384";
      
      # key = null;   # Path to the key.pem file, which will be copied into Syncthing's config directory
      tray.enable = true;
      overrideDevices = false;    # Delete the devices not configured via the devices option
      overrideFolders = false;    # Delete the folders not configured via the folders option
      # extraOptions = [ #   "extra CLI args to pass as a list of strings" # ];

      settings = {
        options = {
          limitBandwidthInLan = false;    # Apply bandwidth limits to devices in the same broadcast domain as the local device
          localAnnounceEnabled = true;    # Send announcements to the local LAN, also use announcements to find other devices
          localAnnouncePort = 21027;
          maxFolderConcurrency = 0;   # This option controls how many folders may concurrently be in I/O-intensive operations
          relaysEnabled = true;
          urAccepted = -1;
        };

        # devices = {
        #   "<name>" = {
        #     autoAcceptFolders = "true or false";
        #     id = "";   # The ID of the device
        #     name = "";   # The name of the device
        #   };
        # };

        # folders = {
        #   "<name>" = {
        #     enable = true;    # Whether to share this folder
        #     id = "";    # The ID of the folder
        #     label = "";   # The label of the folder
        #     path = "";    # The path to the folder which should be shared
        #     type = "";    # Controls how the folder is handled by Syncthing
        #     devices = [ ];    # The devices this folder should be shared with
        #     copyOwnershipFromParent = false;    # On Unix systems, tries to copy file/folder ownership from the parent directory
        #     versioning = {
        #       type = "";    # The type of versioning
        #     };
        #   };
        # };
      };
    };

    # spirenix.user.home.persistHomeDirs = [
    #   ".config/syncthing"
    #   ".local/state/syncthing"
    # ];
  };
}