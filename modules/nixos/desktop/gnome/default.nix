{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.gnome;
in
{
  options.${namespace}.desktop.gnome = {
    enable = mkBoolOpt false "Enable GNOME desktop environment";
  };

  config = mkIf cfg.enable {
    services = {
      desktopManager.gnome.enable = true;
      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
      };
      xserver.xkb.layout = "us";
    };
    environment.gnome.excludePackages = with pkgs; [
      gnome-photos
      gnome-tour
      gnome-text-editor
      cheese # webcam tool
      gnome-music
      gnome-terminal
      epiphany # web browser
      geary # email reader
      evince # document viewer
      gnome-characters
      totem # video player
      tali # poker game
      iagno # go game
      hitori # sudoku game
      atomix # puzzle game
      gnome-calculator
      yelp # help viewer
      gnome-maps
      gnome-weather
      gnome-contacts
      simple-scan
    ];
  };
}
