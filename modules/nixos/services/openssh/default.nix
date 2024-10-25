{ config
, lib
, host ? ""
, format ? ""
, inputs ? { }
, namespace
, ...
}:
let
  inherit (lib) mkIf optionalString types foldl;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.services.openssh;

  user = config.users.users.${config.${namespace}.user.name};
  user-id = builtins.toString user.uid;

  # TODO: This is a hold-over from an earlier Snowfall Lib version which used the specialArg `name` to provide the host name.
  name = host;

  default-key = " n/a ";

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

        #TODO: identify if there is an alternative to gnupg/gpg agents for age based keys.
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
  options.${namespace}.services.openssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure OpenSSH support.";
    authorizedKeys = mkOpt (listOf str) [ default-key ] "The public keys to apply.";
    port = mkOpt port 22022 "The port to listen on (in addition to 22).";
    manage-other-hosts =
      mkOpt bool true "Whether or not to add other host configurations to SSH config.";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;

      settings = {
        PermitRootLogin = if format == "install-iso" then "yes" else "no";
        PasswordAuthentication = false;
      };

      extraConfig = ''
        StreamLocalBindUnlink yes
      '';

      ports = [
        22
        cfg.port
      ];
    };

    programs.ssh.extraConfig = ''
      # Host *
      #   HostKeyAlgorithms +ssh-rsa

      ${optionalString cfg.manage-other-hosts other-hosts-config}
    '';

    spirenix.user.extraOptions.openssh.authorizedKeys.keys = cfg.authorizedKeys;

    spirenix.home.extraOptions = {
      programs.zsh.shellAliases = foldl
        (
          aliases: system: aliases // { "ssh-${system}" = "ssh ${system} -t tmux a"; }
        )
        { }
        (builtins.attrNames other-hosts);
    };
  };
}
