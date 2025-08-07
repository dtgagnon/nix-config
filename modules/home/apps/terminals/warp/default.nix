{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.${namespace}.apps.terminals.warp;
in
{
  options.${namespace}.apps.terminals.warp = {
    enable = mkEnableOption "Whether or not to enable warp";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.warp-terminal ];
    # home.file.".config/warp-terminal/user_preferences.json".text = ''
    #   {
    #     "prefs": {
    #       "CustomSecretRegexList": "[{\"pattern\":\"\\\\b((25[0-5]|(2[0-4]|1\\\\d|[1-9]|)\\\\d)\\\\.?\\\\b){4}\\\\b\",\"name\":\"IPv4 Address\"},{\"pattern\":\"\\\\b((([0-9A-Fa-f]{1,4}:){1,6}:)|(([0-9A-Fa-f]{1,4}:){7}))([0-9A-Fa-f]{1,4})\\\\b\",\"name\":\"IPv6 Address\"},{\"pattern\":\"\\\\bxapp-[0-9]+-[A-Za-z0-9_]+-[0-9]+-[a-f0-9]+\\\\b\",\"name\":\"Slack App Token\"},{\"pattern\":\"\\\\b(\\\\+\\\\d{1,2}\\\\s)?\\\\(?\\\\d{3}\\\\)?[\\\\s.-]\\\\d{3}[\\\\s.-]\\\\d{4}\\\\b\",\"name\":\"Phone Number\"},{\"pattern\":\"\\\\b(AKIA|A3T|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{12,}\\\\b\",\"name\":\"AWS Access ID\"},{\"pattern\":\"\\\\b((([a-zA-z0-9]{2}[-:]){5}([a-zA-z0-9]{2}))|(([a-zA-z0-9]{2}:){5}([a-zA-z0-9]{2})))\\\\b\",\"name\":\"MAC Address\"},{\"pattern\":\"\\\\bAIza[0-9A-Za-z-_]{35}\\\\b\",\"name\":\"Google API Key\"},{\"pattern\":\"\\\\b[0-9]+-[0-9A-Za-z_]{32}\\\\.apps\\\\.googleusercontent\\\\.com\\\\b\",\"name\":\"Google OAuth ID\"},{\"pattern\":\"\\\\bghp_[A-Za-z0-9_]{36}\\\\b\",\"name\":\"GitHub Classic Personal Access Token\"},{\"pattern\":\"\\\\bgithub_pat_[A-Za-z0-9_]{82}\\\\b\",\"name\":\"GitHub Fine-Grained Personal Access Token\"},{\"pattern\":\"\\\\bgho_[A-Za-z0-9_]{36}\\\\b\",\"name\":\"GitHub OAuth Access Token\"},{\"pattern\":\"\\\\bghu_[A-Za-z0-9_]{36}\\\\b\",\"name\":\"GitHub User-to-Server Token\"},{\"pattern\":\"\\\\bghs_[A-Za-z0-9_]{36}\\\\b\",\"name\":\"GitHub Server-to-Server Token\"},{\"pattern\":\"\\\\b(?:r|s)k_(test|live)_[0-9a-zA-Z]{24}\\\\b\",\"name\":\"Stripe Key\"},{\"pattern\":\"\\\\b(ey[a-zA-z0-9_\\\\-=]{10,}\\\\.){2}[a-zA-z0-9_\\\\-=]{10,}\\\\b\",\"name\":\"JWT\"},{\"pattern\":\"\\\\bsk-[a-zA-Z0-9]{48}\\\\b\",\"name\":\"OpenAI API Key\"},{\"pattern\":\"\\\\bsk-ant-api\\\\d{0,2}-[a-zA-Z0-9\\\\-]{80,120}\\\\b\",\"name\":\"Anthropic API Key\"},{\"pattern\":\"\\\\bsk-[a-zA-Z0-9\\\\-]{10,100}\\\\b\",\"name\":\"Generic SK API Key\"}]",
    #       "InputAutodetectionBannerRemainingCount": "2",
    #       "AvailableLLMs": "{\"agent_mode\":{\"default_id\":\"auto\",\"choices\":[{\"display_name\":\"auto\",\"id\":\"auto\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":\"claude 4 sonnet\",\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"lite\",\"id\":\"warp-basic\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":\"basic model\",\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"claude 4 sonnet\",\"id\":\"claude-4-sonnet\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"claude 4 opus\",\"id\":\"claude-4-opus\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"claude 4.1 opus\",\"id\":\"claude-4.1-opus\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"gpt-4o\",\"id\":\"gpt-4o\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"gpt-4.1\",\"id\":\"gpt-4.1\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"o4-mini\",\"id\":\"o4-mini\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"o3\",\"id\":\"o3\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"gemini 2.5 pro\",\"id\":\"gemini-2.5-pro\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true}]},\"planning\":{\"default_id\":\"o3\",\"choices\":[{\"display_name\":\"lite\",\"id\":\"warp-basic\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":\"basic model\",\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"claude 4 opus\",\"id\":\"claude-4-opus\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"claude 4.1 opus\",\"id\":\"claude-4.1-opus\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"gpt-4.1\",\"id\":\"gpt-4.1\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"o4-mini\",\"id\":\"o4-mini\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"o3\",\"id\":\"o3\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true}]},\"coding\":{\"default_id\":\"auto\",\"choices\":[{\"display_name\":\"auto\",\"id\":\"auto\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":\"claude 4 sonnet\",\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"lite\",\"id\":\"warp-basic\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":\"basic model\",\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"claude 4 sonnet\",\"id\":\"claude-4-sonnet\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"claude 4 opus\",\"id\":\"claude-4-opus\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"claude 4.1 opus\",\"id\":\"claude-4.1-opus\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"gpt-4o\",\"id\":\"gpt-4o\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"gpt-4.1\",\"id\":\"gpt-4.1\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"o4-mini\",\"id\":\"o4-mini\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"o3\",\"id\":\"o3\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true},{\"display_name\":\"gemini 2.5 pro\",\"id\":\"gemini-2.5-pro\",\"usage_metadata\":{\"request_multiplier\":1},\"description\":null,\"disable_reason\":null,\"vision_supported\":true}]}}",
    #       "TelemetryBannerDismissed": "true",
    #       "AIRequestLimitInfo": "{\"limit\":150,\"num_requests_used_since_refresh\":0,\"next_refresh_time\":\"2025-09-05T19:24:01.504668Z\",\"is_unlimited\":false,\"request_limit_refresh_duration\":\"Monthly\",\"accepted_autosuggestions_limit\":999999,\"is_unlimited_autosuggestions\":true,\"accepted_autosuggestions_since_last_refresh\":0,\"is_unlimited_voice\":false,\"voice_request_limit\":10000,\"voice_token_limit\":30000,\"voice_requests_used_since_last_refresh\":0,\"voice_tokens_used_since_last_refresh\":0,\"is_unlimited_codebase_indices\":false,\"max_codebase_indices\":3,\"max_files_per_repo\":5000,\"embedding_generation_batch_size\":100}",
    #       "AIAssistantRequestLimitInfo": "{\"limit\":150,\"num_requests_used_since_refresh\":0,\"next_refresh_time\":\"2025-09-05T19:24:01.504668Z\",\"is_unlimited\":false,\"request_limit_refresh_duration\":\"Monthly\",\"accepted_autosuggestions_limit\":999999,\"is_unlimited_autosuggestions\":true,\"accepted_autosuggestions_since_last_refresh\":0,\"is_unlimited_voice\":false,\"voice_request_limit\":10000,\"voice_token_limit\":30000,\"voice_requests_used_since_last_refresh\":0,\"voice_tokens_used_since_last_refresh\":0,\"is_unlimited_codebase_indices\":false,\"max_codebase_indices\":3,\"max_files_per_repo\":5000,\"embedding_generation_batch_size\":100}",
    #       "InputAutodetectionBannerDismissed": "true",
    #       "MCPExecutionPath": "\"/home/dtgagnon/.config/carapace/bin:/run/wrappers/bin:/home/dtgagnon/.nix-profile/bin:/nix/profile/bin:/home/dtgagnon/.local/state/nix/profile/bin:/etc/profiles/per-user/dtgagnon/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/nix/store/sg9l4jqsannl2rpm8sqvw39ma5jqiwzs-util-linux-2.41-bin/bin:/nix/store/bxp00dzqzwjfbsi4d7r072r142i66zxp-newt-0.52.24/bin:/nix/store/qdv9ha7qkbc23d0bg6vh6gl9c7p7gnrw-libnotify-0.8.6/bin:/nix/store/lb33m49aslmvkx5l4xrkiy7m6nbh2kqf-bash-interactive-5.3p0/bin:/nix/store/wq3ivni0plh7g8xl3my8qr9llh4dy7q4-systemd-257.6/bin:/nix/store/5xzmz7vcglw8q023wvqm9sla2d1jggpl-python3-3.13.5-env/bin:/nix/store/kgb3dm7l3s7sy7a4bh93jm2z208rv4az-dmenu-5.3/bin:/nix/store/lv91pnk6dqvw0xmbi5irli7m6nikfr33-binutils-wrapper-2.44/bin:/nix/store/i6k7sx20pwq7x87nlkjz4dm725zcnpp4-hyprland-qtutils-0.1.4+date=2025-07-29_b308a81/bin:/nix/store/5h5758kspk2ir12dvwrgilmcizz617kh-pciutils-3.14.0/bin:/nix/store/43vw43b1km56y6idkzrbz5narkhlfca4-pkgconf-wrapper-2.4.3/bin:/nix/store/k75dxigqjiqbg7i9rfkmx4m9q4fpv6h5-kitty-0.42.2/bin:/nix/store/71zmb5blvs1w6fkiwayidzx8mbmqiyl7-imagemagick-7.1.2-0/bin:/nix/store/z1l05nn4xyaxv25f9pvi7bkmw6jmb48c-ncurses-6.5-dev/bin:/home/dtgagnon/.config/zsh/plugins/zsh-abbr:/home/dtgagnon/.config/zsh/plugins/zsh-nix-shell\"",
    #       "AIRequestQuotaInfoSetting": "{\"cycle_history\":[{\"end_date\":\"2025-09-05T19:24:01.504668Z\",\"was_quota_exceeded\":false,\"banner_state\":{\"dismissed\":false}}]}",
    #       "NewSessionShellOverride": "{\"Executable\":\"/nix/store/6lrbkxnpym1z8lqrrpg59bwnddxfdc52-zsh-5.9/bin/zsh\"}",
    #       "ExperimentId": "db2ec9b1-3488-48f4-b63c-e8013fff3e46",
    #       "HasAutoOpenedWelcomeFolder": "true",
    #       "NotebookFontSize": "14.0",
    #       "TelemetryEnabled": "false",
    #       "HideSecretsInBlockList": "true",
    #       "NextCommandSuggestionsUpgradeBannerNumTimesShownThisPeriod": "0",
    #       "ForceX11": "true",
    #       "ReceivedReferralTheme": "\"Inactive\"",
    #       "DidNonAnonymousUserLogIn": "true",
    #       "DidShowADELaunchModal": "true",
    #       "ChangelogVersions": "{\"v0.2025.07.23.08.12.stable_02\":true}",
    #       "FontSize": "13.0",
    #       "EnteredAgentModeNumTimes": "2",
    #       "InputBoxTypeSetting": "\"Universal\"",
    #       "SystemTheme": "true",
    #       "SafeModeEnabled": "true",
    #       "HasInitializedDefaultSecretRegexes": "true",
    #       "IsSettingsSyncEnabled": "true",
    #       "ShouldAddAgentModeChip": "false",
    #       "PreferredDispatchPlanningLLMId": "\"claude-4-opus\"",
    #       "WorkingDirectoryConfig": "{\"advanced_mode\":false,\"global\":{\"mode\":\"CustomDir\",\"custom_dir\":\"/home/dtgagnon/nix-config/nixos\"},\"split_pane\":{\"mode\":\"PreviousDir\",\"custom_dir\":\"\"},\"new_tab\":{\"mode\":\"PreviousDir\",\"custom_dir\":\"\"},\"new_window\":{\"mode\":\"PreviousDir\",\"custom_dir\":\"\"}}",
    #       "CrashReportingEnabled": "false",
    #       "VimModeEnabled": "true",
    #       "VimKeybindingsBannerState": "\"Dismissed\""
    #     }
    #   }
    # '';
  };
}
