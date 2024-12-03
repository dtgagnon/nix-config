{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (config.lib.stylix) colors;
  inherit (config.lib.formats.rasi) mkLiteral;
  cfg = config.${namespace}.desktop.addons.rofi;
in
{
  options.${namespace}.desktop.addons.rofi = {
    enable = mkBoolOpt false "Whether to enable rofi in the desktop environment.";
  };

  config = mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      terminal = "${pkgs.kitty}/bin/kitty";
      extraConfig = {
        modi = "filebrowser,drun,window,run,ssh";
        disable-history = false;
        hide-scrollbar = true;
        show-icons = true;
        icon-theme = "Papirus";
        location = 0;
        drun-display-format = "{icon} {name}";
        display-drun = "  Apps ";
        display-filebrowser = "  Files ";
        display-run = "  Run ";
        display-Network = " 󰤨 Network";
        display-ssh = " 󰈀 SSH";
        display-window = "  Window";
        sidebar-mode = true;
      };
      theme = lib.mkForce {
        # Global color and style variables used throughout the theme
        "*" = {
          background = mkLiteral "#${colors.base00}";         # Primary background
          lighter-bg = mkLiteral "#${colors.base01}";        # Lighter background for UI elements
          selection-bg = mkLiteral "#${colors.base02}";      # Selection background
          comments = mkLiteral "#${colors.base03}";          # Comments/secondary content
          dark-fg = mkLiteral "#${colors.base04}";           # Dark foreground/borders
          default-fg = mkLiteral "#${colors.base05}";        # Default foreground text
          light-fg = mkLiteral "#${colors.base06}";          # Light foreground text
          light-bg = mkLiteral "#${colors.base07}";          # Light background
          error = mkLiteral "#${colors.base08}";             # Error/red accent
          constant = mkLiteral "#${colors.base09}";          # Constants/orange accent
          class = mkLiteral "#${colors.base0A}";             # Class names/yellow accent
          string = mkLiteral "#${colors.base0B}";            # Strings/green accent
          support = mkLiteral "#${colors.base0C}";           # Support functions/cyan accent
          function = mkLiteral "#${colors.base0D}";          # Functions/blue accent
          keyword = mkLiteral "#${colors.base0E}";           # Keywords/purple accent
          deprecated = mkLiteral "#${colors.base0F}";        # Deprecated/brown accent
        };

        # Inherit background and text colors for these specific elements
        # "element-text, element-icon , mode-switcher" = {
        #   background-color = mkLiteral "inherit";
        #   text-color = mkLiteral "inherit";
        # };

        # Main rofi window container
        "window" = {
          width = mkLiteral "25%";
          height = mkLiteral "50%";
          transparency = "real";
          orientation = mkLiteral "vertical";
          cursor = mkLiteral "default";
          spacing = mkLiteral "0px";
          border = mkLiteral "2px";
          border-radius = mkLiteral "12px";
          border-color = mkLiteral "@deprecated";            # Using base0F for borders
          background-color = mkLiteral "@background";        # Using base00 for main background
        };

        # Container for all main elements (inputbar and listbox)
        "mainbox" = {
          enabled = true;
          padding = mkLiteral "15px";
          orientation = mkLiteral "vertical";
          children = map mkLiteral [
            "inputbar"
            "listbox"
          ];
          # background-color = mkLiteral "@bg";
          background-color = mkLiteral "transparent";
        };

        # Search bar container with entry field and mode switcher
        "inputbar" = {
          enabled = true;
          padding = mkLiteral "2px";
          margin = mkLiteral "10px";

          background-color = mkLiteral "transparent";
          # background-image = mkLiteral ''url("~/Pictures/wallpapers/nord-rainbow-dark-nix.png", width)'';
          border-radius = mkLiteral "12px";
          orientation = mkLiteral "horizontal";
          # children = mkLiteral "[prompt,entry]";
          children = map mkLiteral [
            "entry"
            "dummy"
            "mode-switcher"
          ];
        };

        # Text input field for search
        "entry" = {
          enabled = true;
          expand = false;
          width = mkLiteral "20%";
          padding = mkLiteral "10px";
          border-radius = mkLiteral "12px";
          background-color = mkLiteral "@constant";          # Using base09 for entry background
          text-color = mkLiteral "@default-fg";              # Using base05 for entry text

          cursor = mkLiteral "text";
          placeholder = "🔍 Search... ";
          placeholder-color = mkLiteral "inherit";
        };

        # Container for message and results list
        "listbox" = {
          spacing = mkLiteral "10px";
          padding = mkLiteral "10px";
          background-color = mkLiteral "transparent";
          orientation = mkLiteral "vertical";
          children = map mkLiteral [
            "message"
            "listview"
          ];
        };

        # Grid view of search results
        "listview" = {
          enabled = true;
          columns = 2;
          lines = 5;
          cycle = true;
          dynamic = true;
          scrollbar = false;
          layout = mkLiteral "vertical";
          reverse = false;
          fixed-height = false;
          fixed-columns = true;
          spacing = mkLiteral "10px";
          border = mkLiteral "0px";
          background-color = mkLiteral "@background";        # Using base00 for listview background
        };

        # Spacer element for layout
        "dummy" = {
          expand = true;
          background-color = mkLiteral "transparent";
        };

        # Container for mode buttons (drun, run, window, etc)
        "mode-switcher" = {
          expand = true;
          spacing = mkLiteral "10px";
          background-color = mkLiteral "transparent";
        };

        # Individual mode selection buttons
        "button" = {
          width = mkLiteral "5%";
          padding = mkLiteral "10px";
          border-radius = mkLiteral "8px";
          background-color = mkLiteral "@constant";          # Using base09 for button background
          text-color = mkLiteral "@default-fg";              # Using base05 for button text
          cursor = mkLiteral "pointer";

          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.5";
        };

        # Style for selected mode button
        "button selected" = {
          background-color = mkLiteral "@background";        # Using base00 for selected button background
          text-color = mkLiteral "@string";                  # Using base0B for selected button text
        };

        # Prompt text before search input
        "prompt" = {
          background-color = mkLiteral "@string";            # Using base0B for prompt background
          padding = mkLiteral "6px";
          text-color = mkLiteral "@background";              # Using base00 for prompt text
          border-radius = mkLiteral "3px";
          margin = mkLiteral "20px 0px 0px 20px";
        };

        # Scrollbar styling (when enabled)
        "scrollbar" = {
          width = mkLiteral "4px";
          border = 0;
          handle-color = mkLiteral "@deprecated";            # Using base0F for scrollbar handle
          handle-width = mkLiteral "6px";
          padding = 0;
        };

        # Individual items in the results list
        "element" = {
          enabled = true;
          spacing = mkLiteral "10px";
          padding = mkLiteral "5px";
          border-radius = mkLiteral "12px";
          background-color = mkLiteral "@background";        # Using base00 for element background
          text-color = mkLiteral "@default-fg";              # Using base05 for element text
          cursor = mkLiteral "inherit";
        };

        # Various element states - normal, urgent, active in different combinations
        "element normal.normal" = {
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };
        "element normal.urgent" = {
          background-color = mkLiteral "@error";             # Using base08 for urgent background
          text-color = mkLiteral "@default-fg";              # Using base05 for urgent text
        };
        "element normal.active" = {
          background-color = mkLiteral "@string";            # Using base0B for active background
          text-color = mkLiteral "@default-fg";              # Using base05 for active text
        };
        "element selected.normal" = {
          background-color = mkLiteral "@lighter-bg";        # Using base01 for selected background
          text-color = mkLiteral "@lighter-bg";              # Using base01 for selected text
        };
        "element selected.urgent" = {
          background-color = mkLiteral "@error";             # Using base08 for urgent selected background
          text-color = mkLiteral "@lighter-bg";              # Using base01 for urgent selected text
        };
        "element selected.active" = {
          background-color = mkLiteral "@error";             # Using base08 for active selected background
          text-color = mkLiteral "@lighter-bg";              # Using base01 for active selected text
        };
        "element alternate.normal" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "inherit";
        };
        "element alternate.urgent" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "inherit";
        };
        "element alternate.active" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "inherit";
        };

        # Icon styling for results
        "element-icon" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "inherit";
          size = mkLiteral "36px";
          cursor = mkLiteral "inherit";
        };

        # Text styling for results
        "element-text" = {
          background-color = mkLiteral "transparent";
          font = "${config.stylix.fonts.monospace.name} 16";
          text-color = mkLiteral "inherit";
          cursor = mkLiteral "inherit";

          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.0";
        };

        # Generic text display styling
        "textbox" = {
          padding = mkLiteral "6px";
          # margin = mkLiteral "20px 0px 0px 20px";
          border-radius = mkLiteral "12px";

          text-color = mkLiteral "@string";                  # Using base0B for text color
          background-color = mkLiteral "@constant";          # Using base09 for text background

          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.0";
        };

        # Error message styling
        "error-message" = {
          background-color = mkLiteral "@constant";          # Using base09 for error background
          margin = mkLiteral "2px";
          padding = mkLiteral "2px";
          border-radius = mkLiteral "5px";
        };
      };
    };
  };
}
