#NOTE: When Ghostty is configured via the programs.ghostty home-manager module and with Stylix enabled"" both theme, font-name, font-emoji, font-size, and opacity settings will already be added to the config file for ghostty

{ lib
, pkgs
, config
, inputs
, system
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.terminals.ghostty;
in
{
  options.${namespace}.apps.terminals.ghostty = {
    enable = mkBoolOpt true "Enable ghostty terminal emulator";
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      package = inputs.ghostty.packages.${system}.default;
      settings = {
        keybind = [
          # New Splits
          "ctrl+shift+s>h=new_split:left"
          "ctrl+shift+s>l=new_split:right"
          "ctrl+shift+s>j=new_split:up"
          "ctrl+shift+s>k=new_split:down"

          # Navigate Splits
          "ctrl+h=goto_split:left"
          "ctrl+l=goto_split:right"
          "ctrl+j=goto_split:up"
          "ctrl+k=goto_split:down"
          "ctrl+w=close_surface"
        ];
        window-padding-x = 10;
        window-padding-y = 10;
        window-decoration = false;
      };
      # themes = { }; # Cu:tom created themes to add to $HOME/.config/ghostty/themes
    };

    # home.sessionVariables.TERM = mkForce "ghostty";
    # home.sessionVariables.TERMINAL = mkForce "ghostty";
  };
}
