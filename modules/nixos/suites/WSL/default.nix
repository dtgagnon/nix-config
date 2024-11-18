{ config
, lib
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt;
  cfg = config.${namespace}.suites.WSL;
in
{
  options.${namespace}.suites.WSL = {
    enable = mkBoolOpt false "Whether or not to enable a common WSL configuration";
  };

  config = mkIf cfg.enable {
    spirenix = {
      nix = enabled;

      security = {
        sudo = enabled;
        sops-nix = enabled;
      };

      services = {
        openssh = enabled;
      };

      system = {
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
