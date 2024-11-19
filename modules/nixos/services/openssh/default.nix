{ lib
, config
, host ? ""
, format ? ""
, inputs ? { }
, namespace
, ...
}:
let
  inherit (lib) mkIf optionalString types foldl;
  inherit (lib.${namespace}) mkOpt mkBoolOpt;
  cfg = config.${namespace}.services.openssh;

  user = config.${namespace}.user.name;
  user-id = builtins.toString user.uid;

  hasOptinPersistence = config.environment.persistence ? "/persist";

  # TODO: This is a hold-over from old snowfall-lib rev using specialArg `name` to provide hostname. Can be moved to just `host` once the `name` uses are identified.
  name = host;

  # this is a default user's public ssh key
  default-key = '' config.sops.secrets."ssh-keys/dtgagnon-key.pub" '';

  # Collects the information about the other hosts
  other-hosts = lib.filterAttrs
    (
      key: host: key != name && (host.config.${namespace}.user.name or null) != null
    )
    ((inputs.self.nixosConfigurations or { }) // (inputs.self.darwinConfigurations or { }));

  # Generate SSH configurations for other hosts within the namespace, with an established user, excluding the current host
  other-hosts-config = lib.concatMapStringsSep "\n"
    (
      name:
      let
        remote = other-hosts.${name};
        remote-user-name = remote.config.${namespace}.user.name;
        remote-user-id = builtins.toString remote.config.users.users.${remote-user-name}.uid;

        #NOTE: Don't need to use forward-gpg for age keys, but will need to refer to them statically somehow. I'm using age keys only so far.
        forward-gpg =
          optionalString (config.programs.gnupg.agent.enable && remote.config.programs.gnupg.agent.enable)
            ''
              RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent /run/user/${user-id}/gnupg/S.gpg-agent.extra
              RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent.ssh /run/user/${user-id}/gnupg/S.gpg-agent.ssh
            '';
      in
      ''
        Host ${name}
          User ${remote-user-name}
          ForwardAgent yes
          Port ${builtins.toString cfg.port}
          ${forward-gpg}
      ''
    )
    (builtins.attrNames other-hosts);
in
{
  options.${namespace}.services.openssh = {
    enable = mkBoolOpt false "Whether or not to configure OpenSSH support.";
    authorizedKeys = mkOpt (types.listOf types.str) [ default-key ] "The public keys to apply.";
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
    };

    programs.ssh.extraConfig = ''
      ${optionalString cfg.manage-other-hosts other-hosts-config}
    '';

    spirenix.user.extraOptions.openssh.authorizedKeys.keys = cfg.authorizedKeys;

    spirenix.home.extraOptions = {
      programs.nushell.shellAliases = foldl
        (
          aliases: system: aliases // { "ssh-${system}" = "ssh ${system} -t tmux a"; }
        )
        { }
        (builtins.attrNames other-hosts);
      programs.zsh.shellAliases = foldl
        (
          aliases: system: aliases // { "ssh-${system}" = "ssh ${system} -t tmux a"; }
        )
        { }
        (builtins.attrNames other-hosts);
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    security.pam.sshAgentAuth = {
      enable = true;
      authorizedKeysFiles = [ "/etc/ssh/authorized_keys.d/%u" ];
    };
  };
}
