{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf mkForce types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.rofi;
  hyprCfg = config.${namespace}.desktop.hyprland;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./themes;

  options.${namespace}.desktop.addons.rofi = {
    enable = mkBoolOpt false "Whether to enable rofi in the desktop environment.";
    style = mkOpt types.str "default" "The rofi theme to use.";

    # Custom options mirroring programs.rofi to avoid conflicts with stylix
    theme = mkOpt types.attrs { } "Rofi theme configuration";
    extraConfig = mkOpt types.attrs { } "Extra rofi configuration";
    location = mkOpt types.str "center" "Rofi window location";
  };

  config = mkIf cfg.enable {
    programs.rofi = {
      enable = true;
      plugins = [ pkgs.rofi-calc ];
      terminal = "${hyprCfg.terminal.package}/bin/${hyprCfg.terminal.name}";
      theme = mkForce cfg.theme;
      inherit (cfg) extraConfig location;
    };

    spirenix.preservation.directories = [
      ".config/rofi"
      ".local/share/rofi"
    ];
  };
}
