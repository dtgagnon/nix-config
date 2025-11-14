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
    #NOTE: Monitored folders are typically at: ~/.thunderbird/<profile>/ImapMail/<server>/<folder>.msf || ~/.thunderbird/<profile>/Mail/<account>/<folder>.msf for local folders
    accounts = [
      # Main Inboxes
      { path = "/home/${username}/.thunderbird/${username}/ImapMail/imap.gmail.com/INBOX.msf"; color = "#9CAF88"; } # Personal Gmail
      { path = "/home/${username}/.thunderbird/${username}/ImapMail/imap.gmail-1.com/INBOX.msf"; color = "#FBCEB1"; } # Awrightpath
      { path = "/home/${username}/.thunderbird/${username}/ImapMail/imap.gmail-2.com/INBOX.msf"; color = "#00008B"; } # STSDiesel
      { path = "/home/${username}/.thunderbird/${username}/ImapMail/127.0.0.1/INBOX.msf"; color = "#69558A"; } # Proton
      { path = "/home/${username}/.thunderbird/${username}/ImapMail/127.0.0.1/Folders.sbd/DTG Engineering.msf"; color = "#4682B4"; }
      { path = "/home/${username}/.thunderbird/${username}/ImapMail/127.0.0.1/Folders.sbd/DTG Engineering.sbd/Banking.msf"; color = "#4682B4"; }
      { path = "/home/${username}/.thunderbird/${username}/ImapMail/127.0.0.1/Folders.sbd/DTG Engineering.sbd/catch-all.msf"; color = "#4682B4"; }
      { path = "/home/${username}/.thunderbird/${username}/ImapMail/127.0.0.1/Folders.sbd/DTG Engineering.sbd/Regulatory Affairs.msf"; color = "#4682B4"; }
      { path = "/home/${username}/.thunderbird/${username}/ImapMail/127.0.0.1/Folders.sbd/DTG Engineering.sbd/Rent.msf"; color = "#4682B4"; }
      { path = "/home/${username}/.thunderbird/${username}/ImapMail/127.0.0.1/Folders.sbd/DTG Engineering.sbd/Shipping.msf"; color = "#4682B4"; }
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
        # pkgs.birdtray
      ];
    };

    spirenix.desktop.hyprland.extraExec = [ "thunderbird" ];
    # spirenix.desktop.addons.sysbar.sysTrayApps = [ "birdtray" ];
    # xdg.configFile."birdtray-config.json".text = builtins.toJSON birdtrayConfig;
  };
}
