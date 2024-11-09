{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf optional types mkMerge;
  inherit (lib.${namespace}) enabled mkBoolOpt mkOpt;
  cfg = config.${namespace}.apps.firefox;
  defaultSettings = {
    "browser.aboutwelcome.enabled" = false;
    "browser.meta_refresh_when_inactive.disabled" = true;
    "browser.startup.homepage" = "https://duckduckgo.com";
    "browser.bookmarks.showMobileBookmarks" = true;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.aboutConfig.showWarning" = false;
    "browser.ssb.enabled" = true;
  };
in
{
  options.${namespace}.apps.firefox = with types; {
    enable = mkBoolOpt false "Whether or not to enable Firefox.";
    extraConfig = mkOpt str "" "Extra configuration for the user profile JS file.";
    userChrome = mkOpt str "" "Extra configuration for the user chrome CSS file.";
    settings = mkOpt attrs defaultSettings "Settings to apply to the profile.";
  };

  config = mkIf cfg.enable {
    spirenix.desktop.addons.firefox-nordic-theme = enabled;

    services.gnome.gnome-browser-connector.enable = config.${namespace}.desktop.gnome.enable;

    spirenix.home = {
      file = mkMerge [
        {
          ".mozilla/native-messaging-hosts/com.dannyvankooten.browserpass.json".source = "${pkgs.browserpass}/lib/mozilla/native-messaging-hosts/com.dannyvankooten.browserpass.json";
        }
        (mkIf config.${namespace}.desktop.gnome.enable {
          ".mozilla/native-messaging-hosts/org.gnome.chrome_gnome_shell.json".source = "${pkgs.chrome-gnome-shell}/lib/mozilla/native-messaging-hosts/org.gnome.chrome_gnome_shell.json";
        })
      ];

      extraOptions = {
        programs.firefox = {
          enable = true;
          # package = pkgs.firefox;

          nativeMessagingHosts = [
            pkgs.browserpass
          ] ++ optional config.${namespace}.desktop.gnome.enable pkgs.gnomeExtensions.gsconnect;

          profiles.${config.${namespace}.user.name} = {
            inherit (cfg) extraConfig userChrome settings;
            id = 0;
            name = config.${namespace}.user.name;
          };
        };
      };
    };
  };
}
