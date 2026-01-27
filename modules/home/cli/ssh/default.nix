{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.cli.ssh;
  username = config.${namespace}.user.name;
in
{
  options.${namespace}.cli.ssh = {
    enable = mkBoolOpt true "Enable ssh";
    extraIdentityFiles = mkOpt (types.listOf types.str) [ ] "Additional identity file paths to try after the default, in order given.";
  };

  config = mkIf cfg.enable {
    programs.ssh = { };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          # Auth + access
          identitiesOnly = true;
          identityFile = [ "~/.ssh/${username}-key" ] ++ cfg.extraIdentityFiles;
          addKeysToAgent = "yes";
          #NOTE Use a specific agent if you have one (1Password, gnome-keyring, etc.)
          # identityAgent = "~/.1password/agent.sock";

          # Speed + stability
          compression = false;
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";

          # Host key UX
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";

          # Safety
          forwardAgent = false;
          forwardX11 = false;
          forwardX11Trusted = false;

          extraOptions = {
            HostKeyAlgorithms = "ssh-ed25519";
            StrictHostKeyChecking = "accept-new";
            UpdateHostKeys = "yes";
            PreferredAuthentications = "publickey";
            TCPKeepAlive = "yes";
          };
        };

        "*.ts.net" = {
          controlMaster = "auto";
          controlPersist = "10m";
          serverAliveInterval = 60;
          serverAliveCountMax = 3;
          checkHostIP = false;
          addressFamily = "any"; # use v4+v6 over tailnet
          forwardAgent = true; # enable pam-rssh sudo authentication
        };
      };
    };

    home.file = {
      ".ssh/config.d/.keep".text = "# Managed by home-manager";
      ".ssh/sockets/.keep".text = "# Managed by home-manager";
    };

    spirenix.preservation.directories = [
      { directory = ".ssh"; mode = "0700"; }
    ];
  };
}
