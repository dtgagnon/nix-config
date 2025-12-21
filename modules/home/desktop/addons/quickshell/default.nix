{ lib
, config
, inputs
, system
, namespace
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.quickshell;
in
{
  options.${namespace}.desktop.addons.quickshell = {
    enable = mkBoolOpt false "Whether to enable Quickshell in the desktop environment.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      inputs.quickshell.packages.${system}.default
      # Ensure Qt6 Wayland support is available
      pkgs.kdePackages.qtwayland
    ];

    # Install template shell configuration
    xdg.configFile."quickshell/shell.qml".source = ./shell.qml;

    # Desktop entry for xdg-desktop-portal integration
    xdg.dataFile."applications/org.quickshell.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Quickshell
      Comment=QtQuick-based Wayland compositor shell
      Exec=quickshell
      Icon=application-x-executable
      Terminal=false
      Categories=System;
      NoDisplay=true
    '';
  };
}
