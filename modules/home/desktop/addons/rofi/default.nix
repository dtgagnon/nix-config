{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkDefault mkForce types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
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
        #"@import" = "default";
        
        # Global color and style variables used throughout the theme
        "*" = {
          bg-col = mkLiteral "#${colors.base00}";
          bg-col-light = mkLiteral "#${colors.base01}";
          border-col = mkLiteral "#${colors.base05}";
          selected-col = mkLiteral "#${colors.base00}";
          blue = mkLiteral "#${colors.base0D}";
          fg-col = mkLiteral "#${colors.base05}";
          fg-col2 = mkLiteral "#${colors.base08}";
          grey = mkLiteral "#737994";
          # width = 600;
        };

        # Inherit background and text colors for these specific elements
        "element-text, element-icon , mode-switcher" = {
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };

        # Main rofi window container
        "window" = {
          width = mkLiteral "50%";
          height = mkLiteral "360px";

          transparency = "real";
          # orientation = mkLiteral "vertical";
          # cursor = mkLiteral "default";
          # spacing = mkLiteral "0px";
          
          border = mkLiteral "3px";
          border-radius = mkLiteral "8px";
          border-color = mkLiteral "@border-col";
          background-color = mkLiteral "@bg-col";
        };

        # Container for all main elements (inputbar and listbox)
        "mainbox" = {
          enabled = true;
          padding = mkLiteral "15px";
          orientation = mkLiteral "vertical";
          children = map mkLiteral "[inputbar, listbox]";
          # background-color = mkLiteral "@bg-col";
          background-color = mkLiteral "transparent";
        };

        # Search bar container with entry field and mode switcher
        "inputbar" = {
          enabled = true;
          padding = mkLiteral "2px";
          margin = mkLiteral "10px";
          
          background-color = mkLiteral "transparent";
          # background-image = mkLiteral ''url("~/Pictures/wallpapers/nord-rainbow-dark-nix.png", width)'';
          # background-color = mkLiteral "@bg-col";
          border-radius = mkLiteral "5px";
          orientation = mkLiteral "horizontal";
          # children = mkLiteral "[prompt,entry]";
          children = map mkLiteral ["entry" "dummy" "mode-switcher" ];
        };

        # Text input field for search
        "entry" = {
          enabled = true;
          expand = false;
          width = mkLiteral "20%";
          padding = mkLiteral "10px";
          border-radius = mkLiteral "8px";
          background-color = mkLiteral "@bg-col-light";
          text-color = mkLiteral "@fg-col";

          cursor = mkLiteral "text";
          placeholder = "🖥️ Search ";
          placeholder-color = mkLiteral "inherit";
        };

        # Container for message and results list
        "listbox" = {
          spacing = mkLiteral "10px";
          padding = mkLiteral "10px";
          background-color = mkLiteral "transparent";
          orientation = mkLiteral "vertical";
          children = map mkLiteral ["message" "listview"];
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
          background-color = mkLiteral "@bg-col";
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
          # background-color = mkLiteral "transparent";
        };

        # Individual mode selection buttons
        "button" = {
          #width = mkLiteral "5%";
          padding = mkLiteral "10px";
          #border-radius = mkLiteral "8px";
          background-color = mkLiteral "@bg-col-light";
          text-color = mkLiteral "@grey";
          cursor = mkLiteral "pointer";

          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.5";
        };

        # Style for selected mode button
        "button selected" = {
          background-color = mkLiteral "@bg-col";
          text-color = mkLiteral "@blue";
        };

        # Prompt text before search input
        "prompt" = {
          background-color = mkLiteral "@blue";
          padding = mkLiteral "6px";
          text-color = mkLiteral "@bg-col";
          border-radius = mkLiteral "3px";
          margin = mkLiteral "20px 0px 0px 20px";
        };

        # Colon separator after prompt (if used)
        "textbox-prompt-colon" = {
          expand = false;
          #str =  mkLiteral ":";
        };

        # Scrollbar styling (when enabled)
        "scrollbar" = {
          width = mkLiteral "4px";
          border = 0;
          handle-color = mkLiteral "@border-col";
          handle-width = mkLiteral "6px";
          padding = 0;
        };

        # Individual items in the results list
        "element" = {
          enabled = true;
          # spacing = mkLiteral "10px";
          padding = mkLiteral "5px";
          border-radius = mkLiteral "8px";
          # background-color = mkLiteral "@bg-col";
          # text-color = mkLiteral "@fg-col";
          cursor = mkLiteral "inherit";
        };

        # Various element states - normal, urgent, active in different combinations
        "element normal.normal" = {
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };
        "element normal.urgent" = {
          background-color = mkLiteral "@urgent";
          text-color = mkLiteral "@foreground";
        };
        "element normal.active" = {
          background-color = mkLiteral "@active";
          text-color = mkLiteral "@foreground";
        };
        "element selected.normal" = {
          background-color = mkLiteral "@selected";
          text-color = mkLiteral "@text-selected";
        };
        "element selected.urgent" = {
          background-color = mkLiteral "@urgent";
          text-color = mkLiteral "@text-selected";
        };
        "element selected.active" = {
          background-color = mkLiteral "@urgent";
          text-color = mkLiteral "@text-selected";
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
          # background-color = mkLiteral "transparent";
          # text-color = mkLiteral "inherit";
          size = mkLiteral "36px";
          cursor = mkLiteral "inherit";
        };

        # Text styling for results
        "element-text" = {
          # background-color = mkLiteral "transparent";
          # font = "JetBrainsMono Nerd Font Mono 12";
          # text-color = mkLiteral "inherit";
          cursor = mkLiteral "inherit";

          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.0";
        };

        # Generic text display styling
        "textbox" = {
          padding = mkLiteral "6px";
          margin = mkLiteral "20px 0px 0px 20px";
          # border-radius = mkLiteral "8px";

          text-color = mkLiteral "@blue";
          background-color = mkLiteral "@bg-col-light";

          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.0";
        };

        # Error message styling
        "error-message" = {
          background-color = mkLiteral "@bg-col-light";
          margin = mkLiteral "2px";
          padding = mkLiteral "2px";
          border-radius = mkLiteral "5px";
        };
      };
    };
  };
}