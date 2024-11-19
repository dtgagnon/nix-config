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

      extraConfig = ''
        				function get_appearance()
        					if wezterm.gui then
        						return wezterm.gui.get_appearance()
        					end
        					return "Dark"
        				end

        				function scheme_for_appearance(appearance)
        					if appearance:find 'Dark' then
        						return themes.Dark or ""
        					else
        						return themes.Light or ""
        					end
        				end

                local wezterm = require "wezterm"
                  if ${cfg.font} != ""
                  then wezterm.font(${cfg.font})
                  else ""

                return config
      '';
    };
    home.sessionVariables.TERMINAL = "wezterm";
  };
}
