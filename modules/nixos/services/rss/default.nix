{
  lib,
  pkgs,
  config,
  inputs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkDefault types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.rss;

  secretsPath = toString inputs.nix-secrets;
  feedsFile = "${secretsPath}/rss-feeds.nix";
  importedFeeds = if builtins.pathExists feedsFile then import feedsFile else [ ];

  filterRuleType = types.submodule {
    options = {
      field = mkOpt (types.enum [
        "title"
        "description"
        "link"
        "any"
      ]) "any" "Feed entry field to match against";
      pattern = mkOpt types.str "" "Regex pattern to match (case-insensitive)";
    };
  };

  feedType = types.submodule {
    options = {
      url = mkOpt types.str "" "Feed URL";
      name = mkOpt types.str "" "Human-readable label for the feed";
      tags = mkOpt (types.listOf types.str) [ ] "Tags to apply on bookmarks created from this feed";
      filters = {
        include =
          mkOpt (types.listOf filterRuleType) [ ]
            "Item must match at least one include rule to be kept (if empty, all items pass)";
        exclude = mkOpt (types.listOf filterRuleType) [ ] "Item is rejected if any exclude rule matches";
      };
    };
  };

  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.feedparser
    ps.requests
  ]);

  configFile = pkgs.writeText "rss-filter-config.json" (
    builtins.toJSON {
      inherit (cfg) feeds;
      karakeep = {
        inherit (cfg.karakeep) enable serverAddr;
        apiKeyFile = cfg.karakeep.apiKeyFile;
      };
    }
  );

  scriptPath = ./rss-filter.py;
in
{
  options.${namespace}.services.rss = {
    enable = mkBoolOpt false "Enable RSS feed filter pipeline";

    interval = mkOpt types.str "15m" "How often to check feeds (systemd OnUnitActiveSec format)";

    feeds = mkOpt (types.listOf feedType) [ ] "List of feed definitions";

    karakeep = {
      enable = mkBoolOpt true "Forward matching items to Karakeep";
      serverAddr = mkOpt types.str "http://100.100.1.2:3000" "Karakeep API base URL";
      apiKeyFile = mkOpt types.str "" "Path to file containing Karakeep API key (sops-compatible)";
    };
  };

  config = mkIf cfg.enable {
    # Import feed definitions from nix-secrets and wire up sops API key path
    ${namespace}.services.rss = {
      feeds = mkDefault importedFeeds;
      karakeep.apiKeyFile = mkDefault config.sops.secrets."karakeep/api-key".path;
    };

    # Wire up sops secret for Karakeep API key
    sops.secrets."karakeep/api-key" = mkIf cfg.karakeep.enable { };

    systemd.services.rss-filter = {
      description = "RSS feed filter pipeline";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pythonEnv}/bin/python ${scriptPath} ${configFile}";
        DynamicUser = true;
        StateDirectory = "rss-filter";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
      }
      // lib.optionalAttrs (cfg.karakeep.enable && cfg.karakeep.apiKeyFile != "") {
        ReadOnlyPaths = [ cfg.karakeep.apiKeyFile ];
      };
    };

    systemd.timers.rss-filter = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = cfg.interval;
        RandomizedDelaySec = "1m";
      };
    };
  };
}
