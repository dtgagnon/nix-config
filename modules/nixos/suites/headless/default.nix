{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.suites.headless;
in
{
  options.${namespace}.suites.headless = {
    enable = mkBoolOpt false "Whether or not to enable headless server configuration.";
  };

  config = mkIf cfg.enable {
    # Better console experience for headless server
    console = {
      font = "Lat2-Terminus16";
      useXkbConfig = true;
    };

    # kmscon - modern console with better fonts
    services.kmscon = {
      enable = true;
      hwRender = true;
      fonts = [{
        name = "JetBrainsMono Nerd Font";
        package = pkgs.nerd-fonts.jetbrains-mono;
      }];
      extraConfig = ''
        font-size=14
        xkb-layout=us
      '';
    };

    # tmux - terminal multiplexing and session persistence
    programs.tmux = {
      enable = true;
      terminal = "tmux-256color";
      keyMode = "vi";
      escapeTime = 0;
      extraConfig = ''
        set -g mouse on
        set -g history-limit 10000
        set -g status-style 'bg=default fg=white'
        set -g pane-border-style 'fg=brightblack'
        set -g pane-active-border-style 'fg=blue'
      '';
    };
  };
}
