{
  config,
  lib,
  namespace,
  ...
}:
with lib;
let
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.atuin;
in {
  options.${namespace}.cli.atuin = {
    enable = mkBoolOpt false "Whether to enable atuin shell history tool";
  };

  config = mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      
      settings = {
        auto_sync = true;
        update_check = true;
        style = "compact";
        show_preview = true;
        
        # Filter out sensitive commands from history
        filter_mode = "global";
        filter_mode_shell_up_key_binding = "directory";
        
        # Search settings
        search_mode = "fuzzy";  # Use fuzzy search by default
        
        # Sync settings (uncomment and modify if you want to use sync)
        # sync_address = "https://api.atuin.sh";
        # sync_frequency = "5m";
      };
    };
  };
}
