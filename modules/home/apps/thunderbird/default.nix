{ lib
, pkgs
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.apps.thunderbird;
  username = config.${namespace}.user.name;
in
{
  options.${namespace}.apps.thunderbird = {
    enable = mkBoolOpt false "Enable Thunderbird email client";
  };

  config = mkIf cfg.enable {
    #NOTE: Disabling the home-manager module for now since it interferes with the dynamic setting changes on-going currently - 11/10/2025
    # programs.thunderbird = {
    #   enable = true;
    #   profiles.${username} = {
    #     search = {
    #       default = "ddg";
    #       order = [
    #         "ddg"
    #         "Perplexity"
    #         "google"
    #       ];
    #       privateDefault = "ddg";
    #     };
    #
    #     settings = {
    #       "mail.spellcheck.inline" = true;
    #     };
    #
    #     isDefault = true;
    #   };
    # };
    home.packages = [ pkgs.thunderbird pkgs.birdtray ];
    home.sessionVariables.MAIL_CLIENT = "thunderbird";
  };
}
