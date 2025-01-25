{ pkgs
, mkShell
, ...
}:
mkShell {
  NIX_CONFIG = "extra-experimental-features = nix-command flakes pipe-operators";

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
  shellHook = ''
    		export PATH=$PATH:$PATH
    		export OTHER_VAR=''${OTHER_VAR:-$OTHER_VAR}
    	'';
}
