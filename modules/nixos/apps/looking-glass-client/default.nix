{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.looking-glass-client;
  user = config.${namespace}.user;
in
{
  options.${namespace}.apps.looking-glass-client = {
    enable = mkBoolOpt false "Whether or not to enable the Looking Glass client.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.looking-glass-client ];

    environment.etc."looking-glass-client.ini" = {
      user = "+${toString config.users.users.${user.name}.uid}";
      source = ./client.ini;
    };
  };
}
