# Zen Browser search engine configuration
{ pkgs }:
{
  default = "Google AI";
  privateDefault = "ddg";
  force = true;
  engines = {
    "Google AI" = {
      urls = [{ template = "https://www.google.com/search?q={searchTerms}&udm=50"; }];
      definedAliases = [ ".g" ];
    };
    "google" = {
      urls = [{ template = "https://www.google.com/search?q={searchTerms}"; }];
      definedAliases = [ ".gg" ];
    };
    "nixpkgs" = {
      urls = [{ template = "https://github.com/search?q=repo:NixOS/nixpkgs {searchTerms}&type=code"; }];
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = [ ".np" ];
    };
    "Nix Options" = {
      urls = [{ template = "https://search.nixos.org/options?query={searchTerms}"; }];
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = [ ".no" ];
    };
    "NixOS Wiki" = {
      urls = [{ template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; }];
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = [ ".nw" ];
    };
    "home-manager" = {
      urls = [{ template = "https://github.com/search?q=repo:nix-community/home-manager {searchTerms}&type=code"; }];
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = [ ".hm" ];
    };
    "GitHub" = {
      urls = [{ template = "https://github.com/search?q={searchTerms}&type=code"; }];
      definedAliases = [ ".gh" ];
    };
    youtube = {
      urls = [{ template = "https://www.youtube.com/results?search_query={searchTerms}"; }];
      definedAliases = [ ".yt" ];
    };
    # Disable sponsored/unwanted engines
    bing.metaData.hidden = true;
    amazondotcom-us.metaData.hidden = true;
    ebay.metaData.hidden = true;
    google.metaData.hidden = true; # Hide default Google (using custom ones)
    wikipedia.metaData.alias = ".wiki";
  };
}
