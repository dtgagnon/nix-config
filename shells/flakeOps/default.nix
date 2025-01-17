{ pkgs
, mkShell
, ...
}:
mkShell {
  NIX_CONFIG = "extra-experimental-features = nix-command flakes";

  nativeBuildInputs = builtins.attrValues {
    inherit (pkgs)
      nix
      home-manager
      git
      just
      pre-commit
      deadnix

      age
      ssh-to-age
      sops
      ;
  };
}
