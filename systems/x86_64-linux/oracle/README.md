# Oracle VPS NixOS Configuration

NixOS configuration for Oracle Cloud VPS running Coolify with Tailscale VPN.

## Features

- **Coolify**: Self-hosted PaaS platform for deploying applications
- **Tailscale**: Secure VPN for remote access (no public web interface exposure)
- **Docker**: Container runtime for Coolify
- **Impermanence**: Root filesystem using btrfs with preservation
- **SOPS**: Encrypted secrets management
- **OpenSSH**: Secure remote access

## Architecture

- **OS**: NixOS 24.11
- **Disk Layout**: Btrfs with subvolumes (no LUKS for nixos-anywhere compatibility)
  - 512MB EFI boot partition
  - 4GB encrypted swap
  - Btrfs root with subvolumes: /, /home, /nix, /persist, /var/lib/coolify, /var/lib/docker
- **Networking**: Tailscale VPN, SSH on port 22
- **Services**: Coolify (port 8000), accessible via Tailscale only

## Prerequisites

1. **Oracle Cloud VPS** with SSH access
2. **Tailscale account** and auth key
3. **SSH key** for deployment
4. **Age key** for host (generate after deployment or provide beforehand)
5. **SOPS-encrypted secrets** in your nix-secrets repository

## Deployment Steps

### 1. Prepare Secrets

Before deployment, you need to set up the required secrets in your `nix-secrets` repository:

```bash
# Navigate to your nix-secrets repository
cd /path/to/nix-secrets

# Create secrets for the oracle host
# Required secrets:
# - ssh-keys/dtgagnon-key.pub (your SSH public key)
# - tailscale-authKey (Tailscale authentication key)

# Generate a Tailscale auth key from: https://login.tailscale.com/admin/settings/keys
# Make it reusable and set an appropriate expiration

# Add the secrets using sops (example)
sops secrets/oracle/secrets.yaml
```

Example `secrets.yaml` structure:
```yaml
ssh-keys:
    dtgagnon-key.pub: ssh-ed25519 AAAAC3Nza... user@host
tailscale-authKey: tskey-auth-...
```

### 2. Generate Host Age Key (Optional)

If you want to pre-configure the age key for encryption:

```bash
# Generate an age key for the oracle host
# You can do this after deployment via SSH, or generate it beforehand

# After deployment, SSH into the host and run:
ssh root@<oracle-ip>
ssh-keyscan localhost | ssh-to-age
# Add this key to your nix-secrets .sops.yaml
```

### 3. Deploy with nixos-anywhere

From your nix-config directory:

```bash
# Ensure you have nixos-anywhere installed
nix shell nixpkgs#nixos-anywhere

# Deploy to Oracle VPS
# Replace <oracle-ip> with your VPS IP address
nixos-anywhere --flake .#oracle root@<oracle-ip>
```

**Note**: nixos-anywhere will:
- Partition and format the disk according to `disk-config.nix`
- Install NixOS with your configuration
- Reboot the system

### 4. Verify Disk Device

If your Oracle VPS uses a different disk device (not `/dev/sda`), you need to update `disk-config.nix` before deployment:

```bash
# SSH into the Oracle VPS first to check the disk device
ssh root@<oracle-ip>
lsblk  # Check which device is your main disk (might be /dev/nvme0n1 or /dev/vda)

# Update disk-config.nix line 8 if needed:
device = "/dev/sda";  # Change to /dev/nvme0n1 or /dev/vda if necessary
```

### 5. Post-Deployment Configuration

After successful deployment:

#### a. Connect to Tailscale

The system should automatically connect to Tailscale using the auth key from secrets. Verify:

```bash
# SSH into the VPS via its public IP (initially)
ssh root@<oracle-ip>

# Check Tailscale status
tailscale status

# Note the Tailscale IP (usually 100.x.x.x)
```

From now on, you can SSH via Tailscale instead of the public IP.

#### b. Access Coolify

Coolify will be running on port 8000 and is only accessible via Tailscale:

```bash
# From your local machine (connected to Tailscale)
# Get the oracle host's Tailscale IP
tailscale status | grep oracle

# Access Coolify web interface
# http://<tailscale-ip>:8000
# or if you've configured SSH access:
# http://oracle:8000
```

#### c. Complete Coolify Setup

1. Open `http://<tailscale-ip>:8000` in your browser
2. Follow the Coolify first-time setup wizard
3. Create your admin account
4. Configure your deployment settings

#### d. Generate and Store Host Age Key

```bash
# On the oracle host
ssh-keyscan localhost | ssh-to-age

# Copy the generated age key
# Example output: age1qyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqszqgpqyqs...

# Add this to your nix-secrets/.sops.yaml under the oracle host entry
# Then re-encrypt secrets:
cd /path/to/nix-secrets
sops updatekeys secrets/oracle/secrets.yaml

# Back in nix-config, update the flake.lock for nix-secrets
just update-nix-secrets  # Or: nix flake lock --update-input nix-secrets

# Rebuild the system to use the encrypted secrets
ssh root@oracle  # via Tailscale
nixos-rebuild switch --flake github:yourusername/nix-config#oracle
```

## Maintenance

### Updating the System

```bash
# SSH into the oracle host via Tailscale
ssh root@oracle

# Update and rebuild
nix flake update
nixos-rebuild switch --flake .#oracle
```

### Checking Coolify Status

```bash
# Check Docker containers
docker ps

# Check Coolify container logs
docker logs coolify

# Restart Coolify if needed
systemctl restart docker-coolify.service
```

### Managing Secrets

```bash
# In your nix-secrets repository
cd /path/to/nix-secrets

# Edit secrets
sops secrets/oracle/secrets.yaml

# After editing, commit and push changes
# Then update nix-config's flake lock
cd /path/to/nix-config
just update-nix-secrets
```

### Accessing Docker Volumes

Coolify data is stored in `/var/lib/coolify` (on its own btrfs subvolume):

```bash
ls -la /var/lib/coolify/
# - source/        - Application source code
# - ssh/           - SSH keys for deployment
# - applications/  - Application data
# - databases/     - Database data
# - backups/       - Backup data
# - services/      - Service configurations
# - proxy/         - Reverse proxy configurations
```

## Firewall Configuration

- **Port 22**: SSH (open to public for initial setup, then can use Tailscale)
- **Port 8000**: Coolify web interface (only accessible via Tailscale)
- **Tailscale**: Trusted interface, all traffic allowed

To expose Coolify publicly (not recommended):

```nix
# In default.nix, change:
spirenix.services.coolify.openFirewall = true;
```

## Troubleshooting

### Coolify Won't Start

```bash
# Check Docker status
systemctl status docker

# Check Coolify service
systemctl status docker-coolify.service

# Check secrets file
cat /var/lib/coolify/.secrets

# Restart services
systemctl restart docker
systemctl restart docker-coolify.service
```

### Tailscale Not Connecting

```bash
# Check Tailscale status
systemctl status tailscaled
tailscale status

# Re-authenticate if needed (requires new auth key in secrets)
tailscale up

# Check firewall
iptables -L -n | grep tailscale
```

### Disk Space Issues

```bash
# Check disk usage
df -h
btrfs filesystem usage /

# Clean up Docker
docker system prune -a

# Check btrfs subvolumes
btrfs subvolume list /
```

### SSH Access Issues

```bash
# Via Oracle Cloud Console (if SSH fails):
# 1. Login to Oracle Cloud Console
# 2. Navigate to your instance
# 3. Click "Console Connection" to access serial console
# 4. Login as root and check sshd status:
systemctl status sshd
journalctl -u sshd -n 50
```

## Architecture Notes

### Why No LUKS Encryption?

The root filesystem is not encrypted with LUKS to allow **nixos-anywhere** to perform unattended remote deployments. This is acceptable for a VPS where:
- Physical access is controlled by Oracle
- Sensitive data should be in application-level encryption
- Swap is still encrypted (random encryption on each boot)
- SOPS encrypts secrets at rest

If you need full disk encryption, you'll need to:
1. Deploy manually with LUKS
2. Provide the LUKS password during deployment
3. Configure remote unlock (e.g., via Tang/Clevis or SSH in initrd)

### Btrfs Subvolumes

Separate subvolumes for Docker and Coolify allow:
- Independent snapshots
- Easy backup/restore
- Separate compression settings if needed
- Performance isolation

## Resources

- [Coolify Documentation](https://coolify.io/docs)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
- [Disko](https://github.com/nix-community/disko)
