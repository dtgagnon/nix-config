{ pkgs
, mkShell
, ...
}:
mkShell {
  NIX_CONFIG = "extra-experimental-features = nix-command flakes pipe-operators";
  BOOTSTRAP_USER = "dtgagnon";
  BOOTSTRAP_SSH_PORT = "22";
  BOOTSTRAP_SSH_KEY = "~/.ssh/dtgagnon-key";

  nativeBuildInputs = builtins.attrValues {
    inherit (pkgs)
      nix
      home-manager
      git
      just
      pre-commit
      deadnix
      yq-go

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
