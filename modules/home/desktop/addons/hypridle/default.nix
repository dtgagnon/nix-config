{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.hypridle;
in
{
  options.${namespace}.desktop.addons.hypridle = with types; {
    enable = mkBoolOpt false "Whether to enable hypridle.";

    timeouts = {
      screen = mkOpt int 180 "Seconds until screen dims.";
      lock = mkOpt int 300 "Seconds until screen locks.";
      # suspend = mkOpt int 1800 "Seconds until system suspends.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.${namespace}.desktop.hyprland.enable;
        message = "hypridle requires hyprland";
      }
    ];

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
          lock_cmd = "pidof hyprlock || hyprlock";
        };

        listener = [
          # Dim the screen
          {
            timeout = cfg.timeouts.screen;
            on-timeout = "brightnessctl set 10%";
            on-resume = "brightnessctl -r";
          }

          # Lock the screen
          {
            timeout = cfg.timeouts.lock;
            on-timeout = "notify-send 'Screen Lock' 'Screen will lock in 30 seconds' -t 3000 && sleep 30 && loginctl lock-session";
            on-resume = "hyprctl dispatch dpms on";
          }

          # Turn off the screen
          {
            timeout = cfg.timeouts.screen + 300;
            on-timeout = "hyprctl dispatch dpms suspend";
            on-resume = "hyprctl dispatch dpms on";
          }

          # Enter suspended system state
          # {
          #   timeout = cfg.timeouts.suspend;
          #   on-timeout = "notify-send 'System Suspend' 'System will suspend in 30 seconds' -t 3000 && sleep 30 && systemctl suspend";
          #   on-resume = "hyprctl dispatch dpms on";
          # }
        ];
      };
    };
  };
}
