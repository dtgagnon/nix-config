{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkForce;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.hardware.audio;
in
{
  options.${namespace}.hardware.audio = {
    enable = mkBoolOpt true "Enable typical audio configuration";
  };

  config = mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      jack.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    environment.systemPackages = with pkgs; [
      pulsemixer
      pavucontrol
    ] ++ cfg.extraPackages;

    spirenix.user.extraGroups = [ "audio" ];

    hardware.pulseaudio.enable = mkForce false;
  };
}
