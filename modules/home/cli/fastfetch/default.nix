{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.fastfetch;
in
{
  options.${namespace}.cli.fastfetch = {
    enable = mkBoolOpt false "Whether to install fastfetch or not";
  };

  config = mkIf cfg.enable {

    programs.fastfetch = {
      enable = true;

      settings = {
        display = {
          color = {
            keys = "35";
            output = "90";
          };
          disableLinewrap = true;
          separator = ": ";
        };

        logo = {
          source = ./nixos.png;
          type = "kitty-direct";
          height = 10;
          width = 20;
          padding = {
            top = 2;
            left = 2;
          };
        };

        modules = [
          "break"
          "break"
          {
            type = "custom";
            format = "┌───────────────────────── Hardware ─────────────────────────┐";
          }
          {
            type = "board";
            key = "  MB"; #│
          }
          {
            type = "cpu";
            key = "   ";
          }
          {
            type = "gpu";
            key = "   ";
          }
          {
            type = "memory";
            key = "   ";
          }
          "break"
          {
            type = "display";
            key = "  🖵 ";
          }
          {
            type = "custom";
            key = "  ⌨";
            format = " QK65 + Zaku + 8008 ";
          }
          {
            type = "custom";
            format = "Logitech MX Master 3S";
          }
          {
            type = "custom";
            format = "└──────────────────────────────────────────────────────────┘";
          }
          "break"
          {
            type = "custom";
            format = "┌───────────────────────── Software ─────────────────────────┐";
          }
          "break"
          {
            type = "custom";
            format = "  OS -> NixOS";
          }
          {
            type = "kernel";
            key = "  ├ ";
          }
          {
            type = "packages";
            key = "  ├󰏖 ";
          }
          {
            type = "shell";
            key = "  └ ";
          }
          "break"
          {
            type = "wm";
            key = "  WM";
          }
          {
            type = "terminal";
            key = "  ├ ";
          }
          {
            type = "colors";
            key = "  └󰉼 ";
            symbol = "circle";
          }
          {
            type = "custom";
            format = "└──────────────────────────────────────────────────────────┘";
          }
          "break"
          {
            type = "custom";
            format = "┌─────────────────────── Uptime / Age ───────────────────────┐";
          }
          {
            type = "command";
            key = "│ 󱦟";
            text = # bash
              ''
                birth_install=$(stat -c %W /)
                current=$(date +%s)
                delta=$((current - birth_install))
                delta_days=$((delta / 86400))
                echo $delta_days days
              '';
          }
          {
            type = "uptime";
            key = "│  ";
          }
          {
            type = "custom";
            format = "└──────────────────────────────────────────────────────────┘";
          }
          "break"
          "break"
        ];
      };
    };
  };
}
