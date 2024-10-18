{
  description = "Development environment flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    stablePkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    snowfall-lib.url = "github:snowfallorg/lib";
    snowfall-lib.inputs.nixpkgs.follows = "stablePkgs";
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      src = ./.;
      snowfall.namespace = "define project namespace";
    };
}
