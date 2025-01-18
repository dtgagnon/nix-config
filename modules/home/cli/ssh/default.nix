{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  cfg = config.${namespace}.cli.ssh;
in
{
  options.${namespace}.cli.ssh = {
    enable = mkBoolOpt true "Enable ssh";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      addKeysToAgent = "yes";
      extraConfig = ''
        Host *
          HostKeyAlgorithms ssh-ed25519
      '';
    };

    home.file = {
      ".ssh/config.d/.keep".text = "# Managed by home-manager";
      ".ssh/sockets/.keep".text = "# Managed by home-manager";
    };
  };
}
