{
  lib,
  config,
  namespace,
  ...
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
          {
            type = "custom";
            format = "┌─────────────────────────Hardware─────────────────────────┐";
          }
          {
            type = "board";
            key = "│ MB";
          }
          {
            type = "cpu";
            key = "│  ";
          }
          {
            type = "gpu";
            key = "│ 󰍛 ";
          }
          {
            type = "memory";
            key = "│ 󰑭 ";
          }
          {
            type = "display";
            key = "│ MON";
          }
          {
            type = "custom";
            format = "└──────────────────────────────────────────────────────────┘";
          }
          "break"
          {
            type = "custom";
            format = "┌─────────────────────────Software─────────────────────────┐";
          }
          {
            type = "custom";
            format = " OS -> NixOS";
          }
          {
            type = "kernel";
            key = "│ ├ ";
          }
          {
            type = "packages";
            key = "│ ├󰏖 ";
          }
          {
            type = "shell";
            key = "└ └ ";
          }
          "break"
          {
            type = "wm";
            key = " WM";
          }
          {
            type = "terminal";
            key = "│ ├ ";
          }
          {
            type = "wmtheme";
            key = "│ ├󰉼 ";
          }
          {
            type = "colors";
            key = "└ └󰉼 ";
          }
          {
            type = "custom";
            format = "└──────────────────────────────────────────────────────────┘";
          }
          "break"
          {
            type = "custom";
            format = "┌───────────────────────Uptime / Age───────────────────────┐";
          }
          {
            type = "command";
            key = "│  ";
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
        ];
      };
    };
  };
}
