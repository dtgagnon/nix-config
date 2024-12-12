
     theme = mkForce {
        # Global color and style variables used throughout the theme
        "*" = {
          base00 = mkLiteral "#${colors.base00}";
          base01 = mkLiteral "#${colors.base01}";
          base02 = mkLiteral "#${colors.base02}";
          base03 = mkLiteral "#${colors.base03}";
          base04 = mkLiteral "#${colors.base04}";
          base05 = mkLiteral "#${colors.base05}";
          base06 = mkLiteral "#${colors.base06}";
          base07 = mkLiteral "#${colors.base07}";
          base08 = mkLiteral "#${colors.base08}";
          base09 = mkLiteral "#${colors.base09}";
          base0A = mkLiteral "#${colors.base0A}";
          base0B = mkLiteral "#${colors.base0B}";
          base0C = mkLiteral "#${colors.base0C}";
          base0D = mkLiteral "#${colors.base0D}";
          base0E = mkLiteral "#${colors.base0E}";
          base0F = mkLiteral "#${colors.base0F}";
        };

        # Main rofi window container
        "window" = {
          width = mkLiteral "25%";
          height = mkLiteral "38%";
          transparency = "real";
          orientation = mkLiteral "vertical";
          cursor = mkLiteral "default";
          spacing = mkLiteral "0px";
          border = mkLiteral "2px";
          border-radius = mkLiteral "8px";
          border-color = mkLiteral "@base03";
          background-color = mkLiteral "@base00";
          opacity = mkLiteral "0.5";
        };

        # Container for all main elements (inputbar and listbox)
        "mainbox" = {
          enabled = true;
          padding = mkLiteral "10px";
          margin = mkLiteral "10px";
          orientation = mkLiteral "vertical";
          children = map mkLiteral [
            "inputbar"
            "listbox"
            "mode-switcher"
          ];
          border-radius = mkLiteral "0px";
          border = mkLiteral "1px";
          border-color = mkLiteral "transparent";
          background-color = mkLiteral "transparent";
        };

        # Search bar container with entry field and mode switcher
        "inputbar" = {
          enabled = true;
          padding = mkLiteral "0px";
          margin = mkLiteral "0px";
          background-color = mkLiteral "transparent";
          # background-image = mkLiteral ''url("~/Pictures/wallpapers/nord-rainbow-dark-nix.png", width)'';
          border = mkLiteral "0px";
          border-color = mkLiteral "transparent";
          border-radius = mkLiteral "8px";
          orientation = mkLiteral "horizontal";
          # children = mkLiteral "[prompt,entry]";
          children = map mkLiteral [
            "dummy"
            "entry"
            "dummy"
          ];
        };

        # Text input field for search
        "entry" = {
          enabled = true;
          width = mkLiteral "33%";
          blink = false;
          expand = true;
          padding = mkLiteral "10px";
          border = mkLiteral "2px 0px";
          border-radius = mkLiteral "8px";
          border-color = mkLiteral "@base03";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@base05";

          cursor = mkLiteral "text";
          font = "${config.stylix.fonts.sansSerif.name} 12";
          placeholder = "🔍 Search... ";
          placeholder-color = mkLiteral "inherit";
          horizontal-align = mkLiteral "0.5";
          vertical-align = mkLiteral "0.5";
        };

        # Container for message and results list
        "listbox" = {
          border = mkLiteral "2px 0px";
          border-color = mkLiteral "@base03";
          spacing = mkLiteral "0px";
          padding = mkLiteral "0px";
          margin = mkLiteral "10px 0px 0px 0px";
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
          expand = true;
          padding = mkLiteral "10px";
          margin = mkLiteral "0px";

          columns = 4;
          lines = 5;
          cycle = true;
          dynamic = false;
          scrollbar = false;

          layout = mkLiteral "vertical";
          reverse = false;
          fixed-height = true;
          fixed-columns = true;

          border = mkLiteral "0px";
          border-color = mkLiteral "transparent";
          border-radius = mkLiteral "0px";
          background-color = mkLiteral "transparent";
        };

        # Spacer element for layout
        "dummy" = {
          expand = true;
          background-color = mkLiteral "transparent";
        };

        # Container for mode buttons (drun, run, window, etc)
        "mode-switcher" = {
          expand = false;
          margin = mkLiteral "0px";
          spacing = mkLiteral "0px";
          border = mkLiteral "2px 0px 0px 0px";
          border-radius = mkLiteral "8px";
          border-color = mkLiteral "@base03";
          background-color = mkLiteral "transparent";
        };

        # Individual mode selection buttons
        "button" = {
          padding = mkLiteral "10px";
          margin = mkLiteral "10px";
          border = mkLiteral "2px";
          border-color = mkLiteral "@base03";
          border-radius = mkLiteral "4px";
          background-color = mkLiteral "transparent";
          font = "${config.stylix.fonts.sansSerif.name} 12";
          text-color = mkLiteral "@base03";
          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.5";
          cursor = mkLiteral "pointer";
        };

        # Style for selected mode button
        "button selected" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@base0E";
          border-color = mkLiteral "@base03";
        };

        # Prompt text before search input
        "prompt" = {
          enabled = false;
          background-color = mkLiteral "@base0B";
          padding = mkLiteral "6px";
          text-color = mkLiteral "@base00";
          border-radius = mkLiteral "4px";
          margin = mkLiteral "0px";
        };

        # Scrollbar styling (when enabled)
        "scrollbar" = {
          width = mkLiteral "4px";
          border = 0;
          handle-color = mkLiteral "@base0F";
          handle-width = mkLiteral "6px";
          padding = 0;
        };

        # Individual items in the results list
        "element" = {
          enabled = true;
          expand = true;
          spacing = mkLiteral "0px";
          margin = mkLiteral "10px 10px";
          padding = mkLiteral "5px";
          border = mkLiteral "0px";
          border-radius = mkLiteral "0px";
          border-color = mkLiteral "transparent";
          background-color = mkLiteral "@base00";
          text-color = mkLiteral "@base0D";
          cursor = mkLiteral "inherit";
          orientation = mkLiteral "vertical";
          children = map mkLiteral [
            "element-icon"
            "element-text"
          ];
        };

        # Text styling for results
        "element-text" = {
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
          font = "${config.stylix.fonts.sansSerif.name} 12";
          vertical-align = mkLiteral "0";
          horizontal-align = mkLiteral "0.5";
          cursor = mkLiteral "inherit";
        };

        # Icon styling for results
        "element-icon" = {
          background-color = mkLiteral "inherit";
          # text-color = mkLiteral "inherit";
          size = mkLiteral "36px";
          cursor = mkLiteral "inherit";
          vertical-align = mkLiteral "1.0";
          horizontal-align = mkLiteral "0.5";
        };

        # Various element states - normal, urgent, active in different combinations
        "element normal.normal" = {
          background-color = mkLiteral "inherit";
          border-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };
        "element normal.urgent" = {
          background-color = mkLiteral "@base0E";
          border-color = mkLiteral "inherit";
          text-color = mkLiteral "@base07";
        };
        "element normal.active" = {
          background-color = mkLiteral "@base0D";
          border-radius = mkLiteral "8px";
          border-color = mkLiteral "inherit";
          text-color = mkLiteral "@base01";
        };
        "element selected.normal" = {
          background-color = mkLiteral "transparent";
          border = mkLiteral "0px 0px 2px 0px";
          border-color = mkLiteral "@base05";
          text-color = mkLiteral "@base05";
        };
        "element selected.urgent" = {
          background-color = mkLiteral "@base07";
          border = mkLiteral "0px 0px 2px 0px";
          border-color = mkLiteral "inherit";
          text-color = mkLiteral "@base0E";
        };
        "element selected.active" = {
          background-color = mkLiteral "@base0D";
          border = mkLiteral "0px 0px 2px 0px";
          border-radius = mkLiteral "8px 8px 0px 0px";
          border-color = mkLiteral "@base07";
          text-color = mkLiteral "@base01";
        };
        "element alternate.normal" = {
          background-color = mkLiteral "inherit";
          border-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };
        "element alternate.urgent" = {
          background-color = mkLiteral "inherit";
          border-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };
        "element alternate.active" = {
          background-color = mkLiteral "inherit";
          border-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };

        # Generic text display styling
        "textbox" = {
          padding = mkLiteral "0px";
          margin = mkLiteral "0px 0px 0px 0px";
          border-radius = mkLiteral "8px";
          text-color = mkLiteral "@base09";
          background-color = mkLiteral "@base00";
          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.5";
        };

        # Error message styling
        "error-message" = {
          background-color = mkLiteral "@base09";
          margin = mkLiteral "0px";
          padding = mkLiteral "0px";
          border-radius = mkLiteral "8px";
        };
      };