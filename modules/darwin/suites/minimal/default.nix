{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt;
  cfg = config.${namespace}.suites.minimal;
in
{
  options.${namespace}.suites.minimal = {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    spirenix = {
      desktop.fonts.enable = true;

      hardware = {
        audio.enable = true;
        keyboard.enable = true;
      };

      nix.enable = true;

      security = {
        sudo = enabled;
        sops-nix = enabled;
      };

      system = enabled;

      tools = {
        general = enabled;
        nix-ld = enabled;
      };
    };
  };
}
