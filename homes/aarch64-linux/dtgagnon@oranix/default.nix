{ lib
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
      email = "gagnon.derek@gmail.com";
    };

    cli = {
      fzf.enable = false;
      git = enabled;
      ssh = enabled;
    };

    security.sops-nix = enabled;
  };

  home.stateVersion = "25.11";
}
