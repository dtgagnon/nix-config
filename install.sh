#!/usr/bin/env bash

read -p "Enter target IP address: " target_ip

# Deploy using nixos-anywhere
nix run nixpkgs#nixos-anywhere -- \
	--disk-encryption-keys /tmp/root-crypt.key /tmp/root-crypt.key \
	--disk-encryption-keys /tmp/data-crypt.key /tmp/data-crypt.key \
	--generate-hardware-config nixos-generate-config ./systems/x86_64-linux/generic/hardware.nix \
	--flake '.#generic' \
	--target-host root@${target_ip}
