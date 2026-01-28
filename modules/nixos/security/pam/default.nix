{ lib, config, namespace, ... }:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.security.pam;
in
{
  options.${namespace}.security.pam = {
    enable = mkBoolOpt false "Enable PAM based rSSH authentication for sudo";
    authorizedKeyName = mkOpt types.str "dtgagnon-key" "Name of the public key file for pam_rssh authentication (without .pub extension)";
  };

  config = mkIf cfg.enable {
    security.pam = {
      rssh = {
        enable = true;
        settings = {
          # Use $user variable substitution supported by pam_rssh
          # Points to the same keys used by openssh authorized_keys
          auth_key_file = "/persist/home/$user/.ssh/${cfg.authorizedKeyName}.pub";
        };
      };
      services.sudo.rssh = true;
    };
  };
}
