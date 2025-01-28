{ pkgs
, mkShell
, ...
}:
mkShell {
  nativeBuildInputs = builtins.attrValues {
    inherit (pkgs)
      nix
      home-manager
      git
      just

      age
      ssh-to-age
      sops
      ;
  };
  shellHook = ''
        		export PATH=$PATH:$PATH
        		export OTHER_VAR=''${OTHER_VAR:-$OTHER_VAR}

    				git pull
        	'';
}
