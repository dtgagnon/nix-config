{ pkgs
, mkShell
, ...
}:

mkShell {
  packages = with pkgs; [
    aider-chat
  ];

  buildNativeInputs = with pkgs; [
    ## List packages needed to build the application.
  ];

  buildInputs = with pkgs; [
    ## List packages needed to run the built application.
  ];

  shellHook = ''
    		if [ ! -f "./aider.conf.yml" ]; then
    			echo "Generating aider environment files..."

    			cat <<EOF > ./.aiderignore
    				.aider*
    			EOF

    			cat <<EOF > ./aider.conf.yml
    				### // insert full configuration details here.
    			EOF
    		fi
    	'';

}
