{
  lib,
  pkgs,
  config,
  inputs,
  system,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types genAttrs;
  inherit (lib.${namespace}) mkBoolOpt mkOpt enabled;
  cfg = config.spirenix.desktop.hyprland;
in
{
  imports = lib.snowfall.fs.get-non-default-nix-files ./.;
  
  options.spirenix.desktop.hyprland = {
    enable = mkBoolOpt false "Whether or not to use the hyprland desktop manager";
    extraConfig = mkOpt types.str "" "Additional hyprland configuration in string format";
    primaryModifier = mkOpt types.str "SUPER" "The primary modifier key.";
    extraKeybinds = mkOpt (types.attrsOf types.anything) { } "Additional keybinds to add to the Hyprland config";
    extraSettings = mkOpt (types.attrsOf types.anything) { } "Additional settings to add to the Hyprland config";
  };

  config = mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${system}.hyprland;
      systemd.enable = true;
      xwayland.enable = true;
      inherit (cfg) extraConfig;
      settings = cfg.extraSettings // cfg.extraKeybinds;
    };

    spirenix.desktop.addons = {
      qt = enabled;
      rofi = enabled;
    };

    home.packages = with pkgs; [
      # core dependencies
      libinput
      glib
      gtk3.out
      wayland

      # wayland tools
      wl-clipboard
    ];
  };
}
