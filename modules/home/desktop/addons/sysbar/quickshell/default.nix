{ lib
, config
, inputs
, system
, namespace
, pkgs
, ...
}:
let
  inherit (lib) mkMerge mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.desktop.addons.sysbar.quickshell;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;

  options.${namespace}.desktop.addons.sysbar.quickshell = {
    enable = mkBoolOpt false "Whether to enable Quickshell in the desktop environment";
    premade = mkOpt (types.nullOr types.str) null "Declare the name of a prebuilt quickshell configuration to use";
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = cfg.premade != null -> cfg.enable;
          message = "spirenix: `premade` is set to `${cfg.premade}`, but `enable` is false. You must set `enable = true` to use premade configs.";
        }
      ];
    }
    (mkIf (cfg.enable && cfg.premade == null) {
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
    })
  ];
}
