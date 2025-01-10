{ lib
, config
, inputs
, system
, namespace
, ...
}:
let
  inherit (lib) mkIf types mkForce;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.apps.terminals.ghostty;

  inherit (config.lib.stylix) colors;
in
{
  options.${namespace}.apps.terminals.ghostty = {
    enable = mkBoolOpt true "Enable ghostty terminal emulator";
    dark-theme = mkOpt types.str "stylix" "Set theme to use with dark theme, defaulting to Stylix generated theme";
    light-theme = mkOpt types.str "stylix" "Set theme to use with light theme";
  };

  config = mkIf cfg.enable {
    home.packages = [ inputs.ghostty.packages.${system}.default ];
    home.sessionVariables.TERM = mkForce "ghostty";
    home.sessionVariables.TERMINAL = mkForce "ghostty";

    xdg.configFile."ghostty/config".text = ''
      			theme = dark:"${cfg.dark-theme}",light:"${cfg.light-theme}"
      			font-size = 12

      			window-padding-x = 8
      			window-padding-y = 8
      			window-decoration = false

      		'' + (if cfg.dark-theme == "stylix" && cfg.light-theme == "stylix"
    then ''
      				palette = 0=#${colors.base00}
      				palette = 1=#${colors.base01}
      				palette = 2=#${colors.base02}
      				palette = 3=#${colors.base03}
      				palette = 4=#${colors.base04}
      				palette = 5=#${colors.base05}
      				palette = 6=#${colors.base06}
      				palette = 7=#${colors.base07}
      				palette = 8=#${colors.base08}
      				palette = 9=#${colors.base09}
      				palette = 10=#${colors.base0A}
      				palette = 11=#${colors.base0B}
      				palette = 12=#${colors.base0C}
      				palette = 13=#${colors.base0D}
      				palette = 14=#${colors.base0E}
      				palette = 15=#${colors.base0F}
      			''
    else ""
    );
  };
}
