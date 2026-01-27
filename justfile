SOPS_FILE := "../nix-secrets/.sops.yaml"
YQ := "nix run nixpkgs#yq-go --"

# default recipe to display help information
default:
  @just --list

check:
  nix flake check --keep-going

check-trace:
  nix flake check --show-trace

update:
  nix flake update

diff:
  git diff ':!flake.lock'

age-key:
  nix shell nixpkgs#age -c age-keygen

update-nix-secrets:
  @(cd ~/src/nix/nix-secrets && git fetch && git rebase > /dev/null) || true
  nix flake update nix-secrets --timeout 5

iso:
  # If we dont remove this folder, libvirtd VM doesnt run with the new iso...
  rm -rf result
  nix build .#nixosConfigurations.iso.config.system.build.isoImage && ln -sf result/iso/*.iso latest.iso

iso-install DRIVE: iso
  sudo dd if=$(eza --sort changed result/iso/*.iso | tail -n1) of={{DRIVE}} bs=4M status=progress oflag=sync

disko DRIVE PASSWORD:
  echo "{{PASSWORD}}" > /tmp/disko-password
  sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
    --mode disko \
    disks/btrfs-luks-impermanence-disko.nix \
    --arg disk '"{{DRIVE}}"' \
    --arg password '"{{PASSWORD}}"'
  rm /tmp/disko-password

sync USER HOST PATH:
	rsync -av --filter=':- .gitignore' -e "ssh -l {{USER}} -oport=22" . {{USER}}@{{HOST}}:{{PATH}}/nix-config

# Build local, target remote - requires local cross-compilation (binfmt) for different architectures
bltr HOST USER="dtgagnon":
	nixos-rebuild switch --flake .#{{HOST}} --target-host {{USER}}@{{HOST}} --sudo --show-trace

# Build remote, target remote - sources copied to remote, built natively there
brtr HOST USER="dtgagnon":
	nixos-rebuild switch --flake .#{{HOST}} --target-host {{USER}}@{{HOST}} --build-host {{USER}}@{{HOST}} --sudo

#
# ========== Nix-Secrets manipulation recipes ==========
#

# Update all keys in yaml files in nix-secrets to match the creation rules keys
rekey:
  cd ../nix-secrets && \
    for file in $(find . -name "*.yaml" -not -name ".sops.yaml"); do \
      echo "Rekeying $file" && \
      nix run nixpkgs#sops -- updatekeys -y "$file"; \
    done && \
    git add -u && (git commit -m "chore: rekey" || true) && git push

# Update an age key anchor or add a new one
update-age-key FIELD KEYNAME KEY:
    # NOTE: Due to quirks this is purposefully not using a single yq expression
    if [[ -n "$({{YQ}} '(.keys.{{FIELD}}[] | select(anchor == "{{KEYNAME}}"))' {{SOPS_FILE}})" ]]; then \
        echo "Updating existing key" && \
        {{YQ}} -i '(.keys.{{FIELD}}[] | select(anchor == "{{KEYNAME}}")) = "{{KEY}}"' {{SOPS_FILE}}; \
    else \
        echo "Adding new key" && \
        {{YQ}} -i '.keys.{{FIELD}} += ["{{KEY}}"] | .keys.{{FIELD}}[-1] anchor = "{{KEYNAME}}"' {{SOPS_FILE}}; \
    fi

# Update an existing user age key anchor or add a new one
update-user-age-key USER HOST KEY:
  just update-age-key users {{USER}}_{{HOST}} {{KEY}}

# Update an existing host age key anchor or add a new one
update-host-age-key HOST KEY:
  just update-age-key hosts {{HOST}} {{KEY}}

# Automatically create or update a host.yaml creation rule
add-host-sops-file USER HOST:
    if [[ -z "$({{YQ}} '.creation_rules[] | select(.path_regex | contains("{{HOST}}\\.yaml"))' {{SOPS_FILE}})" ]]; then \
        echo "Adding new host file creation rule" && \
        {{YQ}} -i '.creation_rules += {"path_regex": "sops/{{HOST}}\.yaml$", "key_groups": [{"age": ["{{USER}}", "{{HOST}}"]}]}' {{SOPS_FILE}} && \
        {{YQ}} -i '(.creation_rules[] | select(.path_regex | contains("{{HOST}}\\.yaml"))).key_groups[].age[0] alias = "{{USER}}"' {{SOPS_FILE}} && \
        {{YQ}} -i '(.creation_rules[] | select(.path_regex | contains("{{HOST}}\\.yaml"))).key_groups[].age[1] alias = "{{HOST}}"' {{SOPS_FILE}}; \
    elif [[ -z "$({{YQ}} '.creation_rules[] | select(.path_regex | contains("{{HOST}}\\.yaml")).key_groups[].age[] | select(alias == "{{HOST}}")' {{SOPS_FILE}})" ]]; then \
        echo "Adding {{HOST}} key to existing creation rule" && \
        {{YQ}} -i '(.creation_rules[] | select(.path_regex | contains("{{HOST}}\\.yaml"))).key_groups[].age += ["{{HOST}}"]' {{SOPS_FILE}} && \
        {{YQ}} -i '(.creation_rules[] | select(.path_regex | contains("{{HOST}}\\.yaml"))).key_groups[].age[-1] alias = "{{HOST}}"' {{SOPS_FILE}}; \
    else \
        echo "Host key already exists in creation rule"; \
    fi

# Automatically add the host key to the shared.yaml creation rule
add-to-shared USER HOST:
    if [[ -n "$({{YQ}} '.creation_rules[] | select(.path_regex == "shared\\.yaml$")' {{SOPS_FILE}})" ]]; then \
        if [[ -z "$({{YQ}} '.creation_rules[] | select(.path_regex == "shared\\.yaml$").key_groups[].age[] | select(alias == "{{HOST}}")' {{SOPS_FILE}})" ]]; then \
            echo "Adding {{HOST}} to shared.yaml rule" && \
            {{YQ}} -i '(.creation_rules[] | select(.path_regex == "shared\\.yaml$")).key_groups[].age += ["{{HOST}}"]' {{SOPS_FILE}} && \
            {{YQ}} -i '(.creation_rules[] | select(.path_regex == "shared\\.yaml$")).key_groups[].age[-1] alias = "{{HOST}}"' {{SOPS_FILE}}; \
        else \
            echo "Host key already exists in shared.yaml rule"; \
        fi; \
    else \
        echo "shared.yaml rule not found"; \
    fi

# Automatically add the host and user keys to creation rules for shared.yaml and <host>.yaml
add-creation-rules USER HOST:
    just add-host-sops-file {{USER}} {{HOST}} && \
    just add-to-shared {{USER}} {{HOST}}

#
# ========== Remote Deployment Recipes ==========
#
# These recipes automate NixOS deployment with sops-nix secrets bootstrapping.
# SSH host keys are pre-generated and injected, with age keys derived and added
# to .sops.yaml before deployment so secrets decrypt on first boot.

# Deploy NixOS to a remote host via nixos-anywhere (no LUKS)
# Usage: just deploy oranix oranix-2.example.com ubuntu
deploy HOST TARGET USER="ubuntu" PERSIST_DIR="":
    #!/usr/bin/env bash
    set -euo pipefail

    temp=$(mktemp -d)
    trap "rm -rf $temp" EXIT

    # Determine SSH key path (with optional impermanence)
    ssh_dir="$temp{{PERSIST_DIR}}/etc/ssh"

    # Generate SSH host key
    echo -e "\x1B[32m[+] Generating SSH host key for {{HOST}}...\x1B[0m"
    install -d -m755 "$ssh_dir"
    ssh-keygen -t ed25519 -f "$ssh_dir/ssh_host_ed25519_key" -N "" -C "{{HOST}}"
    chmod 600 "$ssh_dir/ssh_host_ed25519_key"

    # Derive age key from SSH public key
    echo -e "\x1B[32m[+] Deriving age public key...\x1B[0m"
    AGE_KEY=$(cat "$ssh_dir/ssh_host_ed25519_key.pub" | nix shell nixpkgs#ssh-to-age -c ssh-to-age)
    echo -e "\x1B[34m[*] Age key: $AGE_KEY\x1B[0m"

    # Update sops configuration
    echo -e "\x1B[32m[+] Updating .sops.yaml with host age key...\x1B[0m"
    just update-host-age-key {{HOST}} "$AGE_KEY"
    just add-creation-rules dtgagnon {{HOST}}

    # Rekey secrets with new host key
    echo -e "\x1B[32m[+] Rekeying secrets...\x1B[0m"
    just rekey

    # Update flake lock to pick up new .sops.yaml
    echo -e "\x1B[32m[+] Updating nix-secrets flake input...\x1B[0m"
    nix flake update nix-secrets

    # Clear known_hosts entries for target
    echo -e "\x1B[32m[+] Clearing known_hosts for {{TARGET}}...\x1B[0m"
    sed -i "/{{HOST}}/d; /{{TARGET}}/d" ~/.ssh/known_hosts 2>/dev/null || true

    # Deploy with nixos-anywhere
    echo -e "\x1B[32m[+] Deploying {{HOST}} to {{TARGET}}...\x1B[0m"
    nix run github:nix-community/nixos-anywhere -- \
        --extra-files "$temp" \
        --flake .#{{HOST}} \
        {{USER}}@{{TARGET}}

    echo -e "\x1B[32m[+] Done! Verify with: ssh root@{{TARGET}} 'systemctl status sops-nix'\x1B[0m"

# Deploy NixOS to a VPS/cloud host (no LUKS, with impermanence)
# Usage: just deploy-vps oranix oranix-2.example.com ubuntu
deploy-vps HOST TARGET USER="ubuntu": (deploy HOST TARGET USER "/persist")

# Deploy NixOS with LUKS encryption (bare metal)
# Usage: just deploy-luks newhost 192.168.1.100 "my-luks-password" nixos
deploy-luks HOST TARGET PASSWORD USER="nixos" PERSIST_DIR="/persist":
    #!/usr/bin/env bash
    set -euo pipefail

    temp=$(mktemp -d)
    trap "rm -rf $temp" EXIT

    # Determine SSH key path (with impermanence)
    ssh_dir="$temp{{PERSIST_DIR}}/etc/ssh"

    # Generate SSH host key
    echo -e "\x1B[32m[+] Generating SSH host key for {{HOST}}...\x1B[0m"
    install -d -m755 "$ssh_dir"
    ssh-keygen -t ed25519 -f "$ssh_dir/ssh_host_ed25519_key" -N "" -C "{{HOST}}"
    chmod 600 "$ssh_dir/ssh_host_ed25519_key"

    # Derive age key from SSH public key
    echo -e "\x1B[32m[+] Deriving age public key...\x1B[0m"
    AGE_KEY=$(cat "$ssh_dir/ssh_host_ed25519_key.pub" | nix shell nixpkgs#ssh-to-age -c ssh-to-age)
    echo -e "\x1B[34m[*] Age key: $AGE_KEY\x1B[0m"

    # Update sops configuration
    echo -e "\x1B[32m[+] Updating .sops.yaml with host age key...\x1B[0m"
    just update-host-age-key {{HOST}} "$AGE_KEY"
    just add-creation-rules dtgagnon {{HOST}}

    # Rekey secrets with new host key
    echo -e "\x1B[32m[+] Rekeying secrets...\x1B[0m"
    just rekey

    # Update flake lock to pick up new .sops.yaml
    echo -e "\x1B[32m[+] Updating nix-secrets flake input...\x1B[0m"
    nix flake update nix-secrets

    # Clear known_hosts entries for target
    echo -e "\x1B[32m[+] Clearing known_hosts for {{TARGET}}...\x1B[0m"
    sed -i "/{{HOST}}/d; /{{TARGET}}/d" ~/.ssh/known_hosts 2>/dev/null || true

    # Deploy with nixos-anywhere and LUKS password
    echo -e "\x1B[32m[+] Deploying {{HOST}} to {{TARGET}} with LUKS...\x1B[0m"
    nix run github:nix-community/nixos-anywhere -- \
        --extra-files "$temp" \
        --disk-encryption-keys /tmp/disko-password <(echo "{{PASSWORD}}") \
        --flake .#{{HOST}} \
        {{USER}}@{{TARGET}}

    echo -e "\x1B[32m[+] Done! Verify with: ssh root@{{TARGET}} 'systemctl status sops-nix'\x1B[0m"

# Derive and display age key from a remote host's SSH key (for existing hosts)
# Usage: just derive-age-key hostname.example.com
derive-age-key TARGET PORT="22":
    #!/usr/bin/env bash
    set -euo pipefail
    target_key=$(ssh-keyscan -p {{PORT}} -t ssh-ed25519 {{TARGET}} 2>&1 | grep ssh-ed25519 | cut -f2- -d" ")
    if [ -z "$target_key" ]; then
        echo -e "\x1B[31m[!] Failed to get SSH key from {{TARGET}}\x1B[0m"
        exit 1
    fi
    age_key=$(echo "$target_key" | nix shell nixpkgs#ssh-to-age -c ssh-to-age)
    echo -e "\x1B[32m[+] Age key for {{TARGET}}:\x1B[0m"
    echo "$age_key"

# Register an existing host's SSH key with sops (for manual bootstrapping)
# Usage: just register-host-key hostname hostname.example.com
register-host-key HOST TARGET PORT="22":
    #!/usr/bin/env bash
    set -euo pipefail
    echo -e "\x1B[32m[+] Fetching SSH key from {{TARGET}}...\x1B[0m"
    target_key=$(ssh-keyscan -p {{PORT}} -t ssh-ed25519 {{TARGET}} 2>&1 | grep ssh-ed25519 | cut -f2- -d" ")
    if [ -z "$target_key" ]; then
        echo -e "\x1B[31m[!] Failed to get SSH key from {{TARGET}}\x1B[0m"
        exit 1
    fi
    AGE_KEY=$(echo "$target_key" | nix shell nixpkgs#ssh-to-age -c ssh-to-age)
    echo -e "\x1B[34m[*] Age key: $AGE_KEY\x1B[0m"

    echo -e "\x1B[32m[+] Updating .sops.yaml...\x1B[0m"
    just update-host-age-key {{HOST}} "$AGE_KEY"
    just add-creation-rules dtgagnon {{HOST}}

    echo -e "\x1B[32m[+] Rekeying secrets...\x1B[0m"
    just rekey

    echo -e "\x1B[32m[+] Updating nix-secrets flake input...\x1B[0m"
    nix flake update nix-secrets

    echo -e "\x1B[32m[+] Done! Host {{HOST}} is now registered for sops-nix.\x1B[0m"
