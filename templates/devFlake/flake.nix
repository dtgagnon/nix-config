{
  description = "Development environment flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs
            ungoogled-chromium
          ];
          shellHook = ''
            export PUPPETEER_EXECUTABLE_PATH="${pkgs.ungoogled-chromium}/bin/chromium"

            ## === GEMINI-CLI CONFIG/ENVIRONMENT === ##
            # Check and create .gemini directory
            if [ ! -d ".gemini" ]; then
              mkdir -p ".gemini"
            fi

            # Check and create .gemini/settings.json with example environment variable configuration
            if [ ! -f ".gemini/settings.json" ]; then
              cat <<EOF > .gemini/settings.json
                {
                  "PATH": "${pkgs.nodejs}/bin:\$PATH",
                }
              EOF
            fi
          '';
        };
      }
    );
}
