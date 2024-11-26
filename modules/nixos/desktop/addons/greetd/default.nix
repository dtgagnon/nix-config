{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.desktop.addons.greetd;
in
{
  options.${namespace}.desktop.addons.greetd = {
    enable = mkBoolOpt false "Whether or not to enable the greetd display manager.";
  };

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = rec {
          command = "${lib.getExe pkgs.greetd.tuigreet} --time --cmd Hyprland";
          user = "greeter";
        };
        initial_session = default_session;
      };
    };

    # Create a symlink for tuigreet sessions
    environment.etc."greetd/environments".text = ''
      Hyprland
    '';
  };
}
