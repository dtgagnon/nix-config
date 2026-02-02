{ lib
, config
, host ? ""
, format ? ""
, inputs ? { }
, namespace
, ...
}:
let
  inherit (lib) mkIf optionalString types;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.openssh;

  user = config.${namespace}.user.name;
  hasOptinPersistence = config.environment.persistence ? "/persist";

  # Get hostnames without evaluating other hosts' configs
  allHosts = builtins.attrNames (
    (inputs.self.nixosConfigurations or { }) // (inputs.self.darwinConfigurations or { })
  );
  otherHosts = builtins.filter (name: name != host) allHosts;

  # Generate SSH configurations for other hosts
  # Assumes same username across hosts (avoids cross-host config evaluation)
  other-hosts-config = lib.concatMapStringsSep "\n"
    (name: ''
      Host ${name}
      User ${user}
      ForwardAgent yes
      Port ${toString cfg.port}
    '')
    otherHosts;
in
{
  options.${namespace}.services.openssh = {
    enable = mkBoolOpt false "Whether or not to configure OpenSSH support.";
    authorizedKeyName = mkOpt types.str "dtgagnon-key" "Name of the keypair to authorize. Path: /persist/home/%u/.ssh/{name}.pub";
    port = mkOpt types.port 22022 "The port to listen on (in addition to 22).";
    manage-other-hosts = mkBoolOpt true "Whether or not to add other host configurations to SSH config.";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [
        22
        cfg.port
      ];

      settings = {
        PermitRootLogin = if format == "install-iso" then "yes" else "no";
        PasswordAuthentication = false;
        StreamLocalBindUnlink = "yes";
      };

      hostKeys = [
        {
          path = "${optionalString hasOptinPersistence "/persist"}/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];

      authorizedKeysFiles = [
        "/persist/home/%u/.ssh/${cfg.authorizedKeyName}.pub"
      ];
    };

    #NOTE: Right now, just using tailscale on all my devices for ssh connections - uncomment when regular openssh is needed
    programs.ssh.extraConfig = ''
      ${optionalString cfg.manage-other-hosts other-hosts-config}
    '';

    networking.firewall.allowedTCPPorts = [ cfg.port ];
    security.pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = [ "/persist/home/%u/.ssh/${cfg.authorizedKeyName}.pub" ];
    };
  };
}
