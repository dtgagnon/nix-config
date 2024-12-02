{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.windsurf;
in
{
  options.${namespace}.apps.windsurf = {
    enable = mkBoolOpt false "Enable windsurf module";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.spirenix.windsurf ];

		home.file."~/.windsurf/argv.json".text = ''
      // This configuration file allows you to pass permanent command line arguments to VS Code.
      {
        // For compatibility with Hyprland, to get it to know what keyring to use.
        "password-store":"gnome-libsecret"

        // Use software rendering instead of hardware accelerated rendering. This can help in cases where you see rendering issues in VS Code.
        // "disable-hardware-acceleration": true,

        // Allows to disable crash reporting. Should restart the app if the value is changed.
        "enable-crash-reporter": true,

        // Unique id used for correlating crash reports sent from this instance. Do not edit this value.
        "crash-reporter-id": "4c9b8afe-4e3d-40db-a77d-3879fc1923bd"
      }
		'';

    spirenix.user.persistHomeDirs = [
      ".config/Windsurf"  # Future XDG config location
      ".windsurf"         # Current data directory
      ".codeium"          # Codeium data directory
    ];
  };
}
