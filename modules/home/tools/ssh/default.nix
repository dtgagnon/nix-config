{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.tools.ssh;
in
{
  options.${namespace}.tools.ssh = {
    enable = mkBoolOpt true "Enable ssh";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      addKeysToAgent = "yes";
      extraConfig = ''
        Host *
          HostKeyAlgorithms +ssh-ed25519
      '';

      matchBlocks = {
        "git" = {
          host = "github.com gitlab.com";
          user = "git";
          forwardAgent = true;
          identitiesOnly = true;
          identityFile = "~/.ssh/dtgagnon-ssh";
        };
      };
    };

    home.file = {
      ".ssh/config.d/.keep".text = "# Managed by home-manager";
      ".ssh/sockets/.keep".text = "# Managed by home-manager";
    };
  };
}
