{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.hardware.keyboard;
in
{
  options.${namespace}.hardware.keyboard = {
    enable = mkBoolOpt false "Whether or not to configure keyboard settings.";

    model = mkOpt (types.enum [ "generic" "qk65v1" ]) "generic" "Keyboard model";
  };

  config = mkIf cfg.enable {
    console.useXkbConfig = true;

    services.xserver = {
      xkb = {
        layout = "us";
      };
    };

    # Model-specific kernel parameters
    boot.kernelParams = mkIf (cfg.model == "qk65v1") [
      "hid_apple.fnmode=2"
    ];
  };
}
