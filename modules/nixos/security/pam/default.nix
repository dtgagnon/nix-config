{ lib, pkgs, config, namespace, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.security.pam;
in
{
  options.${namespace}.security.pam = {
    enable = mkBoolOpt false "Enable PAM based rSSH authentication for sudo";
  };

  # TODO: I have no idea what the below settings actually do, so I need to read up on that before enabling all this stuff.
  # config = mkIf cfg.enable {
  #   rules.auth.rssh = {
  #     order = config.rules.auth.ssh_agent_auth.order - 1;
  #     control = "sufficient";
  #     modulePath = "${pkgs.pam_rssh}/lib/libpam_rssh.so";
  #     settings.authorized_keys_command = pkgs.writeShellScript "get-authorized-keys" ''
  #               cat "/etc/ssh/authorized_keys.d/$1"
  #             '';
  #   };
  # };
}