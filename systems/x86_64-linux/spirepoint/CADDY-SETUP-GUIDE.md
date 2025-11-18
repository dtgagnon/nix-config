# Caddy Reverse Proxy Setup Guide for Spirepoint

This guide walks you through setting up Caddy as a reverse proxy for your services on spirepoint.

## Overview

The Caddy module provides three ways to expose services:

1. **Tailnet-only** - Only accessible via Tailscale VPN (admin interfaces)
2. **Public domain** - Accessible from internet via your domain (user-facing services)
3. **Hybrid** - Same service accessible both ways

## Prerequisites

### 1. Tailscale Setup (For Tailnet services)

If you want to use Tailscale HTTPS:

```bash
# On spirepoint, enable Tailscale HTTPS
sudo tailscale cert --help  # Check if cert feature is available
sudo tailscale serve https / http://localhost:80  # Test
```

**Get your tailnet name:**
```bash
tailscale status | grep "yourtailnet"
# Or check: https://login.tailscale.com/admin/settings/general
```

### 2. Domain Setup (For Public services)

**Option A: Subdomain wildcard (recommended)**
Create a DNS A record:
```
*.spire.example.com  →  YOUR_PUBLIC_IP
```

**Option B: Individual subdomains**
```
jellyfin.example.com  →  YOUR_PUBLIC_IP
photos.example.com    →  YOUR_PUBLIC_IP
# ... etc
```

**Port Forwarding:**
On your router, forward ports 80 and 443 to spirepoint's local IP.

### 3. Find Service Ports

Common ports (defaults):
- Jellyfin: 8096
- Sonarr: 8989
- Radarr: 7878
- Prowlarr: 9696
- Immich: 2283
- Home Assistant: 8123
- Jellyseerr: 5055
- Audiobookshelf: 13378
- qBittorrent: 8080 (web UI)
- SABnzbd: 8080
- Odoo: 8069

Verify with:
```bash
sudo ss -tlnp | grep LISTEN
```

## Configuration Steps

### Step 1: Copy Example Config

The example configuration is in `caddy-config-example.nix`. Review it and customize:

```nix
# In systems/x86_64-linux/spirepoint/default.nix
{
  # ... existing config ...

  spirenix.services.caddy = {
    enable = true;
    email = "your-email@example.com";
    baseDomain = "example.com";  # Your actual domain
    tailnetName = "your-tailnet";  # From tailscale status

    proxiedServices = {
      # Start with a few services first
      jellyfin = {
        backend = "http://localhost:8096";
        subdomain = "jellyfin";
      };

      sonarr = {
        backend = "http://localhost:8989";
        useTailscale = true;  # Tailnet-only
      };
    };
  };
}
```

### Step 2: Rebuild and Test

```bash
# Test the configuration
nixos-rebuild test --use-remote-sudo --flake .#spirepoint

# Check Caddy status
systemctl status caddy

# View Caddy logs
journalctl -u caddy -f

# Check what Caddy is serving
curl -v http://localhost/
```

### Step 3: Verify DNS

```bash
# Check DNS resolution for public services
dig jellyfin.example.com

# Should return your public IP
```

### Step 4: Test HTTPS

**For Public Services:**
```bash
# From any computer
https://jellyfin.example.com
```

Let's Encrypt will automatically provision certificates on first request.

**For Tailnet Services:**
```bash
# From a device connected to Tailscale
https://sonarr.your-tailnet.ts.net
```

## Configuration Patterns

### Pattern 1: Admin Interface (Tailnet-Only)

```nix
sonarr = {
  backend = "http://localhost:8989";
  useTailscale = true;
};
```

- ✅ Only accessible via Tailscale
- ✅ Automatic HTTPS via Tailscale certs
- ✅ No port forwarding needed
- ✅ No DNS configuration needed

### Pattern 2: Public Service (Domain)

```nix
jellyfin = {
  backend = "http://localhost:8096";
  subdomain = "jellyfin";  # Uses baseDomain
};
```

- ✅ Accessible from anywhere
- ✅ Automatic HTTPS via Let's Encrypt
- ⚠️ Requires DNS record
- ⚠️ Requires port forwarding (80, 443)

### Pattern 3: Custom Domain

```nix
blog = {
  backend = "http://localhost:3000";
  domain = "blog.myotherdomain.com";
};
```

### Pattern 4: IP Whitelist

```nix
admin-panel = {
  backend = "http://localhost:9000";
  subdomain = "admin";
  allowedIPs = [
    "1.2.3.4"           # Your home IP
    "100.64.0.0/10"     # Tailscale CGNAT range
  ];
};
```

### Pattern 5: Basic Authentication

First, generate a password hash:
```bash
nix run nixpkgs#caddy -- hash-password --plaintext 'your-password-here'
```

Add to sops secrets (recommended) or directly:
```nix
spirenix.services.caddy = {
  # ...
  basicAuthUsers = {
    admin = "$2a$14$...hash-from-above...";
  };

  proxiedServices = {
    private-service = {
      backend = "http://localhost:8080";
      subdomain = "private";
      enableBasicAuth = true;
    };
  };
};
```

### Pattern 6: Service-Specific Config

```nix
homeassistant = {
  backend = "http://localhost:8123";
  useTailscale = true;
  extraConfig = ''
    # Websocket support
    header {
      X-Forwarded-For {remote_host}
      X-Forwarded-Proto {scheme}
    }

    # Trusted proxy headers for HA
    reverse_proxy http://localhost:8123 {
      header_up X-Forwarded-For {remote_host}
    }
  '';
};
```

## Troubleshooting

### Caddy won't start

```bash
# Check configuration syntax
journalctl -u caddy -n 50

# Test caddy config manually
sudo caddy validate --config /etc/caddy/Caddyfile
```

### Let's Encrypt fails

```bash
# Check logs
journalctl -u caddy | grep -i acme

# Common issues:
# - Port 80/443 not forwarded
# - DNS not propagated yet (wait up to 48h)
# - Rate limited (use staging CA for testing)
```

**Use staging CA while testing:**
```nix
spirenix.services.caddy = {
  extraGlobalConfig = ''
    acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
  '';
};
```

### Tailscale HTTPS not working

```bash
# Verify Tailscale is running
systemctl status tailscaled

# Check Tailscale serve status
sudo tailscale serve status

# Verify in Caddy config
journalctl -u caddy | grep tailscale
```

### Service returns 502 Bad Gateway

```bash
# Backend service not running
systemctl status sonarr  # (or whatever service)

# Backend on wrong port
ss -tlnp | grep 8989

# Check backend is localhost, not 0.0.0.0
curl http://localhost:8989
```

### Can't access from outside network

```bash
# Verify firewall (should show 80, 443)
sudo iptables -L -n | grep -E '80|443'

# Test from outside
# Use https://www.yougetsignal.com/tools/open-ports/

# Check router port forwarding
# WAN:80 → spirepoint_IP:80
# WAN:443 → spirepoint_IP:443
```

## Security Recommendations

### 1. Admin interfaces: Always Tailnet-only
```nix
# ❌ DON'T expose these to public internet:
sonarr, radarr, prowlarr, qbittorrent, sabnzbd

# ✅ DO use Tailscale for these
proxiedServices.sonarr.useTailscale = true;
```

### 2. Public services: Use service auth
```nix
# Jellyfin: Enable user accounts and passwords
# Immich: Configure user authentication
# Don't rely solely on Caddy basic auth
```

### 3. Use Fail2ban (Optional)
```nix
services.fail2ban = {
  enable = true;
  jails.caddy-auth = ''
    enabled = true
    filter = caddy-auth
    logpath = /var/log/caddy/access.log
    maxretry = 3
    bantime = 3600
  '';
};
```

### 4. Regular Updates
```bash
# Update flake inputs monthly
nix flake update
nixos-rebuild switch --flake .#spirepoint
```

## Next Steps

1. **Start small**: Enable Caddy with 1-2 services first
2. **Test thoroughly**: Verify both Tailnet and public access
3. **Add services gradually**: One at a time, testing each
4. **Monitor logs**: Watch for errors or unauthorized access attempts
5. **Consider Authentik/Authelia**: For more advanced SSO needs

## Reference Links

- [Caddy Documentation](https://caddyserver.com/docs/)
- [Tailscale HTTPS](https://tailscale.com/kb/1153/enabling-https/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [NixOS Caddy Options](https://search.nixos.org/options?query=services.caddy)
