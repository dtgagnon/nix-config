# Zen Browser user.js settings
{
  # Base settings applied to all users
  base = {
    # ─ General UI ─
    "browser.aboutConfig.showWarning" = false;
    "browser.ctrlTab.sortByRecentlyUsed" = true;
    "browser.bookmarks.defaultLocation" = "toolbar_____";

    # ─ Privacy & Security ─
    "dom.security.https_only_mode_ever_enabled" = true;
    "datareporting.usage.uploadEnabled" = false;

    # ─ Disable Sponsored Content ─
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.urlbar.suggest.quicksuggest.all" = false;
  };

  # Extended settings for power users (when profilePath is set)
  extended = {
    # ─ General UI ─
    "browser.tabs.inTitlebar" = 1;

    # ─ Homepage & New Tab ─
    "browser.startup.homepage" = "https://duckduckgo.com";
    "browser.newtabpage.enabled" = false;
    "browser.newtabpage.activity-stream.feeds.section.highlights" = true;

    # ─ AI Sidebar (Claude) ─
    "browser.ml.chat.enabled" = true;
    "browser.ml.chat.provider" = "https://claude.ai/new";
    "browser.ml.chat.sidebar" = true;
    "browser.ml.chat.page.footerBadge" = false;
    "browser.ml.chat.page.menuBadge" = false;
    "browser.ml.enable" = true;

    # ─ Privacy & Security (additional) ─
    "browser.safebrowsing.malware.enabled" = false;
    "browser.safebrowsing.phishing.enabled" = false;

    # ─ URL Bar ─
    "browser.urlbar.placeholderName.private" = "DuckDuckGo";

    # ─ Forms & Autofill (disabled - using Proton Pass) ─
    "extensions.formautofill.addresses.enabled" = false;
    "extensions.formautofill.creditCards.enabled" = false;
    "dom.forms.autocomplete.formautofill" = true;

    # ─ Developer Tools ─
    "devtools.cache.disabled" = true;
    "devtools.toolbox.host" = "window";
    "devtools.everOpened" = true;
    "devtools.netmonitor.persistlog" = true;

    # ─ Downloads ─
    "browser.download.autohideButton" = true;
    "browser.download.panel.shown" = true;

    # ─ Translations ─
    "browser.translations.alwaysTranslateLanguages" = "zh-Hans";
    "browser.translations.mostRecentTargetLanguages" = "en";

    # # ─ Zen UI ─
    # "zen.view.compact" = true;
    # "zen.view.compact.hide-toolbar" = true;
    # "zen.theme.accent-color" = "#aac7ff";
    # "zen.theme.color-prefs.colorful" = true;
    # "zen.urlbar.behavior" = "float";
    #
    # # ─ Zen Tab Management ─
    # "zen.pinned-tab-manager.restore-pinned-tabs-to-pinned-url" = true;
    # "zen.pinned-tab-manager.close-shortcut-behavior" = "reset-switch";
    # "zen.tab-unloader.timeout-minutes" = 15;
    #
    # # ─ Zen Workspaces ─
    # "zen.workspaces.separate-essentials" = false;
    # "zen.workspaces.show-icon-strip" = false;
    #
    # # ─ Tab Groups ─
    # "browser.tabs.groups.enabled" = true;
    # "browser.tabs.groups.smart.optin" = true;
    #
  };
}
