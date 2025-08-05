#NOTE: When Ghostty is configured via the programs.ghostty home-manager module and with Stylix enabled"" both theme, font-name, font-emoji, font-size, and opacity settings will already be added to the config file for ghostty from the stylix global configuration options

{ lib
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
      clearDefaultKeybinds = true;
      settings = {
        keybind = [
          # Close Surface
          "ctrl+w=close_surface"

          # Split Management
          "ctrl+shift+e=new_split:down"
          "ctrl+shift+s>j=new_split:down"
          "ctrl+shift+s>k=new_split:up"
          "ctrl+shift+o=new_split:right"
          "ctrl+shift+s>l=new_split:right"
          "ctrl+shift+s>h=new_split:left"
          "ctrl+enter=toggle_split_zoom"

          # Resize Splits
          "super+ctrl+shift+plus=equalize_splits"
          "super+ctrl+shift+k=resize_split:up,10"
          "super+ctrl+shift+j=resize_split:down,10"
          "super+ctrl+shift+l=resize_split:right,10"
          "super+ctrl+shift+h=resize_split:left,10"

          # Navigate Splits
          "ctrl+shift+left_bracket=goto_split:previous"
          "ctrl+shift+right_bracket=goto_split:next"
          "ctrl+shift+k=goto_split:up"
          "ctrl+shift+j=goto_split:down"
          "ctrl+shift+l=goto_split:right"
          "ctrl+shift+h=goto_split:left"

          # Window/Tab Management
          "ctrl+shift+n=new_window"
          "ctrl+shift+t=new_tab"
          "ctrl+shift+w=close_tab"
          "ctrl+tab=next_tab"
          "ctrl+shift+tab=previous_tab"
          "alt+one=goto_tab:1"
          "alt+two=goto_tab:2"
          "alt+three=goto_tab:3"
          "alt+four=goto_tab:4"
          "alt+five=goto_tab:5"
          "alt+six=goto_tab:6"
          "alt+seven=goto_tab:7"
          "alt+eight=goto_tab:8"
          "alt+nine=last_tab"

          # Other
          "ctrl+alt+a=select_all"
          "ctrl+alt+i=inspector:toggle"
          "ctrl+alt+j=write_screen_file:paste"
          "ctrl+alt+shift+j=write_screen_file:open"

          # Font Size
          "ctrl+zero=reset_font_size"
          "ctrl+minus=decrease_font_size:1"
          "ctrl+equal=increase_font_size:1"

          # Clipboard
          "ctrl+shift+c=copy_to_clipboard"
          "ctrl+shift+v=paste_from_clipboard"

          # Scrolling & Selection
          "ctrl+alt+shift+page_up=jump_to_prompt:-1"
          "ctrl+alt+shift+page_down=jump_to_prompt:1"
          "shift+up=adjust_selection:up"
          "shift+down=adjust_selection:down"
          "shift+right=adjust_selection:right"
          "shift+left=adjust_selection:left"
          "shift+home=scroll_to_top"
          "shift+end=scroll_to_bottom"
          "shift+page_up=scroll_page_up"
          "shift+page_down=scroll_page_down"
        ];
        window-padding-x = 10;
        window-padding-y = 10;
        window-decoration = false;
      };
      # themes = { }; # Cu:tom created themes to add to $HOME/.config/ghostty/themes
    };
  };
}
