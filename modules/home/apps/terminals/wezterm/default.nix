{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.apps.terminals.wezterm;
in
{
  options.${namespace}.apps.terminals.wezterm = {
    enable = mkBoolOpt false "Enable wezterm terminal emulator";
    font = mkOpt (types.str) "" "Optionally declare the wezterm font";
    extraConfig = mkOpt types.str "" "Additional lua for wezterm configuration";
  };

  config = mkIf cfg.enable {

    programs.wezterm = {
      enable = true;

      colorSchemes = {
        kanagawa_custom = {
          ansi = [
            "#090618"
            "#c34043"
            "#76946a"
            "#c0a36e"
            "#7e9cd8"
            "#957fb8"
            "#6a9589"
            "#dcd7ba"
          ];
          brights = [
            "#727169"
            "#e82424"
            "#98bb6c"
            "#e6c384"
            "#7fb4ca"
            "#938aa9"
            "#7aa89f"
            "#c8c093"
          ];
          cursor_bg = "#dcd7ba";
          cursor_border = "#dcd7ba";
          cursor_fg = "#1f1f28";
          foreground = "#dcd7ba";
          background = "#000000";
        };
      };

      # extraConfig = builtins.readFile ./wezterm.lua;
    };
    xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
    xdg.configFile."wezterm/sessionizer.lua".source = ./sessionizer.lua;

    home.sessionVariables."env.TERMINAL" = "wezterm";
  };
}
