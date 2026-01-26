{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.thunderbird;
  username = config.${namespace}.user.name;

  # Wrapper script that waits for proton-bridge before starting Thunderbird
  # This prevents the login failure when Thunderbird starts before proton-bridge is ready
  thunderbird-wait = pkgs.writeShellScript "thunderbird-wait" ''
    # Wait for protonmail-bridge service to be active (max 60s)
    timeout=60
    while ! ${pkgs.systemd}/bin/systemctl --user is-active protonmail-bridge.service >/dev/null 2>&1; do
      sleep 1
      timeout=$((timeout - 1))
      if [ $timeout -le 0 ]; then
        echo "Warning: protonmail-bridge service not active after 60s, starting Thunderbird anyway"
        break
      fi
    done

    # Wait for IMAP port to be listening (max 30s after service is active)
    timeout=30
    while ! ${lib.getExe pkgs.netcat} -z 127.0.0.1 1143 2>/dev/null; do
      sleep 1
      timeout=$((timeout - 1))
      if [ $timeout -le 0 ]; then
        echo "Warning: proton-bridge IMAP port not ready after 30s, starting Thunderbird anyway"
        break
      fi
    done

    exec ${lib.getExe pkgs.thunderbird}
  '';


  birdtrayConfig = {
    # General
    "common/notificationfont" = "DejaVu Sans";
    "common/notificationfontweight" = 0;
    "common/defaultcolor" = "#0000FF";
    "common/bordercolor" = "#000000";
    "common/borderwidth" = 0;
    "common/blinkspeed" = 0;
    "common/showunreademailcount" = true;

    # Monitoring
    # NOTE: Thunderbird uses Maildir storage in ~/Mail/ (converted from mbox 2026-01-05)
    # All accounts use maildirstore format with email addresses as directory names
    # Structure: ~/Mail/<email-address>/<folder>/cur/ (messages) and .msf (index)
    accounts = [
      # Main Inboxes
      { path = "/home/${username}/Mail/gagnon.derek@gmail.com/INBOX.msf"; color = "#9CAF88"; } # Personal Gmail
      { path = "/home/${username}/Mail/dgagnon@awrightpath.net/INBOX.msf"; color = "#FBCEB1"; } # Awrightpath
      { path = "/home/${username}/Mail/dgagnon@stsdiesel.com/INBOX.msf"; color = "#00008B"; } # STSDiesel
      { path = "/home/${username}/Mail/gagnon.derek@protonmail.com/INBOX.msf"; color = "#69558A"; } # Proton
      { path = "/home/${username}/Mail/gagnon.derek@protonmail.com/Folders.DTG Engineering.msf"; color = "#4682B4"; }
      { path = "/home/${username}/Mail/gagnon.derek@protonmail.com/Folders.DTG Engineering.Banking.msf"; color = "#4682B4"; }
      { path = "/home/${username}/Mail/gagnon.derek@protonmail.com/Folders.DTG Engineering.catch-all.msf"; color = "#4682B4"; }
      { path = "/home/${username}/Mail/gagnon.derek@protonmail.com/Folders.DTG Engineering.Regulatory Affairs.msf"; color = "#4682B4"; }
      { path = "/home/${username}/Mail/gagnon.derek@protonmail.com/Folders.DTG Engineering.Rent.msf"; color = "#4682B4"; }
      { path = "/home/${username}/Mail/gagnon.derek@protonmail.com/Folders.DTG Engineering.Shipping.msf"; color = "#4682B4"; }
    ];
    "common/allowsuppressingunread" = false;
    "common/ignoreStartUnreadCount" = false;
    "common/forceIgnoreUnreadEmailsOnMinimize" = false;
    "common/ignoreShowUnreadCount" = false;
    "advanced/runProcessOnChange" = "";

    # Hiding
    "common/launchthunderbird" = true;
    "common/launchthunderbirddelay" = 1;
    "common/startClosedThunderbird" = true;
    "common/exitthunderbirdonquit" = true;
    "common/showhidethunderbird" = false; # doesn't work on wayland
    "common/hidewhenminimized" = true;
    "common/monitorthunderbirdwindow" = false; # doesn't work on wayland
    "common/restartthunderbird" = false;
    "common/hidewhenrestarted" = false;
    "common/hidewhenstarted" = false;
    "common/hideWhenStartedManually" = false;

    # New Email
    "common/newemailEnabled" = false;

    # Advanced
    "advanced/tbcmdline" = [ "${pkgs.thunderbird}/bin/thunderbird" ];
    "advanced/tbwindowmatch" = [ "thunderbird" ];
    "advanced/notificationfontminsize" = 1;
    "advanced/blinkingusealpha" = false;
    "advanced/ignoreNetWMhints" = false;
    "advanced/unreadopacitylevel" = 0.0;
    "advanced/onlyShowIconOnUnreadMessages" = false;
    "advanced/updateOnStartup" = false;
    "advanced/forcedRereadInterval" = 1;
    "advanced/watchfiletimeout" = 1000;

    # Other/non-GUI
    "advanced/tbprocessname" = ".thunderbird-wr"; # Needed for NixOS -- process isn't aligned with birdtray
  };
in
{
  options.${namespace}.apps.thunderbird = {
    enable = mkBoolOpt false "Enable Thunderbird email client";
  };

  config = mkIf cfg.enable {
    #NOTE: Disabling the home-manager module for now since it interferes with the dynamic setting changes on-going currently - 11/10/2025
    home = {
      sessionVariables.MAIL_CLIENT = "thunderbird";
      packages = [
        pkgs.thunderbird
        pkgs.notmuch
        pkgs.mblaze  # Maildir utilities
        pkgs.msmtp   # SMTP sending
        # pkgs.birdtray
      ];
    };

    # Notmuch email indexing and search for LLM agent access
    # Maildir storage: ~/Mail/ (converted from mbox 2026-01-05)
    # All accounts use Maildir format with email addresses as directory names
    programs.notmuch = {
      enable = true;
      new = {
        tags = [ "new" "inbox" ];
        ignore = [ ".msf" ".dat" "tmp/" ];
      };
      search = {
        excludeTags = [ "deleted" "spam" "trash" ];
      };
      maildir = {
        synchronizeFlags = true;
      };
      hooks = {
        # Auto-tag emails by account on initial indexing
        postNew = ''
          # Tag by account based on path
          notmuch tag +gmail -- path:gagnon.derek@gmail.com/** and tag:new
          notmuch tag +proton -- path:gagnon.derek@protonmail.com/** and tag:new
          notmuch tag +awrightpath -- path:dgagnon@awrightpath.net/** and tag:new
          notmuch tag +stsdiesel -- path:dgagnon@stsdiesel.com/** and tag:new
          notmuch tag +local -- path:local/** and tag:new

          # Remove 'new' tag after processing
          notmuch tag -new -- tag:new
        '';
      };
      extraConfig = {
        database = {
          path = "${config.home.homeDirectory}/Mail";
        };
        user = {
          name = "Derek Gagnon";
          primary_email = "gagnon.derek@gmail.com";
          other_email = "gagnon.derek@protonmail.com;dgagnon@awrightpath.net;dgagnon@stsdiesel.com";
        };
      };
    };

    spirenix.desktop.hyprland.extraExec = [ "${thunderbird-wait}" ];
    # spirenix.desktop.addons.sysbar.sysTrayApps = [ "birdtray" ];
    # xdg.configFile."birdtray-config.json".text = builtins.toJSON birdtrayConfig;
  };
}
