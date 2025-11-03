{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.desktop.fonts;
in
{
  options.${namespace}.desktop.fonts = {
    enable = mkBoolOpt false "Whether or not to manage fonts.";
    extraFonts = mkOpt (types.listOf types.package) [ ] "Custom font packages to install.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ font-manager ];

    environment.variables = {
      # Enable icons in tooling since we have nerdfonts.
      LOG_ICONS = "true";
    };

    fonts.packages = with pkgs; [
      font-awesome

      nerd-fonts._0xproto
      nerd-fonts.fira-code
      nerd-fonts.fira-mono
      nerd-fonts.iosevka
      nerd-fonts.iosevka-term
      nerd-fonts.jetbrains-mono
      nerd-fonts.open-dyslexic

      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
    ] ++ cfg.extraFonts;
  };
}
