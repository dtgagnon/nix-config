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
      screen = mkOpt int 300 "Seconds until screen dims.";
      lock = mkOpt int 600 "Seconds until screen locks.";
      suspend = mkOpt int 1800 "Seconds until system suspends.";
    };

    lockCmd = mkOpt str "pidof hyprlock || hyprlock" "Command to run for locking the screen.";
    beforeSleepCmd = mkOpt str "loginctl lock-session" "Command to run before sleep.";
    afterSleepCmd = mkOpt str "hyprctl dispatch dpms on" "Command to run after sleep.";
  };

  config = mkIf cfg.enable {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          before_sleep_cmd = cfg.beforeSleepCmd;
          after_sleep_cmd = cfg.afterSleepCmd;
          lock_cmd = cfg.lockCmd;
        };

        listener = [
          {
            timeout = cfg.timeouts.screen;
            on-timeout = "notify-send 'Screen Dim' 'Screen will dim in 30 seconds' -t 3000";
          }
          {
            timeout = cfg.timeouts.lock;
            on-timeout = "notify-send 'Screen Lock' 'Screen will lock in 30 seconds' -t 3000";
          }
          {
            timeout = cfg.timeouts.lock + 30;
            on-timeout = "loginctl lock-session && hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = cfg.timeouts.suspend;
            on-timeout = "notify-send 'System Suspend' 'System will suspend in 30 seconds' -t 3000 && sleep 30 && systemctl suspend";
          }
        ];
      };
    };
  };
}
