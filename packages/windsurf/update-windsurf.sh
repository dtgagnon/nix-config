#!/usr/bin/env bash
#! nix-shell update-shell.nix -i bash

# Update script for the windsurf package, including vscode versions and hashes.
# Usually doesn't need to be called by hand,
# but is called by a bot: https://github.com/samuela/nixpkgs-upkeep/actions
# Call it by hand if the bot fails to automatically update the versions.

set -euo pipefail

# Directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Supported platforms
declare -A platforms=(
    ["x86_64-linux"]="linux-x64"
    # Uncomment when supported
    # ["x86_64-darwin"]="macos-x64"
    # ["aarch64-linux"]="linux-arm64"
    # ["aarch64-darwin"]="macos-arm64"
    # ["armv7l-linux"]="linux-armhf"
)

# Get latest version from API json
get_latest_version() {
    local plat="$1"
    curl -s "https://windsurf-stable.codeium.com/api/update/$plat/stable/latest" | jq -r ".windsurfVersion"
}

# Get commit hash from API json
get_commit_hash() {
    local plat="$1"
    local version="$2"
    curl -s "https://windsurf-stable.codeium.com/api/update/$plat/stable/latest" | jq -r ".version"
}

# Get sha256hash from API json
get_sha256_hash() {
		local plat="$1"
    curl -s "https://windsurf-stable.codeium.com/api/update/$plat/stable/latest" | jq -r ".sha256hash"
}

# Main update function
update_package() {
    echo "Updating Windsurf package..."

    # Get version info for linux-x64 (primary platform)
    local version
    version=$(get_latest_version "linux-x64")
    echo "Latest version: $version"

    local commit_hash
    commit_hash=$(get_commit_hash "linux-x64" "$version")
    echo "Commit hash: $commit_hash"

		local sha256_hash
		sha256_hash=$(get_sha256_hash "linux-x64")
		echo "sha256 hash: $sha256_hash"

    # Update default.nix
    local default_nix="$SCRIPT_DIR/default.nix"
    sed -i "s/version = \".*\"/version = \"$version\"/" "$default_nix"
    sed -i "s|/stable/[a-f0-9]\{40\}/|/stable/$commit_hash/|" "$default_nix"
		sed -i "s/x86_64-linux = \".*\"/x86_64-linux = \"$sha256_hash\"/" "$default_nix"

    echo "Update complete!"
}

# Run the update
update_package
