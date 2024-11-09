{ lib
, pkgs
, config
, namespace
, ...
}:

let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.tools.comma;
in
{
  options.${namespace}.tools.comma = {
    enable = mkBoolOpt false "Whether or not to enable comma.";
  };

  config = mkIf cfg.enable {
    # Enables `command-not-found` integrations.
    # programs.command-not-found = enabled;
    # programs.nix-index = enabled;
		home.packages = with pkgs; [
			comma
			spirenix.nix-update-index
		];
    spirenix.home = {
      configFile = {
        "wgetrc".text = "";
      };
      extraOptions = {
        programs.nix-index.enable = true;
      };
    };

    # Enables `comma` and uses the `nix-index-database` to provide package information.
    # programs.nix-index-database.comma.enable = true;
  };
}
