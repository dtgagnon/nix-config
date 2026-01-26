{ lib
, pkgs
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled;
in
{
  spirenix = {
    user = {
      fullName = "Derek Gagnon";
      email = "dtgagnon@dtgengineering.com";
    };

    preservation.directories = [
      "nix-config"
      { directory = ".ssh"; mode = "0700"; } # For authorized_keys (incoming SSH)
    ];

    cli = {
      eza = enabled;
      fastfetch = enabled;
      fzf = enabled;
      git = enabled;
      ssh.enable = false;
      yazi = enabled;
      zoxide = enabled;
    };

    security.sops-nix = enabled;
  };

  home.packages = [ pkgs.vim ];
  home.stateVersion = "25.11";
}
