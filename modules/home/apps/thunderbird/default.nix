{ lib
, config
, namespace
, osConfig ? null
, ...
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
          default = "ddg";
          order = [
            "ddg"
            "Perplexity"
            "google"
          ];
          privateDefault = "ddg";
        };

        settings = {
          "mail.spellcheck.inline" = true;
        };

        isDefault = true;
      };
    };

    home.sessionVariables.MAIL_CLIENT = "thunderbird";

  };
}
