{ config
, lib
, namespace
, ...
}:
let
  inherit (lib) mkDefault mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt;
  cfg = config.${namespace}.suites.common;
in
{
  options.${namespace}.suites.common = {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    spirenix = {
      desktop = {
        gnome = enabled;
        fonts = enabled;
      };

      hardware = {
        audio = enabled;
        keyboard = enabled;
      };

      nix = enabled;

      security = {
        sudo = enabled;
        sops-nix = enabled;
      };

      services = {
        openssh = enabled;
      };

      system = enabled;

      tools = {
        general = enabled;
        nix-ld = enabled;
      };
    };
  };
}
