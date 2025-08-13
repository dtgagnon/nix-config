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
    environment.systemPackages = with pkgs; [
      comma
      spirenix.nix-update-index
    ];

    spirenix.user.home = {
      configFile."wgetrc".text = "";
      extraOptions = {
        programs.nix-index.enable = true;
      };
    };
  };
}
