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
          background = mkLiteral "#${colors.base00}";
          lighter-bg = mkLiteral "#${colors.base01}";
          selection-bg = mkLiteral "#${colors.base02}";
          comments = mkLiteral "#${colors.base03}";
          dark-fg = mkLiteral "#${colors.base04}";
          default-fg = mkLiteral "#${colors.base05}";
          light-fg = mkLiteral "#${colors.base06}";
          light-bg = mkLiteral "#${colors.base07}";
          error = mkLiteral "#${colors.base08}";
          constant = mkLiteral "#${colors.base09}";
          class = mkLiteral "#${colors.base0A}";
          string = mkLiteral "#${colors.base0B}";
          support = mkLiteral "#${colors.base0C}";
          function = mkLiteral "#${colors.base0D}";
          keyword = mkLiteral "#${colors.base0E}";
          deprecated = mkLiteral "#${colors.base0F}";
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
          border-color = mkLiteral "@deprecated";
          background-color = mkLiteral "@background";
        };

        # Container for all main elements (inputbar and listbox)
        "mainbox" = {
          enabled = true;
          padding = mkLiteral "15px";
          orientation = mkLiteral "vertical";
          children = map mkLiteral [
            "inputbar"
            "listbox"
            "mode-switcher"
          ];
          background-color = mkLiteral "transparent";
        };

        # Search bar container with entry field and mode switcher
        "inputbar" = {
          enabled = true;
          padding = mkLiteral "2px";
          margin = mkLiteral "10px";

          background-color = mkLiteral "transparent";
          # background-image = mkLiteral ''url("~/Pictures/wallpapers/nord-rainbow-dark-nix.png", width)'';
          border-radius = mkLiteral "0px";
          orientation = mkLiteral "horizontal";
          # children = mkLiteral "[prompt,entry]";
          children = map mkLiteral [
            "entry"
          ];
        };

        # Text input field for search
        "entry" = {
          enabled = true;
          expand = true;
          # width = mkLiteral "X%";
          padding = mkLiteral "10px";
          border = mkLiteral "2px";
          border-radius = mkLiteral "8px";
          border-color = mkLiteral "@deprecated";
          background-color = mkLiteral "@lighter-bg";
          text-color = mkLiteral "@default-fg";

          cursor = mkLiteral "text";
          placeholder = "🔍 Search... ";
          placeholder-color = mkLiteral "inherit";
        };

        # Container for message and results list
        "listbox" = {
          spacing = mkLiteral "10px";
          padding = mkLiteral "10px";
          border-radius = mkLiteral "8px";
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
          border = mkLiteral "2px";
          border-color = mkLiteral "@deprecated";
          border-radius = mkLiteral "8px";
          background-color = mkLiteral "transparent";
        };

        # Spacer element for layout
        # "dummy" = {
        #   expand = true;
        #   background-color = mkLiteral "transparent";
        # };

        # Container for mode buttons (drun, run, window, etc)
        "mode-switcher" = {
          expand = true;
          spacing = mkLiteral "10px";
          background-color = mkLiteral "transparent";
        };

        # Individual mode selection buttons
        "button" = {
          # width = mkLiteral "20%";
          padding = mkLiteral "4px";
          margin = mkLiteral "20px";
          border-color = mkLiteral "@deprecated";
          border-radius = mkLiteral "8px";
          background-color = mkLiteral "@background";
          text-color = mkLiteral "@default-fg";
          cursor = mkLiteral "pointer";

          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.5";
        };

        # Style for selected mode button
        "button selected" = {
          background-color = mkLiteral "@background";
          text-color = mkLiteral "@string";
        };

        # Prompt text before search input
        "prompt" = {
          enabled = false;
          background-color = mkLiteral "@string";
          padding = mkLiteral "6px";
          text-color = mkLiteral "@background";
          border-radius = mkLiteral "3px";
          margin = mkLiteral "0px 0px 0px 0px";
        };

        # Scrollbar styling (when enabled)
        "scrollbar" = {
          width = mkLiteral "4px";
          border = 0;
          handle-color = mkLiteral "@deprecated";
          handle-width = mkLiteral "6px";
          padding = 0;
        };

        # Individual items in the results list
        "element" = {
          enabled = true;
          spacing = mkLiteral "10px";
          padding = mkLiteral "5px";
          border-radius = mkLiteral "12px";
          border-color = mkLiteral "#FFFFFF";
          background-color = mkLiteral "@background";
          text-color = mkLiteral "@default-fg";
          cursor = mkLiteral "inherit";
        };

        # Text styling for results
        "element-text" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "inherit";
          font = "${config.stylix.fonts.monospace.name} 16";
          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.0";
          cursor = mkLiteral "inherit";
        };

        # Icon styling for results
        "element-icon" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "inherit";
          size = mkLiteral "36px";
          cursor = mkLiteral "inherit";
        };

        # Various element states - normal, urgent, active in different combinations
        "element normal.normal" = {
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };
        "element normal.urgent" = {
          background-color = mkLiteral "@error";
          text-color = mkLiteral "@default-fg";
        };
        "element normal.active" = {
          background-color = mkLiteral "@string";
          text-color = mkLiteral "@default-fg";
        };
        "element selected.normal" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@error"; 
          border-color = mkLiteral "@selection-bg";
        };
        "element selected.urgent" = {
          background-color = mkLiteral "@error";
          text-color = mkLiteral "@lighter-bg";
        };
        "element selected.active" = {
          background-color = mkLiteral "@error";
          text-color = mkLiteral "@lighter-bg";
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

        # Generic text display styling
        "textbox" = {
          padding = mkLiteral "6px";
          margin = mkLiteral "0px 0px 0px 0px";
          border-radius = mkLiteral "8px";
          text-color = mkLiteral "@constant";
          background-color = mkLiteral "@background";
          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.5";
        };

        # Error message styling
        "error-message" = {
          background-color = mkLiteral "@constant";
          margin = mkLiteral "2px";
          padding = mkLiteral "2px";
          border-radius = mkLiteral "8px";
        };
      };
    };
  };
}