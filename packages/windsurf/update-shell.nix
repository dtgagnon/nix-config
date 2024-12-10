{
  lib,
  pkgs,
  ...
}:
lib.mkShell {
	packages = with pkgs; [
		bash
		curl
		gawk
		gnugrep
		gnused
		jq
		nix
		nix-prefetch
		nix-prefetch-scripts
	];
}
