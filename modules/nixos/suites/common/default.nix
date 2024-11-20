{ config
, lib
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt;
  cfg = config.${namespace}.suites.common;
in
{
  options.${namespace}.suites.common = {
    enable = mkBoolOpt false "Whether or not to enable common configuration.";
  };

  config = mkIf cfg.enable {
    spirenix = {
      desktop.gnome = enabled;

      hardware = {
        audio = enabled;
      };

      nix = enabled;

      security = {
        sudo = enabled;
        sops-nix = enabled;
      };

      services = {
        openssh = enabled;
      };

      system = {
        boot = enabled;
        fonts = enabled;
        locale = enabled;
        network = enabled;
        time = enabled;
        xkb = enabled;
      };

      tools = {
        general = enabled;
        nix-ld = enabled;
      };
    };
  };
}
