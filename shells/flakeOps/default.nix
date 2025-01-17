{ pkgs
, checks
, mkShell
, ...
}:
mkShell {
  NIX_CONFIG = "extra-experimental-features = nix-command flakes";

  inherit (checks.pre-commit-check) shellHook;
  buildInputs = checks.pre-commit-check.enabledPackages;

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
