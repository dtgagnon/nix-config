#!/usr/bin/env bash
set -eo pipefail

### UX helpers - Functions for user experience enhancements (colored output, prompts)
### These functions provide colored output to the terminal and handle user prompts.

# --- red function ---
# Outputs text to the terminal in red color, indicating an error or important warning.
# Arguments:
#   $1: Text to be displayed in red.
#   $2 (optional): Command to be executed and its output displayed in red.
function red() {
	echo -e "\x1B[31m[!] $1 \x1B[0m"
	if [ -n "${2-}" ]; then
		echo -e "\x1B[31m[!] $($2) \x1B[0m"
	fi
}

# --- green function ---
# Outputs text to the terminal in green color, typically indicating success or positive feedback.
# Arguments:
#   $1: Text to be displayed in green.
#   $2 (optional): Command to be executed and its output displayed in green.
function green() {
	echo -e "\x1B[32m[+] $1 \x1B[0m"
	if [ -n "${2-}" ]; then
		echo -e "\x1B[32m[+] $($2) \x1B[0m"
	fi
}

# --- blue function ---
# Outputs text to the terminal in blue color, often used for informational messages or prompts.
# Arguments:
#   $1: Text to be displayed in blue.
#   $2 (optional): Command to be executed and its output displayed in blue.
function blue() {
	echo -e "\x1B[34m[*] $1 \x1B[0m"
	if [ -n "${2-}" ]; then
		echo -e "\x1B[34m[*] $($2) \x1B[0m"
	fi
}

# --- yellow function ---
# Outputs text to the terminal in yellow color, usually for warnings or less critical messages than red.
# Arguments:
#   $1: Text to be displayed in yellow.
#   $2 (optional): Command to be executed and its output displayed in yellow.
function yellow() {
	echo -e "\x1B[33m[*] $1 \x1B[0m"
	if [ -n "${2-}" ]; then
		echo -e "\x1B[33m[*] $($2) \x1B[0m"
	fi
}

# --- yes_or_no function ---
# Prompts the user for a yes/no confirmation with "yes" as the default.
# Returns 0 if yes, 1 if no.
# Arguments:
#   $*: The prompt message to display to the user.
function yes_or_no() {
	echo -en "\x1B[34m[?] $* [y/n] (default: y): \x1B[0m"
	while true; do
		read -rp "" yn
		yn=${yn:-y}
		case $yn in
		[Yy]*) return 0 ;; # Return 0 for yes (or any input starting with 'y' or 'Y')
		[Nn]*) return 1 ;; # Return 1 for no (or any input starting with 'n' or 'N')
		esac
	done
}

# --- no_or_yes function ---
# Prompts the user for a yes/no confirmation with "no" as the default.
# Returns 0 if yes, 1 if no.
# Arguments:
#   $*: The prompt message to display to the user.
function no_or_yes() {
	echo -en "\x1B[34m[?] $* [y/n] (default: n): \x1B[0m"
	while true; do
		read -rp "" yn
		yn=${yn:-n}
		case $yn in
		[Yy]*) return 0 ;; # Return 0 for yes (or any input starting with 'y' or 'Y')
		[Nn]*) return 1 ;; # Return 1 for no (or any input starting with 'n' or 'N')
		esac
	done
}

### SOPS helpers - Functions to manage SOPS (Secrets OPerationS) related tasks
### These functions simplify interactions with SOPS for managing encrypted secrets.

# --- SOPS_FILE variable ---
# Defines the path to the main .sops.yaml configuration file.
SOPS_FILE="$(dirname "${BASH_SOURCE[0]}")/../../nix-secrets/.sops.yaml"

# --- sops_update_age_key function ---
# Updates or adds an age key to the .sops.yaml file under either 'hosts' or 'users' key group.
# Arguments:
#   $1: field - Key group ('hosts' or 'users') to update.
#   $2: keyname - Anchor name for the key.
#   $3: key - The age key to add or update.
function sops_update_age_key() {
	field="$1"
	keyname="$2"
	key="$3"

	# Validate the field argument to be either 'hosts' or 'users'.
	if [ ! "$field" == "hosts" ] && [ ! "$field" == "users" ]; then
		red "Invalid field passed to sops_update_age_key. Must be either 'hosts' or 'users'."
		exit 1
	fi

	# Check if a key with the given anchor name already exists in the specified field.
	if [[ -n $(yq ".keys.${field}[] | select(.anchor == \"${keyname}\")" "${SOPS_FILE}") ]]; then
		green "Updating existing ${keyname} key"
		yq -i "(.keys.${field}[] | select(.anchor == \"${keyname}\")) = ${key}" "${SOPS_FILE}" # Update existing key
	else
		green "Adding new ${keyname} key"
		yq -i ".keys.$field += [\"$key\"] | .keys.${field}[-1] anchor = \"$keyname\"" "$SOPS_FILE" # Add new key with anchor
	fi
}

# --- sops_add_shared_creation_rules function ---
# Adds creation rules to .sops.yaml for shared secrets (shared.yaml), ensuring keys for user and host are included.
# Arguments:
#   $1: User identifier.
#   $2: Hostname.
function sops_add_shared_creation_rules() {
	u="\"$1_$2\"" # quoted user_host for yaml
	h="\"$2\""    # quoted hostname for yaml

	shared_selector='.creation_rules[] | select(.path_regex == "shared\.yaml$")' # Selector for shared.yaml rule
	# Check if shared.yaml creation rule exists.
	if [[ -n $(yq "$shared_selector" "${SOPS_FILE}") ]]; then
		echo "BEFORE"
		cat "${SOPS_FILE}"
		# Check if the host's age key alias is already in the shared.yaml rule.
		if [[ -z $(yq "$shared_selector.key_groups[].age[] | select(alias == $h)" "${SOPS_FILE}") ]]; then
			green "Adding $u and $h to shared.yaml rule"
			# NOTE: Split on purpose to avoid weird file corruption
			yq -i "($shared_selector).key_groups[].age += [$u, $h]" "$SOPS_FILE" # Add user and host keys to the rule
			yq -i "($shared_selector).key_groups[].age[-2] alias = $u" "$SOPS_FILE" # Set alias for user key
			yq -i "($shared_selector).key_groups[].age[-1] alias = $h" "$SOPS_FILE" # Set alias for host key
		fi
	else
		red "shared.yaml rule not found" # Error if shared.yaml rule is not found
	fi
}

# --- sops_add_host_creation_rules function ---
# Adds creation rules to .sops.yaml for host-specific secrets (<host>.yaml), including keys for user, host, whoami, and hostname.
# Arguments:
#   $1: User identifier.
#   $2: Hostname.
function sops_add_host_creation_rules() {
	host="$2"                     # hostname for selector
	h="\"$2\""                    # quoted hostname for yaml
	u="\"$1_$2\""                 # quoted user_host for yaml
	w="\"$(whoami)_$(hostname)\"" # quoted whoami_hostname for yaml
	n="\"$(hostname)\""           # quoted hostname for yaml

	host_selector=".creation_rules[] | select(.path_regex | contains(\"${host}\.yaml\"))" # Selector for host-specific rule
	# Check if host-specific creation rule exists.
	if [[ -z $(yq "$host_selector" "${SOPS_FILE}") ]]; then
		green "Adding new host file creation rule"
		yq -i ".creation_rules += {\"path_regex\": \"${host}\\.yaml$\", \"key_groups\": [{\"age\": [$u, $h]}]}" "$SOPS_FILE" # Add new host-specific rule
		# Add aliases one by one
		yq -i "($host_selector).key_groups[].age[0] alias = $u" "$SOPS_FILE" # Set alias for user key
		yq -i "($host_selector).key_groups[].age[1] alias = $h" "$SOPS_FILE" # Set alias for host key
		yq -i "($host_selector).key_groups[].age[2] alias = $w" "$SOPS_FILE" # Set alias for whoami_hostname key
		yq -i "($host_selector).key_groups[].age[3] alias = $n" "$SOPS_FILE" # Set alias for hostname key
	fi
}

# --- sops_add_creation_rules function ---
# Orchestrates adding creation rules for both shared and host-specific secrets files.
# Arguments:
#   $1: User identifier.
#   $2: Hostname.
function sops_add_creation_rules() {
	user="$1"
	host="$2"

	sops_add_shared_creation_rules "$user" "$host" # Add rules for shared.yaml
	sops_add_host_creation_rules "$user" "$host" # Add rules for host-specific yaml
}
