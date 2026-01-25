# Oracle Cloud nixos-anywhere Deployment Plan

## Goal
Ensure everything is in place to run nixos-anywhere and install minimal NixOS onto an Oracle Cloud VM.Standard.E2.1.Micro instance.

## Current State Analysis

### ✅ What's Already in Place

1. **Oracle Host Configuration** (`systems/x86_64-linux/oracle/`)
   - Complete NixOS configuration for Oracle Cloud
   - Disko disk partitioning setup (no LUKS for unattended deployment)
   - Btrfs with preservation framework
   - Services: Coolify, Tailscale, OpenSSH
   - Comprehensive README with deployment instructions

2. **nixos-anywhere Infrastructure** (`justfile` recipes)
   - Single-command deployment via `just deploy-vps`
   - Automated SSH host key generation
   - Age key derivation from SSH host keys
   - Automatic .sops.yaml updates and rekeying
   - No interactive prompts - fully automated

3. **Secrets** (nix-secrets)
   - ✅ Tailscale auth key configured
   - ✅ SSH public key (dtgagnon-key.pub) configured
   - ⚠️ Oracle host age key not yet configured (will be generated during deployment)

### ⚠️ Identified Gaps

1. **Missing Scripts Directory**
   - `justfile` references `scripts/system-flake-rebuild.sh` (line 25, 29)
   - `justfile` references `scripts/system-flake-rebuild-trace.sh` (line 33)
   - `justfile` references `scripts/check-sops.sh` (line 47)
   - The `scripts/` directory doesn't exist
   - Impact: `just rebuild` and related commands will fail

2. **No Oracle-Specific Just Recipe**
   - Current recipes are generic or reference missing scripts
   - No dedicated recipe for Oracle Cloud deployment workflow

3. **Disk Device Verification Needed**
   - `disk-config.nix` assumes `/dev/sda` (line 8)
   - Oracle Cloud instances may use `/dev/sda`, `/dev/vda`, or `/dev/nvme0n1`
   - Need to verify actual device name before deployment

## Oracle Cloud VM.Standard.E2.1.Micro Specs

**Resources:**
- **vCPUs**: 1 (AMD EPYC or Intel Xeon)
- **RAM**: 1GB
- **Bandwidth**: 0.48 Gbps
- **Storage**: Block storage (boot volume size configurable, typically 50-200GB)
- **Architecture**: x86_64

**Important Notes:**
- ARM-based (Ampere) shapes are different (VM.Standard.A1.Flex)
- E2.1.Micro is x86_64 and uses KVM virtualization
- Extremely limited resources - minimal configuration required

## Age Key and Secrets Workflow

### How the Deploy Recipes Handle Age Keys

The `justfile` deploy recipes handle age key automation automatically:

1. **SSH Host Key Generation**
   - Generates `ssh_host_ed25519_key` pair for target host
   - Stored in `$temp/$persist_dir/etc/ssh/`
   - Included in nixos-anywhere `--extra-files`
   - Ensures consistent host identity across reboots

2. **Host Age Key Derivation**
   - Derives age key from SSH public key using `ssh-to-age`
   - Done **before** deployment (not after)
   - Automatically updates `nix-secrets/.sops.yaml` with new host age key
   - Creates anchor: `&oranix` for the host key

3. **SOPS Creation Rules**
   - Calls `just add-creation-rules` to update `.sops.yaml`
   - Both `oranix.yaml` and `shared.yaml` get access to the host age key

4. **Rekey and Update**
   - Runs `just rekey` to re-encrypt all secrets with new keys
   - Updates flake input via `nix flake update nix-secrets`
   - Secrets are ready to decrypt on first boot

### Secrets Architecture

**Two-Key System:**
- **Host Age Key** (derived from SSH host key)
  - ✅ Survives reinstalls (if you keep the SSH host key)
  - ✅ No manual copying needed
  - ✅ Automatically available on boot
  - ⚠️ Lost if SSH host key is regenerated

- **User Age Key** (randomly generated)
  - ✅ Can be stored elsewhere for recovery
  - ✅ Allows manual decryption from workstation
  - ⚠️ Stored in encrypted secrets file (chicken-egg problem)
  - ⚠️ Lost if you can't decrypt the secrets file

**Lockout Prevention:**
- Both keys can decrypt secrets (redundancy)
- User key stored in `oracle.yaml` encrypted with... both keys (circular dependency!)
- **Recommendation**: Extract and backup user secret key after generation

## Deployment Workflow Options

### Option A: Use justfile recipes (Recommended)

**Pros:**
- Single-command deployment (no interactive prompts)
- Automatic SSH key generation and age key derivation
- Automatic .sops.yaml updates and rekeying
- Secrets decrypt on first boot
- Well-integrated with existing sops recipes

**Steps:**
```bash
cd /home/dtgagnon/nix-config/nixos

# For VPS/cloud with impermanence (oranix/oracle)
just deploy-vps oranix <ORACLE_IP> ubuntu

# Or for generic deployment without impermanence
just deploy oranix <ORACLE_IP> ubuntu
```

**What it does automatically:**
1. Generates SSH host key (pre-deployment)
2. Derives age key from SSH public key
3. Updates `.sops.yaml` with host age key anchor
4. Adds creation rules for host + shared secrets
5. Rekeys all secrets with the new host key
6. Updates nix-secrets flake input
7. Deploys with nixos-anywhere `--extra-files`

### Option B: Register existing host (Two-phase deploy)

Use this if the host already has an SSH key you want to keep:

```bash
cd /home/dtgagnon/nix-config/nixos

# First deploy without sops secrets working
nix run github:nix-community/nixos-anywhere -- \
  --flake .#oranix \
  ubuntu@<ORACLE_IP>

# After boot, register the generated SSH key with sops
just register-host-key oranix <ORACLE_IP>

# Then rebuild on the target to apply secrets
ssh root@<ORACLE_IP> "cd /etc/nixos && nixos-rebuild switch --flake .#oranix"
```

## Critical Files

- `/home/dtgagnon/nix-config/nixos/systems/x86_64-linux/oracle/default.nix` - Main configuration
- `/home/dtgagnon/nix-config/nixos/systems/x86_64-linux/oracle/disk-config.nix` - Disk partitioning
- `/home/dtgagnon/nix-config/nixos/systems/x86_64-linux/oracle/hardware.nix` - Hardware settings
- `/home/dtgagnon/nix-config/nixos/justfile` - Deployment recipes
- `../nix-secrets/.sops.yaml` - SOPS configuration
- `../nix-secrets/sops/oranix.yaml` - Oranix-specific secrets

## Implementation Plan

### Phase 1: Pre-Deployment Setup (10 minutes)

#### 1.1 Create Missing Scripts Directory

The justfile currently references scripts that don't exist. Create them:

**Files to create:**
- `scripts/system-flake-rebuild.sh` - Wrapper for nixos-rebuild switch
- `scripts/check-sops.sh` - Validates SOPS configuration

**Implementation:**
```bash
# Create scripts directory
mkdir -p scripts

# Create system-flake-rebuild.sh
cat > scripts/system-flake-rebuild.sh << 'EOF'
#!/usr/bin/env bash
set -e
sudo nixos-rebuild switch --impure --flake .# "$@"
EOF

# Create check-sops.sh
cat > scripts/check-sops.sh << 'EOF'
#!/usr/bin/env bash
set -e
echo "Checking SOPS configuration..."
[[ -f ../nix-secrets/.sops.yaml ]] || { echo "❌ .sops.yaml not found"; exit 1; }
echo "✅ SOPS configuration looks good"
ls -lh ../nix-secrets/sops/*.yaml 2>/dev/null || true
EOF

chmod +x scripts/*.sh
```

#### 1.2 Verify Disk Device on Oracle Instance

**CRITICAL:** Must verify before deployment to avoid disk detection failures.

```bash
# SSH to Oracle instance (still running Ubuntu/OEL)
ssh -i ~/.ssh/oranix ubuntu@<ORACLE_PUBLIC_IP>

# Check disk layout
lsblk
# Look for: /dev/sda, /dev/vda, or /dev/nvme0n1

# If NOT /dev/sda, update:
# systems/x86_64-linux/oracle/disk-config.nix line 8
```

#### 1.3 Configure Real Tailscale Auth Key

Update secrets with actual Tailscale authentication key:

```bash
cd ~/nix-config/nix-secrets

# Edit oracle secrets
sops sops/oracle.yaml

# Ensure it contains:
# tailscale-authKey: tskey-auth-XXXXX-YYYYYY
# (Generate from: https://login.tailscale.com/admin/settings/keys)
```

#### 1.4 Validate Configuration Builds

```bash
cd ~/nix-config/nixos

# Verify oracle configuration exists
nix flake show --impure 2>&1 | grep oracle

# Test build (dry-run)
nix build --dry-run .#nixosConfigurations.oracle.config.system.build.toplevel
```

### Phase 2: Execute Deployment

#### 2.1 Run deployment via justfile

```bash
cd ~/nix-config/nixos

# Single command - fully automated
just deploy-vps oranix <ORACLE_PUBLIC_IP> ubuntu
```

**What Happens Automatically:**

1. Generates SSH host key in temp directory
2. Derives age key from SSH public key using `ssh-to-age`
3. Updates `nix-secrets/.sops.yaml` with new `&oranix` anchor
4. Adds creation rules for `oranix.yaml` and `shared.yaml`
5. Runs `just rekey` to re-encrypt all secrets with oranix's key
6. Updates `nix-secrets` flake input
7. Clears known_hosts entries for target
8. Runs `nixos-anywhere` with `--extra-files` containing SSH key
9. SSH key saved to `/persist/etc/ssh/ssh_host_ed25519_key`
10. System reboots with secrets decrypting on first boot

**No interactive prompts!** The entire process is automated.

#### 2.2 Commit Age Key Updates

After deployment completes successfully:

```bash
cd ~/nix-config/nix-secrets

# Review changes (should show &oracle age key added)
git diff .sops.yaml

# Commit
git add .sops.yaml sops/oracle.yaml
git commit -m "feat: add oracle host age key and configure secrets"
git push

cd ~/nix-config/nixos

# Update flake to pick up new nix-secrets
nix flake update nix-secrets

# Commit flake.lock
git add flake.lock
git commit -m "chore: update nix-secrets for oracle deployment"
git push
```

### Phase 3: First System Rebuild (10 minutes)

#### 3.1 SSH to Oracle and Rebuild

```bash
# SSH to oracle (now running NixOS)
ssh -i ~/.ssh/oranix root@<ORACLE_PUBLIC_IP>

# Navigate to synced config
cd /root/nixos  # or /home/ubuntu/nixos if target_user was ubuntu

# Pull latest nix-secrets with oracle's age key
nix flake update nix-secrets

# First rebuild with secrets
sudo nixos-rebuild switch --impure --flake .#oracle --show-trace
```

**Success Indicators:**
- ✅ Secrets decrypted: `ls -la /run/secrets/` shows `tailscale-authKey`
- ✅ Tailscale running: `systemctl status tailscale`
- ✅ Coolify container: `docker ps | grep coolify`

### Phase 4: Verify Services (10 minutes)

#### 4.1 Confirm Tailscale Connection

```bash
# On oracle
sudo tailscale status
# Should show online with your tailnet

# From workstation
tailscale status | grep oracle
ping oracle  # MagicDNS should work
ssh root@oracle  # Via Tailscale (use this going forward)
```

#### 4.2 Access Coolify Web Interface

From your workstation browser:
- Navigate to: `http://oracle:8000` (via Tailscale MagicDNS)
- Or: `http://100.x.x.x:8000` (Tailscale IP)
- Complete Coolify first-time setup wizard
- Create admin account

### Phase 5: Critical Backups (5 minutes)

#### 5.1 Backup SSH Host Key

**⚠️ DO THIS IMMEDIATELY - this key can decrypt all oracle secrets:**

```bash
# On oracle
sudo cat /persist/etc/ssh/ssh_host_ed25519_key > ~/oracle-ssh-host-key.backup

# Copy to workstation
scp root@oracle:~/oracle-ssh-host-key.backup ~/.ssh/oracle-host-key.backup

# Secure it
chmod 600 ~/.ssh/oracle-host-key.backup

# ALSO store in password manager or encrypted backup
```

#### 5.2 Verify Age Key Derivation

```bash
# On oracle - derive age key manually to verify
nix shell nixpkgs#ssh-to-age.out -c sh -c \
  "ssh-keygen -y -f /persist/etc/ssh/ssh_host_ed25519_key | ssh-to-age"

# Should match the key in nix-secrets/.sops.yaml under &oracle anchor
```

### Phase 6: Optional Hardening (After Verification)

#### 6.1 Restrict SSH to Tailscale Only

**⚠️ Only after confirming Tailscale SSH works!**

Edit `systems/x86_64-linux/oracle/default.nix`:

```nix
# Remove 22 from allowedTCPPorts
networking.firewall.allowedTCPPorts = [ ];  # Was: [ 22 ]

# SSH only via Tailscale
networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
```

Rebuild to apply:
```bash
sudo nixos-rebuild switch --impure --flake .#oracle
```

## Recovery Procedures

### Scenario 1: SOPS Decryption Fails

**Symptom:** Secrets not appearing in `/run/secrets/`

**Fix:**
```bash
# On oracle - verify SSH host key exists
sudo ls -la /persist/etc/ssh/ssh_host_ed25519_key

# Manually derive age key
nix shell nixpkgs#ssh-to-age.out -c sh -c \
  "ssh-keygen -y -f /persist/etc/ssh/ssh_host_ed25519_key | ssh-to-age"

# On workstation - re-add to .sops.yaml if needed
cd ~/nix-config/nix-secrets
ORACLE_AGE_KEY="age1XXXXX..."  # From above command
just update-host-age-key oracle "$ORACLE_AGE_KEY"
just rekey
git add -A && git commit -m "fix: update oracle age key" && git push

# On oracle - rebuild
cd /root/nixos
nix flake update nix-secrets
sudo nixos-rebuild switch --impure --flake .#oracle
```

### Scenario 2: Complete Host Loss

**You can still decrypt secrets with your user key:**

```bash
# On workstation
cd ~/nix-config/nix-secrets
sops -d sops/oranix.yaml  # Uses &dtgagnon key

# Re-provision new instance
cd ~/nix-config/nixos
just deploy-vps oranix <NEW_IP> ubuntu
# Generates new host key, updates .sops.yaml, rekeys automatically
```

### Scenario 3: Locked Out of Tailscale

**Use Oracle Cloud Console serial console:**

1. Login to Oracle Cloud Console
2. Navigate to instance → Console Connection
3. Login as root
4. Check Tailscale: `journalctl -u tailscale -n 50`
5. Manual auth: `tailscale up --ssh --authkey "$(cat /run/secrets/tailscale-authKey)"`

## Age Key Architecture Explained

### Why Two Keys Are Better Than One

**Your User Key (`&dtgagnon`):**
- Already exists in `~/.config/sops/age/keys.txt`
- Public: `age1ztct0zpqy8lj2954ghrae9tw6r4wmdw7qfv3sqp03367x2d7macqn6fwgc`
- Can decrypt oracle secrets from your workstation
- Survives host reinstalls/failures

**Oranix Host Key (`&oranix`):**
- Derived from `/persist/etc/ssh/ssh_host_ed25519_key`
- Generated during deployment by `just deploy-vps`
- Available automatically on boot (no manual copying)
- Oranix can decrypt its own secrets

**Both keys can decrypt = No lockout:**
- If oranix fails → use your user key to decrypt from workstation
- If you lose user key → oranix still boots and decrypts
- If you lose SSH host key → re-run `just deploy-vps` to generate new one

### The Circular Dependency Myth

You mentioned concern about the "chicken-egg problem" - here's why it's not actually a problem:

1. **Deploy recipe generates SSH key BEFORE installation**
   - Key exists in temp directory
   - Age key derived immediately from the public key
   - Key passed to nixos-anywhere via `--extra-files`
   - Installed to `/persist/etc/ssh/` during deployment

2. **Age key added to .sops.yaml BEFORE deployment**
   - `just update-host-age-key` adds the anchor
   - `just add-creation-rules` updates creation rules
   - `just rekey` re-encrypts all secrets
   - `nix flake update nix-secrets` updates the lock

3. **Secrets ready on first boot**
   - SSH key is already in place
   - sops-nix derives age key from SSH key
   - Secrets decrypt immediately

**Timeline ensures no lockout:**
```
Generate SSH key → Derive age key → Update .sops.yaml → Rekey → Deploy → First boot with secrets
```

## Maintenance Guide

### Weekly Updates

```bash
ssh root@oracle
cd /root/nixos
nix flake update
sudo nixos-rebuild switch --impure --flake .#oracle
sudo nix-collect-garbage --delete-older-than 30d
```

### Update Secrets

```bash
# On workstation
cd ~/nix-config/nix-secrets
sops sops/oracle.yaml  # Edit secrets
git commit -am "chore: update oracle secrets" && git push

# On oracle
cd /root/nixos
nix flake update nix-secrets
sudo nixos-rebuild switch --impure --flake .#oracle
```

### Monitor Resource Usage (1GB RAM!)

```bash
# On oracle
free -h
docker stats
df -h /var/lib/coolify
```

## Critical Files Reference

**Configuration:**
- `systems/x86_64-linux/oracle/default.nix` - Main NixOS config
- `systems/x86_64-linux/oracle/disk-config.nix` - Disko partitioning (verify `/dev/sda`)
- `systems/x86_64-linux/oracle/hardware.nix` - QEMU guest settings
- `systems/x86_64-linux/oracle/README.md` - Comprehensive documentation

**Deployment:**
- `justfile` - Main deployment recipes (deploy, deploy-vps, deploy-luks, etc.)

**Secrets:**
- `../nix-secrets/.sops.yaml` - Encryption key configuration (updated by deploy recipes)
- `../nix-secrets/sops/oranix.yaml` - Oranix-specific secrets
- `modules/nixos/security/sops-nix/default.nix` - SOPS module configuration

## Summary

### What's Already Perfect

- Oracle/Oranix NixOS configuration is complete and minimal (1GB RAM optimized)
- Disko handles partitioning automatically (Btrfs + preservation)
- Justfile recipes automate everything (SSH keys, age keys, sops setup)
- Dual-key encryption prevents lockout scenarios
- Comprehensive README documents the architecture

### What Needs Action

1. **Verify disk device** on Oracle instance (Phase 1.2)
2. **Add real Tailscale key** to secrets (Phase 1.3)
3. **Run `just deploy-vps`** (Phase 2) - single command
4. **Backup SSH host key** (Phase 5)

### The Magic of Justfile Recipes

The `deploy-vps` recipe handles **all complexity** in a single command:
- Generates SSH host keys before installation
- Derives age keys automatically from SSH keys
- Updates `.sops.yaml` with proper anchors
- Adds creation rules for host-specific and shared secrets
- Rekeys all secrets with new host key
- Updates nix-secrets flake input
- Deploys with nixos-anywhere
- Secrets decrypt on first boot

No interactive prompts, no manual key copying, no complex sops commands, no lockout risk.

```bash
# Single command deployment
just deploy-vps oranix <IP> ubuntu
```
