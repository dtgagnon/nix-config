{ lib
, pkgs
, config
, inputs
, system
, namespace
, ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (lib.${namespace}) mkBoolOpt mkRGBA;
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
      plugins = [ pkgs.rofi-calc ];
      terminal = "${inputs.ghostty.packages.${system}.default}/bin/ghostty";
      extraConfig = {
        modi = "drun,window,filebrowser";
        disable-history = false;
        hide-scrollbar = true;
        show-icons = true;
        icon-theme = "Papirus";
        drun-display-format = "{icon} {name}";
        display-drun = "";
        display-filebrowser = "";
        display-run = "";
        display-ssh = "󰈀";
        display-window = "";
        sidebar-mode = false;
      };
      location = "top";
      theme = mkForce {
        # Global color and style variables used throughout the theme
        "*" = {
					base00 = mkLiteral "${mkRGBA { hex = "#${colors.base00}"; alpha = 0.8; }}";
					base01 = mkLiteral "${mkRGBA { hex = "#${colors.base01}"; alpha = 0.8; }}";
					base02 = mkLiteral "${mkRGBA { hex = "#${colors.base02}"; alpha = 0.8; }}";
					base03 = mkLiteral "${mkRGBA { hex = "#${colors.base03}"; alpha = 0.8; }}";
          # base00 = mkLiteral "#${colors.base00}80";
          # base01 = mkLiteral "#${colors.base01}80";
          # base02 = mkLiteral "#${colors.base02}80";
          # base03 = mkLiteral "#${colors.base03}80";
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
          width = mkLiteral "15%";
          height = mkLiteral "28%";
          transparency = "real";
          orientation = mkLiteral "vertical";
          cursor = mkLiteral "default";
          spacing = mkLiteral "0px";
          border = mkLiteral "2px";
          border-radius = mkLiteral "16px";
          border-color = mkLiteral "@base03";
          background-color = mkLiteral "transparent";
          opacity = mkLiteral "1";
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
          ];
          border-radius = mkLiteral "16px";
          border = mkLiteral "0px";
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
          children = map mkLiteral [
            "entry"
            "mode-switcher"
          ];
        };

        # Prompt text before search input
        "prompt" = {
          enable = false;
          padding = mkLiteral "6px";
          margin = mkLiteral "0px";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@base04";
          border-radius = mkLiteral "4px";
          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.5";
        };

        # Text input field for search
        "entry" = {
          enabled = true;
          width = mkLiteral "100%";
          blink = false;
          expand = true;
          padding = mkLiteral "10px";
          margin = mkLiteral "0px 40px 0px 0px";
          border = mkLiteral "2px 0px";
          border-radius = mkLiteral "8px";
          border-color = mkLiteral "@base03";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@base05";

          cursor = mkLiteral "text";
          font = "${config.stylix.fonts.sansSerif.name} 12";
          placeholder = "Search...";
          placeholder-color = mkLiteral "@base03";
          horizontal-align = mkLiteral "0.5";
          vertical-align = mkLiteral "0.5";
        };

        # Container for mode buttons (drun, run, window, etc)
        "mode-switcher" = {
          expand = false;
          padding = mkLiteral "4px";
          margin = mkLiteral "0px";
          spacing = mkLiteral "0px";
          border = mkLiteral "2px 0px";
          border-radius = mkLiteral "8px";
          border-color = mkLiteral "@base03";
          background-color = mkLiteral "transparent";
        };

        # Individual mode selection buttons
        "button" = {
          padding = mkLiteral "2px 4px";
          margin = mkLiteral "0px 2px";
          border = mkLiteral "0px";
          border-color = mkLiteral "transparent";
          border-radius = mkLiteral "4px";
          background-color = mkLiteral "transparent";
          font = "${config.stylix.fonts.monospace.name} 22";
          text-color = mkLiteral "@base05";
          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.5";
          cursor = mkLiteral "pointer";
        };

        # Style for selected mode button
        "button selected" = {
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@base04";
          border-color = mkLiteral "@base04";
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
          padding = mkLiteral "12px 0px 4px 0px";
          margin = mkLiteral "0px";

          columns = 3;
          lines = 3;
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
          text-color = mkLiteral "@base05";
        };

        # Individual items in the results list
        "element" = {
          enabled = true;
          expand = true;
          spacing = mkLiteral "0px";
          margin = mkLiteral "5px 0px 0px 0px";
          padding = mkLiteral "5px 0px 0px 0px";
          border = mkLiteral "0px";
          border-radius = mkLiteral "0px";
          border-color = mkLiteral "transparent";
          background-color = mkLiteral "@base00";
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
          text-color = mkLiteral "@base05";
          font = "${config.stylix.fonts.sansSerif.name} 10";
          vertical-align = mkLiteral "0";
          horizontal-align = mkLiteral "0.5";
          cursor = mkLiteral "inherit";
        };

        # Icon styling for results
        "element-icon" = {
          background-color = mkLiteral "inherit";
          # text-color = mkLiteral "inherit";
          size = mkLiteral "32px";
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
          border-color = mkLiteral "@base04";
          text-color = mkLiteral "@base04";
        };
        "element selected.urgent" = {
          background-color = mkLiteral "@base07";
          border = mkLiteral "0px 0px 2px 0px";
          border-color = mkLiteral "inherit";
          text-color = mkLiteral "@base01";
        };
        "element selected.active" = {
          background-color = mkLiteral "@base0D";
          border = mkLiteral "0px 0px 2px 0px";
          border-radius = mkLiteral "8px 8px 0px 0px";
          border-color = mkLiteral "@base05";
          text-color = mkLiteral "@base05";
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

        # Spacer element for layout
        "dummy" = {
          expand = true;
          background-color = mkLiteral "transparent";
        };

        # Scrollbar styling (when enabled)
        "scrollbar" = {
          width = mkLiteral "4px";
          border = 0;
          handle-color = mkLiteral "@base0F";
          handle-width = mkLiteral "6px";
          padding = 0;
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
    };
  };
}
