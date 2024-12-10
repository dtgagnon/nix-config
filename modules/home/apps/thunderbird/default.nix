{ 
  lib,
  pkgs,
  config, 
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.thunderbird;
in
{
  options.${namespace}.apps.thunderbird = {
    enable = mkBoolOpt false "Enable Thunderbird email client";
  };

  config = mkIf cfg.enable {
    programs.thunderbird = {
      enable = true;
      settings = {
        #global settings
      };

      profiles.${config.spirenix.user.name} = {
        search = {
          default = "DuckDuckGo";
          order = [
            "DuckDuckGo"
            "Perplexity"
            "Google"
          ];
          privateDefault = "DuckDuckGo";
        };
        
        settings = {
          "mail.spellcheck.inline" = true;
        };

        isDefault = true;
      };
    };

    home.sessionVariables.MAIL_CLIENT = "thunderbird";

    # spirenix.user.persistHomeDirs = [
    #   ".thunderbird"  # Contains all user profiles, extensions, and settings
    # ];
  };
}
