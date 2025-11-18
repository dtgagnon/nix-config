# DTG Engineering VPS - Digital Ocean NixOS Deployment

This configuration deploys a NixOS-based reverse proxy on Digital Ocean to connect the publicly accessible `dtgengineering.com` website to your locally-hosted Odoo ERP/CRM system via Tailscale.

## Architecture

```
Internet → Digital Ocean VPS (Nginx) → Tailscale VPN → Local Odoo (port 8069)
           [dtgengineering.com]          [encrypted]     [100.x.x.x:8069]
```

## Features

- **Nginx Reverse Proxy**: Routes HTTPS traffic to Odoo backend
- **Automatic SSL**: Let's Encrypt certificates managed by ACME
- **Tailscale VPN**: Secure encrypted connection to local network
- **WebSocket Support**: Required for Odoo real-time features
- **Security Headers**: XSS protection, frame options, content type sniffing prevention

## Prerequisites

### 1. SSH Key Setup (Security Best Practice)

This configuration uses a **VPS-specific SSH key** for enhanced security. This means:
- Your personal SSH key stays on your local machines only
- If the VPS key is compromised, only the VPS is affected
- You can revoke VPS access without affecting other systems
- Easier to audit and rotate keys

**The VPS SSH key has already been generated at**: `~/.ssh/dtg-vps`

#### Add to Your SSH Config (Optional but Recommended)

Add this to your `~/.ssh/config` file for easy access:

```ssh-config
Host dtg-vps
    HostName YOUR_DROPLET_IP  # Replace after creating droplet
    User root
    IdentityFile ~/.ssh/dtg-vps
    IdentitiesOnly yes
```

Then you can simply connect with: `ssh dtg-vps`

#### Upload Public Key to Digital Ocean

When creating your droplet, you'll need to add the **public key**:

```bash
# Display your VPS public key
cat ~/.ssh/dtg-vps.pub
```

Copy this key and add it to Digital Ocean during droplet creation (see next step).

### 2. Digital Ocean Account Setup

1. Create a Digital Ocean account at https://www.digitalocean.com
2. Generate an API token:
   - Go to API → Tokens/Keys
   - Click "Generate New Token"
   - Name it (e.g., "NixOS Deployment")
   - Keep this token secure - you'll need it for automation (optional)

### 3. Create the Droplet

You can create the droplet via web UI or CLI:

#### Option A: Web UI
1. Go to Digital Ocean dashboard
2. Click "Create" → "Droplets"
3. Choose:
   - **Image**: Ubuntu 22.04 LTS (any Linux will work, it will be replaced)
   - **Size**: Basic plan, $6/mo minimum (1GB RAM, 1 vCPU, 25GB SSD)
   - **Datacenter**: Choose closest to your users
   - **Authentication**: SSH keys
     - Click "New SSH Key"
     - Paste the content of `~/.ssh/dtg-vps.pub`
     - Name it "dtg-vps"
     - Select this key for the droplet
4. Click "Create Droplet"
5. Note the IP address

#### Option B: CLI (using doctl)
```bash
# Install doctl if needed
nix shell nixpkgs#doctl

# Authenticate
doctl auth init

# Create droplet
doctl compute droplet create dtg-vps \
  --image ubuntu-22-04-x64 \
  --size s-1vcpu-1gb \
  --region nyc3 \
  --ssh-keys $(doctl compute ssh-key list --format ID --no-header) \
  --wait
```

### 4. DNS Configuration

Point your domain to the droplet:

1. Log into your DNS provider (where you bought dtgengineering.com)
2. Add/update A record:
   ```
   Type: A
   Name: @ (or dtgengineering.com)
   Value: YOUR_DROPLET_IP
   TTL: 300 (5 minutes)
   ```
3. Wait for DNS propagation (5-15 minutes)
4. Verify with: `dig dtgengineering.com` or `nslookup dtgengineering.com`

### 5. Tailscale Setup

#### On Your Local Odoo Machine
```bash
# Install Tailscale if not already installed
nix shell nixpkgs#tailscale

# Start and connect to your tailnet
sudo tailscale up

# Note the Tailscale IP address
tailscale status
# Look for this machine's IP (will be 100.x.x.x)
```

#### Generate Auth Key for VPS
1. Go to https://login.tailscale.com/admin/settings/keys
2. Click "Generate auth key"
3. Settings:
   - Reusable: ✓ (so you can redeploy)
   - Ephemeral: ✗ (we want it to persist)
   - Expires: 90 days (or longer)
4. Copy the key (starts with `tskey-auth-...`)
5. Keep this secure - you'll use it after deployment

### 6. Pre-Deployment Configuration

Edit the configuration files in this directory:

#### `default.nix`
1. Update email for ACME:
   ```nix
   email = "your-email@example.com";  # Line ~28
   ```

2. Update Odoo backend IP (after Tailscale setup):
   ```nix
   backend = "http://100.x.x.x:8069";  # Line ~37
   ```
   Replace `100.x.x.x` with your Odoo machine's Tailscale IP

## Deployment

### Initial Deployment with nixos-anywhere

From the root of your nix-config repository:

```bash
# Navigate to flake root
cd /home/dtgagnon/nix-config/nixos

# Validate configuration
nix flake check

# Deploy to Digital Ocean droplet
# Replace YOUR_DROPLET_IP with actual IP address
nix run github:nix-community/nixos-anywhere -- \
  --flake .#dtg-vps \
  root@YOUR_DROPLET_IP
```

This will:
1. Connect to your droplet via SSH
2. Partition the disk according to `disk-config.nix`
3. Install NixOS with your configuration
4. Reboot into the new system

**Time**: Approximately 10-15 minutes

### Post-Deployment Setup

After the system reboots:

```bash
# Connect to the new NixOS system
ssh root@YOUR_DROPLET_IP

# Join your Tailscale network
tailscale up --authkey tskey-auth-YOUR-KEY-HERE

# Verify Tailscale is connected
tailscale status

# Check nginx is running
systemctl status nginx

# Check nginx can reach Odoo backend (update IP first!)
curl -I http://100.x.x.x:8069

# Exit SSH
exit
```

### Verify Deployment

1. **Check HTTPS certificate**:
   ```bash
   curl -I https://dtgengineering.com
   ```
   Should show: `HTTP/2 200` (or 302/303 redirect)

2. **Test in browser**:
   - Navigate to `https://dtgengineering.com`
   - Should see your Odoo instance
   - Certificate should be valid (green lock icon)

3. **Check Odoo functionality**:
   - Log into Odoo
   - Test appointments module
   - Verify real-time features work (WebSocket)

## Updating the Configuration

After making changes to the configuration:

### Option 1: Using deploy-rs (Recommended)
```bash
cd /home/dtgagnon/nix-config/nixos
nix run .#deploy.dtg-vps
```

### Option 2: Manual nixos-rebuild
```bash
nixos-rebuild switch \
  --flake .#dtg-vps \
  --target-host root@YOUR_DROPLET_IP
```

### Option 3: SSH and rebuild locally
```bash
ssh root@YOUR_DROPLET_IP
nixos-rebuild switch --flake /etc/nixos#dtg-vps
```

## Troubleshooting

### DNS Issues
```bash
# Check DNS propagation
dig dtgengineering.com

# Force DNS flush on your machine (if needed)
sudo resolvectl flush-caches  # Linux
dscacheutil -flushcache        # macOS
```

### Certificate Issues
```bash
# SSH into VPS
ssh root@YOUR_DROPLET_IP

# Check ACME logs
journalctl -u acme-dtgengineering.com.service

# Manually trigger certificate renewal
systemctl start acme-dtgengineering.com.service

# Check certificate status
ls -la /var/lib/acme/dtgengineering.com/
```

### Nginx Issues
```bash
# Check nginx configuration
nginx -t

# View nginx logs
journalctl -u nginx -f

# Check if nginx can reach backend
curl -I http://100.x.x.x:8069
```

### Tailscale Issues
```bash
# Check Tailscale status
tailscale status

# Re-authenticate if needed
tailscale up --authkey YOUR-AUTH-KEY

# Verify connectivity to Odoo machine
ping 100.x.x.x  # Replace with Odoo Tailscale IP
```

### Connection Test
```bash
# From VPS, test Odoo connection
curl -v http://100.x.x.x:8069/web/database/selector

# From local network, verify Tailscale
tailscale ping dtg-vps
```

## Monitoring

Consider setting up monitoring for:
- **Uptime**: https://uptimerobot.com (free tier available)
- **SSL Certificate Expiry**: Should auto-renew via ACME
- **Disk Space**: Monitor with `df -h`
- **Memory Usage**: Monitor with `free -h`

## Security Notes

- SSH is configured for key-only authentication (no passwords)
- Firewall only allows ports 22, 80, 443
- Tailscale interface is trusted (all traffic allowed)
- Odoo backend is only accessible via Tailscale (not public internet)
- HTTPS is enforced (HTTP redirects to HTTPS)
- Security headers prevent common attacks (XSS, clickjacking, etc.)

## Cost Estimation

- **Digital Ocean Droplet**: $6/month (1GB RAM)
- **Bandwidth**: 1TB included (should be sufficient)
- **Backups**: +$1.20/month (optional, 20% of droplet cost)
- **Total**: ~$6-8/month

## Future Enhancements

Consider adding:
- [ ] Automated backups to Digital Ocean Spaces or similar
- [ ] Monitoring/alerting (Prometheus + Grafana)
- [ ] Rate limiting for public endpoints
- [ ] Fail2ban for additional SSH protection
- [ ] Multiple Odoo backends for redundancy
- [ ] CDN for static assets (Cloudflare)

## Maintenance

### Regular Tasks
- **Weekly**: Check system logs for errors
- **Monthly**: Verify certificate auto-renewal
- **Quarterly**: Update NixOS configuration and redeploy
- **Annually**: Review and rotate Tailscale auth keys

### Updating NixOS
```bash
cd /home/dtgagnon/nix-config/nixos

# Update flake inputs
nix flake update

# Test locally (if you have a local NixOS machine)
nix flake check

# Deploy updates
nix run .#deploy.dtg-vps
```

## Support Resources

- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **nixos-anywhere**: https://github.com/nix-community/nixos-anywhere
- **Digital Ocean Docs**: https://docs.digitalocean.com
- **Tailscale Docs**: https://tailscale.com/kb/
- **Nginx Docs**: https://nginx.org/en/docs/
- **Odoo Docs**: https://www.odoo.com/documentation/

## Quick Reference

### Important Files
- `default.nix` - Main configuration
- `disk-config.nix` - Disk partitioning
- `hardware.nix` - Hardware-specific settings

### Important Commands
```bash
# Deploy
nix run github:nix-community/nixos-anywhere -- --flake .#dtg-vps root@IP

# Update
nixos-rebuild switch --flake .#dtg-vps --target-host root@IP

# Check status
ssh root@IP systemctl status nginx tailscaled

# View logs
ssh root@IP journalctl -u nginx -f
```

### Important Paths on VPS
- `/etc/nixos` - System configuration
- `/var/lib/acme` - SSL certificates
- `/var/log/nginx` - Nginx logs
- `/persist` - Persistent data (with preservation module)

---

**Questions or Issues?**
Open an issue in the nix-config repository or consult the NixOS documentation.
