#!/usr/bin/env bash
set -eo pipefail

# Include helpers library for common functions like red, green, blue, yes_or_no, etc.
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# --- User-configurable variables ---
# These variables are set by command-line arguments or environment defaults.
target_hostname="" # Hostname of the target machine
target_destination="" # IP address or domain name of the target machine
target_user=${BOOTSTRAP_USER-$(whoami)} # Username for SSH, defaults to current user or BOOTSTRAP_USER env var
ssh_port=${BOOTSTRAP_SSH_PORT-22} # SSH port, defaults to 22 or BOOTSTRAP_SSH_PORT env var
ssh_key=${BOOTSTRAP_SSH_KEY-} # Path to SSH key, defaults to empty or BOOTSTRAP_SSH_KEY env var
persist_dir="" # Directory for persistent data (used with impermanence)
luks_secondary_drive_labels="" # Comma-separated list of LUKS drive labels for secondary decryption

# --- Temporary directory setup ---
# Create a temporary directory to store generated SSH host keys.
temp=$(mktemp -d)

# --- Cleanup function ---
# Function to remove the temporary directory when the script exits.
function cleanup() {
	rm -rf "$temp"
}
trap cleanup exit

# --- sync function ---
# Copies files to the target machine using rsync over SSH.
# Arguments:
#   $1: user - Username for SSH on the target machine.
#   $2: source - Path to the source directory on the local machine.
#   $3: destination - Path to the destination directory on the target machine (relative to user's home).
function sync() {
	# $1 = user, $2 = source, $3 = destination
	rsync -av --filter=':- .gitignore' -e "ssh -l $1 -oport=${ssh_port}" "$2" "$1@${target_destination}:"
}

# --- help_and_exit function ---
# Displays usage instructions and exits the script.
function help_and_exit() {
	echo
	echo "Remotely installs NixOS on a target machine using this nix-config."
	echo
	echo "USAGE: $0 -n <target_hostname> -d <target_destination> -k <ssh_key> [OPTIONS]"
	echo
	echo "ARGS:"
	echo "  -n <target_hostname>                    specify target_hostname of the target host to deploy the nixos config on."
	echo "  -d <target_destination>                 specify ip or domain to the target host."
	echo "  -k <ssh_key>                            specify the full path to the ssh_key you'll use for remote access to the"
	echo "                                          target during install process."
	echo "                                          Example: -k /home/${target_user}/.ssh/my_ssh_key"
	echo
	echo "OPTIONS:"
	echo "  -u <target_user>                        specify target_user with sudo access. nix-config will be cloned to their home."
	echo "                                          Default='${target_user}'."
	echo "  --port <ssh_port>                       specify the ssh port to use for remote access. Default=${ssh_port}."
	echo '  --luks-secondary-drive-labels <drives>  specify the luks device names (as declared with "disko.devices.disk.*.content.luks.name" in host/common/disks/*.nix) separated by commas.'
	echo '                                          Example: --luks-secondary-drive-labels "cryptprimary,cryptextra"'
	echo "  --impermanence                          Use this flag if the target machine has impermanence enabled. WARNING: Assumes /persist path."
	echo "  --debug                                 Enable debug mode."
	echo "  -h | --help                             Print this help."
	exit 0
}

# --- Argument parsing ---
# Processes command-line arguments to set variables.
while [[ $# -gt 0 ]]; do
	case "$1" in
	-n) # Target hostname
		shift
		target_hostname=$1
		;;
	-d) # Target destination (IP or domain)
		shift
		target_destination=$1
		;;
	-u) # Target user
		shift
		target_user=$1
		;;
	-k) # SSH key path
		shift
		ssh_key=$1
		;;
	--luks-secondary-drive-labels) # LUKS secondary drive labels
		shift
		luks_secondary_drive_labels=$1
		;;
	--port) # SSH port
		shift
		ssh_port=$1
		;;
	--temp-override) # Override temp directory (for debugging)
		shift
		temp=$1
		;;
	--impermanence) # Enable impermanence mode
		persist_dir="/persist"
		;;
	--debug) # Enable debug mode (set -x)
		set -x
		;;
	-h | --help) help_and_exit ;; # Help and exit
	*) # Invalid option
		red "ERROR: Invalid option detected."
		help_and_exit
		;;
	esac
	shift
done

# --- Argument validation ---
# Check if required arguments are provided.
if [ -z "$target_hostname" ] || [ -z "$target_destination" ] || [ -z "$ssh_key" ]; then
	red "ERROR: -n, -d, and -k are all required"
	echo
	help_and_exit
fi

# --- SSH command definitions ---
# Define SSH and SCP command templates for later use.
ssh_cmd="ssh -oControlMaster=no -oport=${ssh_port} -oForwardAgent=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $ssh_key -t $target_user@$target_destination"
# shellcheck disable=SC2001
ssh_root_cmd=$(echo "$ssh_cmd" | sed "s|${target_user}@|root@|") # Create root SSH command by replacing target user with root
scp_cmd="scp -oControlMaster=no -oport=${ssh_port} -o StrictHostKeyChecking=no -i $ssh_key"

# --- Git root directory ---
# Determine the root of the git repository.
git_root=$(git rev-parse --show-toplevel)

# --- nixos_anywhere function ---
# Sets up a minimal environment and runs nixos-anywhere to install NixOS on the target machine.
function nixos_anywhere() {
	# Clear the known_hosts for the target to ensure fresh SSH connection.
	green "Wiping known_hosts of $target_destination"
	sed -i "/$target_hostname/d; /$target_destination/d" ~/.ssh/known_hosts

	green "Installing NixOS on remote host $target_hostname at $target_destination"

	###
	# nixos-anywhere extra-files generation - SSH host key setup
	###
	green "Preparing a new ssh_host_ed25519_key pair for $target_hostname."
	# Create directory for SSH host keys in the temporary directory.
	install -d -m755 "$temp/$persist_dir/etc/ssh"

	# Generate a new SSH host key pair (ed25519) without a passphrase.
	ssh-keygen -t ed25519 -f "$temp/$persist_dir/etc/ssh/ssh_host_ed25519_key" -C "$target_user"@"$target_hostname" -N ""

	# Set permissions for the SSH host key (read/write for owner only).
	chmod 600 "$temp/$persist_dir/etc/ssh/ssh_host_ed25519_key"

	green "Adding ssh host fingerprint at $target_destination to ~/.ssh/known_hosts"
	# Add the target host's fingerprint to known_hosts (ignore errors if already present).
	ssh-keyscan -p "$ssh_port" "$target_destination" | grep -v '^#' >>~/.ssh/known_hosts || true

	###
	# nixos-anywhere installation - Core NixOS installation process
	###
	cd nixos-installer
	# Set temporary LUKS passphrase for disko (will be updated later).
	temp_luks_passphrase="passphrase"
	if no_or_yes "Manually set luks encryption passphrase? (Default: \"$temp_luks_passphrase\")"; then
		blue "Enter your luks encryption passphrase:"
		read -rs luks_passphrase
		$ssh_root_cmd "/bin/sh -c 'echo $luks_passphrase > /tmp/disko-password'" # Send LUKS passphrase to target machine
	else
		green "Using '$temp_luks_passphrase' as the luks encryption passphrase. Change after installation."
		$ssh_root_cmd "/bin/sh -c 'echo $temp_luks_passphrase > /tmp/disko-password'" # Send default LUKS passphrase to target machine
	fi

	# Generate hardware configuration on the target machine if requested.
	if no_or_yes "Generate a new hardware config for this host?\nSay yes only if you don't already have a local hardware-configuration.nix for the target host in your repo."; then
		green "Generating hardware-configuration.nix on $target_hostname and adding it to the local nix-config."
		$ssh_root_cmd "nixos-generate-config --no-filesystems --root /mnt" # Generate hardware config on target
		$scp_cmd root@"$target_destination":/mnt/etc/nixos/hardware-configuration.nix "${git_root}"/hosts/nixos/"$target_hostname"/hardware.nix # Copy hardware config back to local repo
		generated_hardware_config=1 # Flag to indicate hardware config was generated
	fi

	# Run nixos-anywhere to perform the installation.
	# --extra-files includes the generated SSH host keys.
	SHELL=/bin/sh nix run github:nix-community/nixos-anywhere -- --ssh-port "$ssh_port" --post-kexec-ssh-port "$ssh_port" --extra-files "$temp" --flake .#"$target_hostname" root@"$target_destination"

	# Wait for system restart and confirmation to continue.
	if ! yes_or_no "Has your system restarted and are you ready to continue? (no exits)"; then
		exit 0
	fi

	green "Adding $target_destination's ssh host fingerprint to ~/.ssh/known_hosts"
	ssh-keyscan -p "$ssh_port" "$target_destination" | grep -v '^#' >>~/.ssh/known_hosts || true # Add host fingerprint again after reboot

	# Persist machine-id and SSH host keys if persist_dir is set (impermanence).
	if [ -n "$persist_dir" ]; then
		$ssh_root_cmd "cp /etc/machine-id $persist_dir/etc/machine-id || true" # Persist machine-id
		$ssh_root_cmd "cp -R /etc/ssh/ $persist_dir/etc/ssh/ || true" # Persist SSH host keys
	fi
	cd - >/dev/null # Return to previous directory
}

# --- generate_host_age_key function ---
# Generates an age key based on the newly generated SSH host key.
function generate_host_age_key() {
	green "Generating an age key based on the new ssh_host_ed25519_key"

	# Get the SSH host key from the target machine using ssh-keyscan.
	target_key=$(ssh-keyscan -p "$ssh_port" -t ssh-ed25519 "$target_destination" 2>&1 | grep ssh-ed25519 | cut -f2- -d" ") || {
		red "Failed to get ssh key. Host down or maybe SSH port now changed?"
		exit 1
	}

	# Convert the SSH host key to an age key using nix-shell and ssh-to-age.
	host_age_key=$(nix shell nixpkgs#ssh-to-age.out -c sh -c "echo $target_key | ssh-to-age")

	# Validate the format of the generated age key.
	if grep -qv '^age1' <<<"$host_age_key"; then
		red "The result from generated age key does not match the expected format."
		yellow "Result: $host_age_key"
		yellow "Expected format: age10000000000000000000000000000000000000000000000000000000000"
		exit 1
	fi

	green "Updating nix-secrets/.sops.yaml"
	sops_update_age_key "hosts" "$target_hostname" "$host_age_key" # Update .sops.yaml with the new host age key
}

# --- generate_user_age_key function ---
# Generates a new age key for the user if one doesn't exist.
age_secret_key="" # Global variable to store the generated user age secret key
function generate_user_age_key() {
	green "Age key does not exist. Generating."
	user_age_key=$(nix shell nixpkgs#age -c "age-keygen") # Generate a new age key pair
	readarray -t entries <<<"$user_age_key" # Read the output into an array
	age_secret_key=${entries[2]} # Extract the secret key
	public_key=$(echo "${entries[1]}" | rg key: | cut -f2 -d: | xargs) # Extract the public key
	key_name="${target_user}_${target_hostname}" # Construct key name
	green "Generated age key for ${key_name}"
	# Update .sops.yaml with the new user age public key and anchor.
	sops_update_age_key "users" "$key_name" "$public_key"
	sops_add_creation_rules "${target_user}" "${target_hostname}" # Add creation rules for the new user key
}

# --- generate_user_age_key_and_file function ---
# Generates a user age key and creates/updates the host-specific secrets file.
function generate_user_age_key_and_file() {
	# FIXME(starter-repo): remove old secrets.yaml line once starter repo is completed
	#secret_file="${git_root}"/../nix-secrets/secrets.yaml
	secret_file="${git_root}"/../nix-secrets/sops/${target_hostname}.yaml # Path to host-specific secrets file
	config="${git_root}"/../nix-secrets/.sops.yaml # Path to .sops.yaml config file
	# If the secret file doesn't exist, create it and generate a new user key.
	if [ ! -f "$secret_file" ]; then
		green "Host secret file does not exist. Creating $secret_file"
		generate_user_age_key # Generate user age key
		echo "{}" >"$secret_file" # Create empty secrets file
		sops --config "$config" -e "$secret_file" >"$secret_file.enc" # Encrypt the empty file
		mv "$secret_file.enc" "$secret_file" # Replace unencrypted file with encrypted file
	fi
	# Check if age key exists in the secret file, generate if not.
	if ! sops --config "$config" -d --extract '["keys"]["age"]' "$secret_file" >/dev/null 2>&1; then
		if [ -z "$age_secret_key" ]; then
			generate_user_age_key # Generate user age key if not already generated
		fi
		echo "Secret key $age_secret_key"
		# shellcheck disable=SC2116,SC2086
		sops --config "$config" --set "$(echo '["keys"]["age"] "'$age_secret_key'"')" "$secret_file" # Add age key to secrets file
	else
		green "Age key already exists for ${target_hostname}"
	fi
}

# --- setup_luks_secondary_drive_decryption function ---
# Sets up LUKS secondary drive decryption using a keyfile.
function setup_luks_secondary_drive_decryption() {
	green "Generating /luks-secondary-unlock.key"
	local key=${persist_dir}/luks-secondary-unlock.key # Path to LUKS keyfile
	$ssh_root_cmd "/bin/sh -c 'dd bs=512 count=4 if=/dev/random of=$key iflag=fullblock && chmod 400 $key'" # Generate random keyfile on target
	# Add the keyfile as a LUKS key for specified secondary drives.
	green "Cryptsetup luksAddKey will now be used to add /luks-secondary-unlock.key for the specified secondary drive names."
	readarray -td, drivenames <<<"$luks_secondary_drive_labels" # Split comma-separated drive labels into array
	for name in "${drivenames[@]}"; do
		device_path=$($ssh_root_cmd -q "/bin/sh -c 'cryptsetup status \"$name\" | awk \'/device:/ {print \$2}\''") # Get device path for LUKS device
		$ssh_root_cmd "/bin/sh -c 'echo \"$luks_passphrase\" | cryptsetup luksAddKey $device_path /luks-secondary-unlock.key'" # Add keyfile as LUKS key
	done
}

# --- Option validation (repeated, might be redundant) ---
# FIXME(bootstrap): The ssh key and destination aren't required if only rekeying, so could be moved into specific sections?
if [ -z "${target_hostname}" ] || [ -z "${target_destination}" ] || [ -z "${ssh_key}" ]; then
	red "ERROR: -n, -d, and -k are all required"
	echo
	help_and_exit
fi

# --- Interactive prompts for actions ---
# Conditional execution of different script sections based on user prompts.
if yes_or_no "Run nixos-anywhere installation?"; then
	nixos_anywhere # Run NixOS installation if user confirms
fi

if yes_or_no "Generate host (ssh-based) age key?"; then
	generate_host_age_key # Generate host age key if user confirms
	updated_age_keys=1 # Flag to indicate age keys were updated
fi

if yes_or_no "Generate user age key?"; then
	# This may end up creating the host.yaml file, so add creation rules in advance
	generate_user_age_key_and_file # Generate user age key and file if user confirms
	updated_age_keys=1 # Flag to indicate age keys were updated
fi

# --- Post-age key generation actions ---
# Actions to perform if age keys were generated or updated.
if [[ $updated_age_keys == 1 ]]; then
	# If age keys were updated, add creation rules to .sops.yaml.
	# to some creation rules, namely <host>.yaml and shared.yaml
	sops_add_creation_rules "${target_user}" "${target_hostname}"
	# Rekey secrets to apply new age keys.
	just rekey
	green "Updating flake input to pick up new .sops.yaml"
	nix flake update nix-secrets # Update flake input to reflect changes in .sops.yaml
fi

# --- Git host fingerprint setup ---
# Add SSH host fingerprints for GitLab and GitHub to known_hosts on the target machine.
green "NOTE: If this is the first time running this script on $target_hostname, the next step is required to continue"
if yes_or_no "Add ssh host fingerprints for git{lab,hub}?"; then
	if [ "$target_user" == "root" ]; then
		home_path="/root" # Use root's home directory if target user is root
	else
		home_path="/home/$target_user" # Otherwise use target user's home directory
	fi
	green "Adding ssh host fingerprints for git{lab,hub}"
	$ssh_cmd "mkdir -p $home_path/.ssh/; ssh-keyscan -t ssh-ed25519 gitlab.com github.com 2>/dev/null | grep -v '^#' >>$home_path/.ssh/known_hosts" # Add gitlab.com and github.com host keys
fi

# --- Copy nix-config and nix-secrets ---
# Optionally copy the full nix-config and nix-secrets to the target machine.
if yes_or_no "Do you want to copy your full nix-config and nix-secrets to $target_hostname?"; then
	green "Adding ssh host fingerprint at $target_destination to ~/.ssh/known_hosts"
	ssh-keyscan -p "$ssh_port" "$target_destination" 2>/dev/null | grep -v '^#' >>~/.ssh/known_hosts || true # Add host fingerprint again before copying
	green "Copying full nix-config to $target_hostname"
	sync "$target_user" "${git_root}"/../nixos # Copy nixos directory
	green "Copying full nix-secrets to $target_hostname"
	sync "$target_user" "${git_root}"/../nix-secrets # Copy nix-secrets directory

	# FIXME(bootstrap): Add some sort of key access from the target to download the config (if it's a cloud system)
	if yes_or_no "Do you want to rebuild immediately? (requires yubikey-agent)"; then
		green "Rebuilding nix-config on $target_hostname"
		$ssh_cmd "cd nixos && sudo nixos-rebuild --impure --show-trace --flake .#$target_hostname switch" # Rebuild NixOS configuration on target
	fi
else
	echo
	green "NixOS was successfully installed!"
	echo "Post-install config build instructions:"
	echo "To copy nix-config from this machine to the $target_hostname, run the following command"
	echo "just sync $target_user $target_destination"
	echo "To rebuild, sign into $target_hostname and run the following command"
	echo "cd nixos"
	echo "sudo nixos-rebuild --show-trace --flake .#$target_hostname switch"
	echo
fi

# --- Commit and push hardware-configuration.nix ---
# Optionally commit and push the generated hardware-configuration.nix to the git repository.
if [[ $generated_hardware_config == 1 ]]; then
	if yes_or_no "Do you want to commit and push the generated hardware-configuration.nix for $target_hostname to nix-config?"; then
		(pre-commit run --all-files 2>/dev/null || true) && # Run pre-commit hooks
			git add "$git_root/hosts/$target_hostname/hardware-configuration.nix" && (git commit -m "feat: hardware-configuration.nix for $target_hostname" || true) && git push # Add, commit, and push hardware config
	fi
fi

# --- Success message ---
green "Success!"
