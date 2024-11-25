{
  options,
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
	inherit (lib) mkIf types;
	inherit (lib.${namespace}) mkOpt mkBoolOpt;
	cfg = config.${namespace}.desktop.fonts;
in {
  options.${namespace}.desktop.fonts = {
    enable = mkBoolOpt false "Whether or not to manage fonts.";
    fonts = mkOpt (types.listOf types.package) [ ] "Custom font packages to install.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ font-manager ];

    environment.variables = {
      # Enable icons in tooling since we have nerdfonts.
      LOG_ICONS = "true";
    };

    fonts.packages =
      with pkgs;
      [
        (nerdfonts.override { fonts = [ "FiraCode" "FiraMono" ]; })
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-emoji
      ]
      ++ cfg.fonts;
  };
}
