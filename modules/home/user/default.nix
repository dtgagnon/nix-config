{
  lib
, config
, pkgs
, namespace
, osConfig ? { }
, ...
}:

let
  inherit (lib) types mkIf mkDefault mkMerge;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.user;

  is-linux = pkgs.stdenv.isLinux; ## Line isn't used because if it's linux, it's just using the final else statement.
  is-darwin = pkgs.stdenv.isDarwin;

  home-directory =
    if cfg.name == null then null
    else if is-darwin then "/Users/${cfg.name}"
    else "/home/${cfg.name}";
in
{
  options.${namespace}.user = {
    enable = mkBoolOpt true "Whether to configure the user account.";
    name = mkOpt (types.nullOr types.str) (config.snowfallorg.user.name or "admin") "The user account.";
    fullName = mkOpt types.str "" "The full name of the user.";
    email = mkOpt types.str "" "The email of the user.";
    home = mkOpt (types.nullOr types.str) home-directory "The user's home directory.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.name != null;
          message = "${namespace}.user.name must be set";
        }
        {
          assertion = cfg.home != null;
          message = "${namespace}.user.home must be set";
        }
      ];

      home = {
        username = mkDefault cfg.name;
        homeDirectory = mkDefault cfg.home;
      };
    }
  ]);
}
