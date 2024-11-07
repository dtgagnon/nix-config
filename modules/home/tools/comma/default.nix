{ config
, lib
, pkgs
, options
, namespace
, ... 
}:

let 
  inherit (lib) mkIf;
  inherit (lib.${namespace}) enabled mkBoolOpt; 
  cfg = config.${namespace}.tools.comma;
in 
{
  options.${namespace}.tools.comma = {
    enable = mkBoolOpt false "Whether or not to enable comma.";
  };

  config = mkIf cfg.enable {
    # Enables `command-not-found` integrations.
    # programs.command-not-found = enabled;
    programs.nix-index = enabled;

    # Enables `comma` and uses the `nix-index-database` to provide package information.
    programs.nix-index-database.comma.enable = true;
  };
}
