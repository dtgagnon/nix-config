{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.firefox;
in
{
  options.${namespace}.apps.firefox = {
    enable = mkBoolOpt false "Enable firefox web browser";
  };
  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      # enableGnomeExtensions = false;
      # nativeMessagingHosts = [ ];
      # policies = [ ];
      profiles.${config.${namespace}.user.name} = {
        id = 0;
        name = config.${namespace}.user.name;
        settings = {
          "browser.aboutwelcome.enabled" = false;
          "browser.meta_refresh_when_inactive.disabled" = true;
          "browser.startup.homepage" = "https://duckduckgo.com";
          "browser.bookmarks.showMobileBookmarks" = true;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.aboutConfig.showWarning" = false;
          "browser.ssb.enabled" = true;
          "browser.cache.disk.enable" = false;
        };
      };
    };

    home.sessionVariables.BROWSER = "firefox";

    ${namespace}.home.persistHomeDirs = [
      ".mozilla"
      ".cache/mozilla"
    ];
  };
}
