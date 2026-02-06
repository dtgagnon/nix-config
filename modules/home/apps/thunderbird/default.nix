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

  # Wrapper script that waits for proton-bridge before starting Thunderbird
  # This prevents the login failure when Thunderbird starts before proton-bridge is ready
  thunderbird-wait = pkgs.writeShellScript "thunderbird-wait" ''
    # Wait for protonmail-bridge service to be active (max 60s)
    timeout=60
    while ! ${pkgs.systemd}/bin/systemctl --user is-active protonmail-bridge.service >/dev/null 2>&1; do
      sleep 1
      timeout=$((timeout - 1))
      if [ $timeout -le 0 ]; then
        echo "Warning: protonmail-bridge service not active after 60s, starting Thunderbird anyway"
        break
      fi
    done

    # Wait for IMAP port to be listening (max 30s after service is active)
    timeout=30
    while ! ${lib.getExe pkgs.netcat} -z 127.0.0.1 1143 2>/dev/null; do
      sleep 1
      timeout=$((timeout - 1))
      if [ $timeout -le 0 ]; then
        echo "Warning: proton-bridge IMAP port not ready after 30s, starting Thunderbird anyway"
        break
      fi
    done

    exec ${lib.getExe pkgs.thunderbird}
  '';
in
{
  options.${namespace}.apps.thunderbird = {
    enable = mkBoolOpt false "Enable Thunderbird email client";
  };

  config = mkIf cfg.enable {
    #NOTE: Disabling the home-manager module for now since it interferes with the dynamic setting changes on-going currently - 11/10/2025
    home = {
      sessionVariables.MAIL_CLIENT = "thunderbird";
      packages = [
        pkgs.thunderbird
        pkgs.notmuch
        pkgs.mblaze  # Maildir utilities
        pkgs.msmtp   # SMTP sending
        # pkgs.birdtray
      ];
    };

    # NOTE: Notmuch is configured by spirenix.services.mail module
    # Only including the notmuch package here for CLI access
    # To add account-tagging hooks, use: spirenix.services.mail.notmuch.postNewHook

    spirenix.desktop.hyprland.extraExec = [ "${thunderbird-wait}" ];
    # spirenix.desktop.addons.sysbar.sysTrayApps = [ "birdtray" ];
    # xdg.configFile."birdtray-config.json".text = builtins.toJSON birdtrayConfig;

    spirenix.preservation.directories = [
      ".thunderbird"
    ];
  };
}
