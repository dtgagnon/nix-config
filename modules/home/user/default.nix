{ lib
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

  is-darwin = pkgs.stdenv.isDarwin;

  home-directory =
    if cfg.name == null then
      null
    else if is-darwin then
      "/Users/${cfg.name}"
    else
      "/home/${cfg.name}";
in
{
  options.${namespace}.user = {
    enable = mkBoolOpt true "Whether to configure the user account.";

    name = mkOpt (types.nullOr types.str) (config.snowfallorg.user.name or "dtgagnon") "The user account.";
    home = mkOpt (types.nullOr types.str) home-directory "The user's home directory.";

    fullName = mkOpt types.str "${cfg.name}" "The full name of the user.";
    email = mkOpt types.str "${cfg.name}@email.com" "The email of the user.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.home-manager.enable = true;
      home = {
        preferXdgDirectories = true;
        username = mkDefault cfg.name;
        homeDirectory = mkDefault cfg.home;
        stateVersion = lib.mkDefault (osConfig.system.stateVersion or "24.05");
      };
    }
  ]);

}
