{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.looking-glass-client;
in
{
  options.${namespace}.apps.looking-glass-client = {
    enable = mkBoolOpt false "Whether or not to enable the Looking Glass client.";
  };

  config = mkIf cfg.enable {
    programs.looking-glass-client = {
      enable = true;
      package = pkgs.looking-glass-client;
      settings = {
        app = {
          allowDMA = true;
          shmFile = "/dev/kvmfr0";
        };
        win = {
          size = "3440x1440";
          autoResize = "yes";
          borderless = "no";
          dontUpscale = "yes";
          fullScreen = "no";
          keepAspect = "yes";
          maximize = "no";
          noScreensaver = "yes";
          quickSplash = "yes";
          uiSize = 16; #huh? idk why
        };
        input = {
          autoCapture = "no";
          escapeKey = "KEY_RIGHTCTRL";
          grabKeyboardOnFocus = "yes";
          rawMouse = "yes";
          releaseKeysOnFocusLoss = "yes";
        };
        audio = {
          micDefault = "allow";
        };
        spice = {
          enable = "yes";
          audio = true;
          clipboard = "yes";
        };
        wayland = {
          warpSupport = "yes";
          fractionScale = "no";
        };
      };
    };
  };
}
