nix-shell -p nix-update --run "nix-update opencoe --flake --override-filename packages/opencode/default.nix --subpackage tui --subpackage node_modules"
