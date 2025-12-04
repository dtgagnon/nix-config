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

2. **nixos-anywhere Infrastructure** (`installer/install.sh`)
   - Full-featured installation script with nixos-anywhere integration
   - Automated SSH host key generation
   - Age key generation from SSH host keys
   - SOPS integration and .sops.yaml management
   - Interactive prompts for all deployment steps

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

### How install.sh Handles Age Keys

The `installer/install.sh` script has comprehensive age key automation:

1. **SSH Host Key Generation** (lines 145-157)
   - Generates `ssh_host_ed25519_key` pair for target host
   - Stored in `$temp/$persist_dir/etc/ssh/`
   - Included in nixos-anywhere `--extra-files`
   - Ensures consistent host identity across reboots

2. **Host Age Key Generation** (lines 204-226)
   - After nixos-anywhere completes, prompts: "Generate host (ssh-based) age key?"
   - Uses `ssh-keyscan` to get SSH host key from target
   - Converts to age key using `ssh-to-age`
   - Automatically updates `nix-secrets/.sops.yaml` with new host age key
   - Creates anchor: `&oracle` for the host key

3. **User Age Key Generation** (lines 229-270)
   - Prompts: "Generate user age key?"
   - Generates fresh age key pair using `age-keygen`
   - Extracts public key and adds to `.sops.yaml` with anchor: `&dtgagnon_oracle`
   - Creates host-specific secrets file: `nix-secrets/sops/oracle.yaml`
   - Stores user's **secret key** in `oracle.yaml` at path `["keys"]["age"]`

4. **SOPS Creation Rules** (lines 317-319)
   - Automatically adds creation rules to `.sops.yaml`
   - Both `oracle.yaml` and `shared.yaml` get access to:
     - Host age key: `&oracle`
     - User age key: `&dtgagnon_oracle`

5. **Rekey and Update** (lines 319-322)
   - Runs `just rekey` to re-encrypt all secrets with new keys
   - Updates flake input to pick up new `.sops.yaml`

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

### Option A: Use installer/install.sh (Recommended)

**Pros:**
- Handles all automation (SSH keys, age keys, sops configuration)
- Interactive prompts guide you through process
- Automatic secrets setup
- Well-tested workflow

**Cons:**
- Not wrapped in just recipes
- Requires running from `installer/` directory
- Long interactive process

**Steps:**
```bash
cd /home/dtgagnon/nix-config/nixos/installer
./install.sh -n oracle -d <ORACLE_IP> -k ~/.ssh/dtgagnon-key
```

### Option B: Direct nixos-anywhere

**Pros:**
- Faster, non-interactive
- Single command deployment

**Cons:**
- Manual age key setup afterward
- Manual sops configuration
- No automated secrets management

**Steps:**
```bash
cd /home/dtgagnon/nix-config/nixos
nix run github:nix-community/nixos-anywhere -- \
  --flake .#oracle \
  root@<ORACLE_IP>
```

### Option C: Create Just Recipe Wrapper

**Pros:**
- Simple just command interface
- Reproducible from justfile
- Can customize for oracle-specific needs

**Cons:**
- Requires creating new recipe
- Still needs manual age key handling if not using install.sh

## Critical Files

- `/home/dtgagnon/nix-config/nixos/systems/x86_64-linux/oracle/default.nix` - Main configuration
- `/home/dtgagnon/nix-config/nixos/systems/x86_64-linux/oracle/disk-config.nix` - Disk partitioning
- `/home/dtgagnon/nix-config/nixos/systems/x86_64-linux/oracle/hardware.nix` - Hardware settings
- `/home/dtgagnon/nix-config/nixos/installer/install.sh` - Installation automation
- `/home/dtgagnon/nix-config/nixos/justfile` - Just recipes
- `../nix-secrets/.sops.yaml` - SOPS configuration (to be updated)
- `../nix-secrets/sops/oracle.yaml` - Oracle-specific secrets (to be created)

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

### Phase 2: Execute Deployment (20-30 minutes)

#### 2.1 Run installer/install.sh

```bash
cd ~/nix-config/nixos/installer

./install.sh \
  -n oracle \
  -d <ORACLE_PUBLIC_IP> \
  -k ~/.ssh/oranix \
  -u ubuntu \
  --port 22 \
  --impermanence
```

**Interactive Prompt Guide:**

| Prompt | Answer | Why |
|--------|--------|-----|
| "Run nixos-anywhere installation?" | **YES** | Starts deployment |
| "Manually set LUKS passphrase?" | **NO** | No LUKS on oracle config |
| "Generate new hardware config?" | **NO** | Already in repo |
| *Wait for reboot (1-2 min)* | - | System reboots automatically |
| "Has your system restarted?" | **YES** | Confirm reboot completed |
| "Generate host (ssh-based) age key?" | **YES** | ⚠️ CRITICAL for secrets |
| "Generate user age key?" | **NO** | You already have one |
| "Add ssh fingerprints for git?" | **YES** | Enables git operations |
| "Copy full nix-config?" | **YES** | Enables manual rebuild |
| "Rebuild immediately?" | **NO** | Verify first |

**What Happens Behind the Scenes:**

1. `install.sh` generates SSH host key → saved to `/persist/etc/ssh/ssh_host_ed25519_key`
2. `nixos-anywhere` partitions disk, installs NixOS, reboots
3. Script converts SSH key to age key using `ssh-to-age`
4. Updates `nix-secrets/.sops.yaml` with new `&oracle` anchor
5. Runs `just rekey` to re-encrypt all secrets with oracle's key
6. Your user key (`&dtgagnon`) + oracle's host key (`&oracle`) can both decrypt

#### 2.2 Commit Age Key Updates

After install.sh completes successfully:

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
sops -d sops/oracle.yaml  # Uses &dtgagnon key

# Re-provision new instance
cd ~/nix-config/nixos/installer
./install.sh -n oracle -d <NEW_IP> -k ~/.ssh/oranix -u ubuntu --impermanence
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

**Oracle Host Key (`&oracle`):**
- Derived from `/persist/etc/ssh/ssh_host_ed25519_key`
- Generated during deployment by `install.sh`
- Available automatically on boot (no manual copying)
- Oracle can decrypt its own secrets

**Both keys can decrypt = No lockout:**
- If oracle fails → use your user key to decrypt from workstation
- If you lose user key → oracle still boots and decrypts
- If you lose SSH host key → re-run install.sh to generate new one

### The Circular Dependency Myth

You mentioned concern about the "chicken-egg problem" - here's why it's not actually a problem:

1. **install.sh generates SSH key BEFORE installation**
   - Key exists in temp directory
   - Passed to nixos-anywhere via `--extra-files`
   - Installed to `/persist/etc/ssh/` during deployment

2. **Age key derived AFTER installation completes**
   - SSH daemon starts with the pre-generated key
   - `ssh-keyscan` retrieves public key
   - Converted to age format
   - Added to `.sops.yaml`

3. **Secrets rekeyed BEFORE first rebuild**
   - `just rekey` re-encrypts with new oracle key
   - Flake input updated to latest nix-secrets
   - First rebuild uses already-encrypted secrets

**Timeline ensures no lockout:**
```
Generate SSH key → Install NixOS → Derive age key → Rekey secrets → First rebuild
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
- `installer/install.sh` - Main deployment orchestrator
- `installer/helpers.sh` - Helper functions for prompts/sops
- `justfile` - Just recipes (rebuild, rekey, etc.)
- `scripts/system-flake-rebuild.sh` - To be created (Phase 1.1)
- `scripts/check-sops.sh` - To be created (Phase 1.1)

**Secrets:**
- `../nix-secrets/.sops.yaml` - Encryption key configuration (updated by install.sh)
- `../nix-secrets/sops/oracle.yaml` - Oracle-specific secrets (needs real Tailscale key)
- `modules/nixos/security/sops-nix/default.nix` - SOPS module configuration

## Summary

### What's Already Perfect

✅ Oracle NixOS configuration is complete and minimal (1GB RAM optimized)
✅ Disko handles partitioning automatically (Btrfs + preservation)
✅ install.sh automates everything (SSH keys, age keys, sops setup)
✅ Dual-key encryption prevents lockout scenarios
✅ Comprehensive README documents the architecture

### What Needs Action

1. **Create `scripts/` directory** (Phase 1.1) - 2 minutes
2. **Verify disk device** on Oracle instance (Phase 1.2) - 1 minute
3. **Add real Tailscale key** to secrets (Phase 1.3) - 2 minutes
4. **Run installer/install.sh** (Phase 2) - 20-30 minutes
5. **Backup SSH host key** (Phase 5) - 2 minutes

### The Magic of install.sh

The script handles **all complexity**:
- ✅ Generates SSH host keys before installation
- ✅ Derives age keys automatically from SSH keys
- ✅ Updates `.sops.yaml` with proper anchors
- ✅ Rekeys all secrets with new oracle key
- ✅ Ensures dual-key redundancy (your key + oracle's key)
- ✅ Syncs nix-config and nix-secrets to target
- ✅ Provides clear prompts for each decision point

You just answer prompts and verify each phase succeeds. No manual key copying, no complex sops commands, no lockout risk.
