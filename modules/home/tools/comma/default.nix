{ config
, lib
, pkgs
, options
, namespace
, ... 
}:

with lib;
with lib.${namespace};
let cfg = config.${namespace}.tools.comma;

in {
  options.${namespace}.tools.comma = with types; {
    enable = mkBoolOpt false "Whether or not to enable comma.";
  };

  config = mkIf cfg.enable {
    # Enables `command-not-found` integrations.
    # programs.command-not-found.enable = mkForce false;
    programs.nix-index = enabled;

    # Enables `comma` and uses the `nix-index-database` to provide package information.
    programs.nix-index-database.comma.enable = true;
  };
}
