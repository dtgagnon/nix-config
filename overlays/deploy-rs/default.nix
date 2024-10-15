{ channels, ... }:

final: prev:

{ inherit (channels.nixpkgs) deploy-rs; }
