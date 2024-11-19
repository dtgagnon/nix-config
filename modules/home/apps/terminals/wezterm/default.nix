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

        exampleTheme = {
          ansi = [
            "#222222"
            "#D14949"
            "#48874F"
            "#AFA75A"
            "#599797"
            "#8F6089"
            "#5C9FA8"
            "#8C8C8C"
          ];
          brights = [
            "#444444"
            "#FF6D6D"
            "#89FF95"
            "#FFF484"
            "#97DDFF"
            "#FDAAF2"
            "#85F5DA"
            "#E9E9E9"
          ];
          background = "#1B1B1B";
          cursor_bg = "#BEAF8A";
          cursor_border = "#BEAF8A";
          cursor_fg = "#1B1B1B";
          foreground = "#BEAF8A";
          selection_bg = "#444444";
          selection_fg = "#E9E9E9";
        };
      };

      extraConfig = builtins.readFile ./wezterm.lua
        #NOTE: temp fix for rendering failures on nixpkgs master branch:
        + ''
        	front_end = "WebGpu",
        	enable_wayland = false,
      '';
    };
    home.sessionVariables.TERMINAL = "wezterm";
  };
}
