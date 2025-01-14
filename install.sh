#!/usr/bin/env bash

# Create a temporary directory
temp=$(mktemp -d)

# Function to cleanup temporary directory on exit
cleanup() {
  rm -rf "$temp"
}
trap cleanup EXIT

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/etc/ssh"

# Decrypt your private key from the password store and copy it to the temporary directory
sops ssh_host_ed25519_key > "$temp/etc/ssh/ssh_host_ed25519_key"

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"


# Deploy using nixos-anywhere
nixos-anywhere \
	--disk-encrption-keys /tmp/root-crypt.key /tmp/root-crypt.key \
	--disk-encrption-keys /tmp/data-crypt.key /tmp/data-crypt.key \
	--flake '.#generic' \
	root@100.118.81.33
