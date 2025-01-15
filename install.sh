#!/usr/bin/env bash

read -p "Enter target IP address: " target_ip

# Deploy using nixos-anywhere
nix run nixpkgs#nixos-anywhere -- \
	--disk-encrption-keys /tmp/root-crypt.key /tmp/root-crypt.key \
	--disk-encrption-keys /tmp/data-crypt.key /tmp/data-crypt.key \
	--flake '.#generic' \
	--generate-hardware-config nixos-generate-config ./systems/x86_64-linux/generic/hardware.nix \
	root@${target_ip}