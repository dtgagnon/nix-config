#!/usr/bin/env bash

read -p "Enter target IP address: " target_ip
read -p "Enter system configuration to build: " system_config

# Deploy using nixos-anywhere
SHELL=/bin/sh nix run nixpkgs#nixos-anywhere -- \
	--disk-encryption-keys /tmp/root-crypt.key /persist/root-crypt.key \
	--disk-encryption-keys /tmp/data-crypt.key /persist/data-crypt.key \
	# --generate-hardware-config nixos-generate-config ./systems/x86_64-linux/${system_config}/hardware.nix \
	--flake .#${system_config} \
	--target-host root@${target_ip}
