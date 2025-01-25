SOPS_FILE := "../nix-secrets/.sops.yaml"

# default recipe to display help information
default:
  @just --list

rebuild-pre: update-nix-secrets
  @git add --intent-to-add .

rebuild-post:
  just check-sops

build: rebuild

check:
  nix flake check --impure --keep-going
  cd nixos-installer && nix flake check --impure --keep-going

check-trace:
  nix flake check --impure --show-trace
  cd nixos-installer && nix flake check --impure --show-trace

# NOTE: Add --option eval-cache false if you end up caching a failure you can't get around
rebuild: rebuild-pre
  scripts/system-flake-rebuild.sh

# Requires sops to be running and you must have reboot after initial rebuild
rebuild-full: rebuild-pre && rebuild-post
  scripts/system-flake-rebuild.sh

# Requires sops to be running and you must have reboot after initial rebuild
rebuild-trace: rebuild-pre && rebuild-post
  scripts/system-flake-rebuild-trace.sh

update:
  nix flake update

rebuild-update: update rebuild

diff:
  git diff ':!flake.lock'

age-key:
  nix-shell -p age --run "age-keygen"

check-sops:
  scripts/check-sops.sh

update-nix-secrets:
  @(cd ~/src/nix/nix-secrets && git fetch && git rebase > /dev/null) || true
  nix flake update nix-secrets --timeout 5

iso:
  # If we dont remove this folder, libvirtd VM doesnt run with the new iso...
  rm -rf result
  nix build --impure .#nixosConfigurations.iso.config.system.build.isoImage && ln -sf result/iso/*.iso latest.iso

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

build-host HOST:
	NIX_SSHOPTS="-p22" nixos-rebuild --target-host {{HOST}} --use-remote-sudo --show-trace --impure --flake .#"{{HOST}}" switch

#
# ========== Nix-Secrets manipulation recipes ==========
#

# Update all keys in sops/*.yaml files in nix-secrets to match the creation rules keys
rekey:
  cd ../nix-secrets && for file in $(ls *.yaml); do \
    sops updatekeys -y $file; \
  done && \
    (pre-commit run --all-files || true) && \
    git add -u && (git commit -nm "chore: rekey" || true) && git push

# Update an age key anchor or add a new one
update-age-key FIELD KEYNAME KEY:
    # NOTE: Due to quirks this is purposefully not using a single yq expression
    if [[ -n "$(yq '(.keys.{{FIELD}}[] | select(anchor == "{{KEYNAME}}"))' {{SOPS_FILE}})" ]]; then \
        echo "Updating existing key" && \
        yq -i '(.keys.{{FIELD}}[] | select(anchor == "{{KEYNAME}}")) = "{{KEY}}"' {{SOPS_FILE}}; \
    else \
        echo "Adding new key" && \
        yq -i '.keys.{{FIELD}} += ["{{KEY}}"] | .keys.{{FIELD}}[-1] anchor = "{{KEYNAME}}"' {{SOPS_FILE}}; \
    fi

# Update an existing user age key anchor or add a new one
update-user-age-key USER HOST KEY:
  just update-age-key users {{USER}}_{{HOST}} {{KEY}}

# Update an existing host age key anchor or add a new one
update-host-age-key HOST KEY:
  just update-age-key hosts {{HOST}} {{KEY}}

# Automatically create a host.yaml file for host-specific secrets
add-host-sops-file USER HOST:
    if [[ -z "$(yq '.creation_rules[] | select(.path_regex | contains("{{HOST}}\\.yaml"))' {{SOPS_FILE}})" ]]; then \
        echo "Adding new host file creation rule" && \
        yq -i '.creation_rules += {"path_regex": "{{HOST}}\.yaml$", "key_groups": [{"age": ["{{USER}}_{{HOST}}", "{{HOST}}"]}]}' {{SOPS_FILE}} && \
        yq -i '(.creation_rules[] | select(.path_regex == "{{HOST}}\.yaml$")).key_groups[].age[0] alias = "{{USER}}_{{HOST}}"' {{SOPS_FILE}} && \
        yq -i '(.creation_rules[] | select(.path_regex == "{{HOST}}\.yaml$")).key_groups[].age[1] alias = "{{HOST}}"' {{SOPS_FILE}}; \
    fi

# Automatically add the host and user keys to the shared.yaml creation rule
add-to-shared USER HOST:
    if [[ -n "$(yq '.creation_rules[] | select(.path_regex == "shared\\.yaml$")' {{SOPS_FILE}})" ]]; then \
        if [[ -z "$(yq '.creation_rules[] | select(.path_regex == "shared\\.yaml$").key_groups[].age[] | select(alias == "{{HOST}}")' {{SOPS_FILE}})" ]]; then \
            echo "Adding {{USER}}_{{HOST}} and {{HOST}} to shared.yaml rule" && \
            yq -i '(.creation_rules[] | select(.path_regex == "shared\\.yaml$")).key_groups[].age += ["{{USER}}_{{HOST}}", "{{HOST}}"]' {{SOPS_FILE}} && \
            yq -i '(.creation_rules[] | select(.path_regex == "shared\\.yaml$")).key_groups[].age[-2] alias = "{{USER}}_{{HOST}}"' {{SOPS_FILE}} && \
            yq -i '(.creation_rules[] | select(.path_regex == "shared\\.yaml$")).key_groups[].age[-1] alias = "{{HOST}}"' {{SOPS_FILE}}; \
        else \
            echo "Keys already exist in shared.yaml rule"; \
        fi; \
    else \
        echo "shared.yaml rule not found"; \
    fi

# Automatically add the host and user keys to creation rules for shared.yaml and <host>.yaml
add-creation-rules USER HOST:
    just add-host-sops-file {{USER}} {{HOST}} && \
    just add-to-shared {{USER}} {{HOST}}
