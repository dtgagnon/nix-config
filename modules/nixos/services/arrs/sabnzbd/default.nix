{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.arrs.sabnzbd;
in
{
  # Module options configuration
  # Defines all user-configurable settings for the SABnzbd service
  options.${namespace}.services.arrs.sabnzbd = {
    enable = mkBoolOpt false "Enable the sabnzbd service";
    user = mkOpt types.str "usenet" "The user that the sabnzbd will run as";
    group = mkOpt types.str "media" "The group that sabnzbd belongs to";

    stateDir = mkOpt types.path "${config.spirenix.services.arrs.dataDir}/sabnzbd" "Directory for Sabnzbd state";
    package = mkOpt types.package pkgs.sabnzbd "The package to use for SABnzbd";
    guiPort = mkOpt types.port 8081 "The port that SABnzbd's GUI will listen on for incomming connections.";
    openFirewall = mkBoolOpt false "Open firewall for SABnzbd";
    whitelistHostnames = mkOpt (types.listOf types.str) [ config.networking.hostName ] "A list of hostnames that are allowed to connect to SABnzbd";
    whitelistRanges = mkOpt (types.listOf types.str) [ "100.100.0.0/16" ] "A list of IP ranges that are allowed to connect to SABnzbd";
  };

  config =
    let
      # Target location for the SABnzbd configuration file
      ini-file-target = "${cfg.stateDir}/sabnzbd.ini";

      # Helper function to safely concatenate strings with commas
      # Only adds commas if the input list is non-empty
      concatStringsCommaIfExists = with lib.strings;
        stringList: (
          optionalString (builtins.length stringList > 0) (
            concatStringsSep "," stringList
          )
        );

      # Base configuration for SABnzbd
      # Contains all the default settings that will be written to the INI file
      user-configs = {
        misc = {
          # Dynamic host binding based on firewall settings
          host =
            if cfg.openFirewall
            then "0.0.0.0"  # Listen on all interfaces if firewall is open
            else "127.0.0.1"; # Listen only on localhost if firewall is closed
          port = cfg.guiPort;
          download_dir = "${config.spirenix.services.arrs.mediaDir}/downloads/usenet/.incomplete";
          complete_dir = "${config.spirenix.services.arrs.mediaDir}/downloads/usenet/complete";
          dirscan_dir = "${config.spirenix.services.arrs.mediaDir}/usenet/watch";
          # host_whitelist = concatStringsCommaIfExists cfg.whitelistHostnames;
          local_ranges = concatStringsCommaIfExists cfg.whitelistRanges;
          permissions = "775";
        };
        "servers] [[newshosting]" = {
          username = "cat ${config.sops.secrets."newshosting/username".path}";
          password = "cat ${config.sops.secrets."newshosting/password".path}";
          enable = 1;
          name = "newshosting";
          fillserver = 0;
          connections = 100;
          ssl = 1;
          host = "news.newshosting.com";
          timeout = 60;
          displayname = "Newshosting";
          port = 563;
          retention = 0;
        };
        logging = {
          log_level = 1;
          log_size = 5242880;
          enable_cherrypy_logging = 0;
          log_backups = 5;
        };
        cleanup = {
          enable_duplicate_detection = 1;
          enable_meta_duplicate_detection = 0;
          clean_up_download_dir = 1;
        };

      };

      # Creates the initial INI file from our user-configs
      ini-base-config-file = pkgs.writeTextFile {
        name = "base-config.ini";
        text = lib.generators.toINI { } user-configs;
      };

      # Script to ensure proper file permissions on the config file
      # Sets ownership to usenet:media and restrictive permissions
      fix-config-permissions-script = pkgs.writeShellApplication {
        name = "sabnzbd-fix-config-permissions";
        runtimeInputs = with pkgs; [ util-linux ];
        text = ''
          if [ ! -f ${ini-file-target} ]; then
            echo 'FAILURE: cannot change permissions of ${ini-file-target}, file does not exist'
            exit 1
          fi

          chmod 600 ${ini-file-target}
          chown usenet:media ${ini-file-target}
        '';
      };

      # Transforms the Nix config structure into Python dictionary assignments
      # Used to update the config file at runtime
      user-configs-to-python-list = with lib;
        attrsets.collect (f: !builtins.isAttrs f) (
          attrsets.mapAttrsRecursive
            (
              path: value:
                "sab_config_map['"
                + (lib.strings.concatStringsSep "']['" path)
                + "'] = '"
                + (builtins.toString value)
                + "'"
            )
            user-configs
        );

      # Script that applies the configuration at runtime
      # Uses ConfigObj to safely modify the INI file
      apply-user-configs-script = pkgs.writers.writePython3Bin "sabnzbd-set-user-values"
        {
          libraries = [ pkgs.python3Packages.configobj ];
        } ''
        # flake8: noqa
        from pathlib import Path
        from configobj import ConfigObj

        sab_config_path = Path("${ini-file-target}")
        if not sab_config_path.is_file() or sab_config_path.suffix != ".ini":
            raise Exception(f"{sab_config_path} is not a valid config file path.")

        sab_config_map = ConfigObj(str(sab_config_path))

        ${lib.strings.concatStringsSep "\n" user-configs-to-python-list}

        sab_config_map.write()
      '';
    in
    mkIf cfg.enable {
      # System user and group configuration
      users = {
        groups.${cfg.group} = { };
        users.${cfg.user} = {
          isSystemUser = true;
          group = "${cfg.group}";
        };
      };

      # Directory structure setup
      # Creates all necessary directories with appropriate permissions
      systemd.tmpfiles.rules = [
        # Base state directory
        "d '${cfg.stateDir}' 0700 usenet media - -"
        # Initial config file
        "C ${cfg.stateDir}/sabnzbd.ini - - - - ${ini-base-config-file}"

        # Media directory structure
        # All directories owned by usenet:media with appropriate permissions
        "d '${config.spirenix.services.arrs.mediaDir}/usenet'             0755 usenet media - -"
        "d '${config.spirenix.services.arrs.mediaDir}/usenet/.incomplete' 0755 usenet media - -"
        "d '${config.spirenix.services.arrs.mediaDir}/usenet/.watch'      0755 usenet media - -"
        "d '${config.spirenix.services.arrs.mediaDir}/usenet/manual'      0775 usenet media - -"
        "d '${config.spirenix.services.arrs.mediaDir}/usenet/liadarr'     0775 usenet media - -"
        "d '${config.spirenix.services.arrs.mediaDir}/usenet/radarr'      0775 usenet media - -"
        "d '${config.spirenix.services.arrs.mediaDir}/usenet/sonarr'      0775 usenet media - -"
      ];

      # Main service configuration
      services.sabnzbd = {
        enable = true;
        package = cfg.package;
        user = "${cfg.user}";
        group = "${cfg.group}";
        configFile = "${cfg.stateDir}/sabnzbd.ini";
      };

      # Firewall configuration
      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.guiPort ];

      # Service runtime configuration
      # Includes startup scripts and service behavior settings
      systemd.services.sabnzbd.serviceConfig = {
        ExecStartPre = lib.mkBefore [
          ("+" + fix-config-permissions-script + "/bin/sabnzbd-fix-config-permissions")
          (apply-user-configs-script + "/bin/sabnzbd-set-user-values")
        ];
        Restart = "on-failure";
        StartLimitBurst = 5;
      };

      # Secrets management
      # Configures secure storage for sensitive credentials
      sops.secrets = {
        "newshosting/username".owner = "${cfg.user}";
        "newshosting/password".owner = "${cfg.user}";
      };
    };
}
