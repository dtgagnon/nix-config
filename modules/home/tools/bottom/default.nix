{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.tools.bottom;
in {
  options.${namespace}.tools.bottom = {
    enable = mkBoolOpt false "Whether or not to enable bottom system monitor";
  };

  config = mkIf cfg.enable {
    programs.bottom = {
      enable = true;
      settings = {
        # Colors and style
        colors = {
          table_header_color = "#f5e0dc";
          all_cpu_color = "#f38ba8";
          avg_cpu_color = "#eba0ac";
          cpu_core_colors = ["#f38ba8" "#fab387" "#f9e2af" "#a6e3a1" "#74c7ec" "#89b4fa"];
          ram_color = "#a6e3a1";
          swap_color = "#fab387";
          rx_color = "#89b4fa";
          tx_color = "#f38ba8";
          widget_title_color = "#f5e0dc";
          border_color = "#585b70";
          highlighted_border_color = "#f5e0dc";
          text_color = "#cdd6f4";
          graph_color = "#a6e3a1";
          cursor_color = "#f5e0dc";
          selected_text_color = "#11111b";
          selected_bg_color = "#f5e0dc";
        };

        # Layout and behavior
        flags = {
          dot_marker = false;  # Use dots in graphs
          temperature_type = "c";  # Celsius
          rate_unit = "b";  # Bytes
          hide_table_gap = true;
          mem_as_value = true;
          tree = true;  # Show process tree
          show_table_scroll_position = true;
          process_command = true;  # Show full command
          basic = false;  # Enable advanced features
          network_use_binary_prefix = true;
          network_use_bytes = true;
          network_use_log = false;
          cpu_as_percentage = true;
        };

        # Default widget layout
        row = [
          {
            ratio = 30;
            child = [
              {
                type = "cpu";
                ratio = 50;
              }
              {
                type = "mem";
                ratio = 50;
              }
            ];
          }
          {
            ratio = 40;
            child = [
              {
                type = "proc";
                ratio = 100;
                default = true;  # Start with process widget selected
              }
            ];
          }
          {
            ratio = 30;
            child = [
              {
                type = "net";
                ratio = 50;
              }
              {
                type = "disk";
                ratio = 50;
              }
            ];
          }
        ];
      };
    };
  };
}
