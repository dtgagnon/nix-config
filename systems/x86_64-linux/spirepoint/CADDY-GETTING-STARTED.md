# Getting Started with Caddy on Spirepoint

Follow this checklist to set up reverse proxying for your services.

## Phase 1: Preparation (10 minutes)

### 1. Gather Information

- [ ] Your domain name: `_________________`
- [ ] Your Tailscale tailnet name: `_________________`
  - Find it: `tailscale status | head -n1`
- [ ] Your public IP address: `_________________`
  - Find it: `curl ifconfig.me`
- [ ] Email for Let's Encrypt: `_________________`

### 2. Decide on Service Exposure

Fill in which services should be:

**Public (accessible from internet):**
- [ ] Jellyfin - for remote streaming
- [ ] ________________________
- [ ] ________________________

**Tailnet-Only (VPN required):**
- [ ] Sonarr - admin interface
- [ ] Radarr - admin interface
- [ ] Prowlarr - admin interface
- [ ] qBittorrent - torrent client
- [ ] ________________________
- [ ] ________________________

## Phase 2: DNS Configuration (15 minutes)

### Option A: Wildcard DNS (Recommended)

- [ ] Log into your domain registrar/DNS provider
- [ ] Create A record: `*.spire.YOURDOMAIN.com → YOUR_PUBLIC_IP`
- [ ] Wait for propagation (test with `dig jellyfin.spire.YOURDOMAIN.com`)

### Option B: Individual Subdomains

- [ ] Create A record for each public service:
  - `jellyfin.YOURDOMAIN.com → YOUR_PUBLIC_IP`
  - `photos.YOURDOMAIN.com → YOUR_PUBLIC_IP`
  - etc.

### Verify DNS
```bash
dig jellyfin.YOURDOMAIN.com
# Should return your public IP
```

## Phase 3: Router Configuration (5 minutes)

- [ ] Access your router admin panel
- [ ] Find Port Forwarding section
- [ ] Add port forwarding rules:
  - External Port 80 (TCP) → spirepoint IP:80
  - External Port 443 (TCP) → spirepoint IP:443
- [ ] Save changes

### Verify Port Forwarding
- [ ] Use https://www.yougetsignal.com/tools/open-ports/
- [ ] Test ports 80 and 443 with your public IP
- [ ] Both should show "open"

## Phase 4: Configure Caddy (15 minutes)

### 1. Edit spirepoint configuration

```bash
cd ~/nix-config/nixos
$EDITOR systems/x86_64-linux/spirepoint/default.nix
```

### 2. Add Caddy configuration

Reference `caddy-config-example.nix` and add to your default.nix:

```nix
spirenix.services.caddy = {
  enable = true;
  email = "YOUR_EMAIL";  # From step 1
  baseDomain = "YOURDOMAIN.com";  # From step 1
  tailnetName = "YOUR_TAILNET";  # From step 1

  proxiedServices = {
    # Start with ONE service to test
    jellyfin = {
      backend = "http://localhost:8096";
      subdomain = "jellyfin";
    };
  };
};
```

- [ ] Configuration added
- [ ] Email, domain, and tailnet name updated
- [ ] Starting with 1-2 services only

### 3. Test the configuration

```bash
# From ~/nix-config/nixos directory
nixos-rebuild test --use-remote-sudo --flake .#spirepoint
```

- [ ] Build succeeded
- [ ] No errors in output

### 4. Check Caddy status

```bash
systemctl status caddy
```

- [ ] Service is active (running)
- [ ] No errors in status

### 5. Check logs

```bash
journalctl -u caddy -f
```

- [ ] No error messages
- [ ] Watch for ACME certificate acquisition

## Phase 5: Testing (10 minutes)

### Test Public Service

From any computer (not connected to Tailscale):

```bash
https://jellyfin.YOURDOMAIN.com
```

- [ ] Page loads successfully
- [ ] HTTPS works (green padlock)
- [ ] No certificate errors
- [ ] Service works normally

### Test Tailnet Service

From a device connected to your Tailscale:

```bash
https://sonarr.YOURTAILNET.ts.net
```

- [ ] Page loads successfully
- [ ] HTTPS works
- [ ] Service works normally

### Common Issues

**503 Service Unavailable**
- Backend service not running: `systemctl status jellyfin`
- Wrong port in backend URL

**404 Not Found**
- DNS not propagated yet (wait 5-60 minutes)
- Check with `dig yourdomain.com`

**Certificate Error**
- ACME challenge failed - check ports 80/443 are forwarded
- Check logs: `journalctl -u caddy | grep -i acme`

**Can't Access Tailnet Service**
- Tailscale not running: `systemctl status tailscaled`
- Not connected to VPN: `tailscale status`

## Phase 6: Add More Services (Ongoing)

Once first service works:

- [ ] Add one new service at a time
- [ ] Test each before adding next
- [ ] Follow patterns from `caddy-config-example.nix`
- [ ] Keep admin interfaces on Tailnet only

### Quick add template

```nix
proxiedServices = {
  # ... existing services ...

  NEW_SERVICE = {
    backend = "http://localhost:PORT";
    # For public:
    subdomain = "SUBDOMAIN";
    # For Tailnet:
    # useTailscale = true;
  };
};
```

Then:
```bash
nixos-rebuild switch --use-remote-sudo --flake .#spirepoint
systemctl status caddy
journalctl -u caddy -n 50
```

## Phase 7: Security Hardening (Recommended)

### Enable Authentication

For sensitive public services (like Immich):

```bash
# Generate password hash
nix run nixpkgs#caddy -- hash-password --plaintext 'your-strong-password'

# Add to sops secret or configuration
```

```nix
spirenix.services.caddy = {
  # ...
  basicAuthUsers = {
    admin = "$2a$14$HASH_FROM_ABOVE";
  };

  proxiedServices = {
    immich = {
      backend = "http://localhost:2283";
      subdomain = "photos";
      enableBasicAuth = true;  # Add this
    };
  };
};
```

- [ ] Password hashes generated
- [ ] Basic auth configured for sensitive services
- [ ] Tested authentication works

### Review Service Exposure

- [ ] All admin tools (Sonarr, Radarr, etc.) are Tailnet-only
- [ ] Public services have their own authentication enabled
- [ ] No unnecessary services exposed
- [ ] Document what's public vs private

### Consider Additional Security

- [ ] Set up Fail2ban
- [ ] Enable monitoring/alerting
- [ ] Regular security updates (nix flake update monthly)
- [ ] Backup authentication credentials

## Need Help?

Check these resources:
- `CADDY-SETUP-GUIDE.md` - Comprehensive guide with patterns
- `CADDY-QUICK-REF.md` - Quick reference for commands and configs
- `caddy-config-example.nix` - Example configuration with all your services

Common commands:
```bash
# View logs
journalctl -u caddy -f

# Restart Caddy
sudo systemctl restart caddy

# Test configuration
nixos-rebuild test --flake .#spirepoint

# Apply configuration
nixos-rebuild switch --flake .#spirepoint
```

## Success Criteria

You're done when:
- [ ] Can access public services from any network via HTTPS
- [ ] Can access private services via Tailscale HTTPS
- [ ] All services work normally through reverse proxy
- [ ] No certificate errors
- [ ] Logs show no errors
- [ ] Security best practices followed

## Next Steps

Once everything works:
1. Consider SSO with Authentik or Authelia (optional, advanced)
2. Set up monitoring with Grafana (optional)
3. Configure automatic backups
4. Document your setup for future reference

Congratulations! 🎉 Your services are now accessible with friendly URLs and proper HTTPS!
