# Caddy Quick Reference

## Common Commands

```bash
# Status and logs
systemctl status caddy
journalctl -u caddy -f

# Restart after config changes
sudo systemctl restart caddy

# Test rebuild (doesn't activate)
nixos-rebuild test --flake .#spirepoint

# Activate changes
nixos-rebuild switch --flake .#spirepoint

# View active Caddy config
caddy adapt --config /etc/caddy/Caddyfile

# Generate password hash
nix run nixpkgs#caddy -- hash-password --plaintext 'mypassword'
```

## Service Ports Reference

| Service | Default Port | Protocol |
|---------|--------------|----------|
| Jellyfin | 8096 | HTTP |
| Jellyseerr | 5055 | HTTP |
| Sonarr | 8989 | HTTP |
| Radarr | 7878 | HTTP |
| Prowlarr | 9696 | HTTP |
| Bazarr | 6767 | HTTP |
| Lidarr | 8686 | HTTP |
| Readarr | 8787 | HTTP |
| qBittorrent | 8080 | HTTP |
| SABnzbd | 8080 | HTTP |
| Immich | 2283 | HTTP |
| Home Assistant | 8123 | HTTP |
| Audiobookshelf | 13378 | HTTP |
| Odoo | 8069 | HTTP |
| Ntfy | 2586 | HTTP |

## Configuration Templates

### Tailnet-Only Service
```nix
service-name = {
  backend = "http://localhost:PORT";
  useTailscale = true;
};
# Access: https://service-name.TAILNET.ts.net
```

### Public Service (Subdomain)
```nix
service-name = {
  backend = "http://localhost:PORT";
  subdomain = "service";  # service.DOMAIN.com
};
# Requires: DNS A record, ports 80/443 forwarded
```

### Public Service (Custom Domain)
```nix
service-name = {
  backend = "http://localhost:PORT";
  domain = "custom.domain.com";
};
# Requires: DNS A record pointing to your IP
```

### With Basic Auth
```nix
service-name = {
  backend = "http://localhost:PORT";
  subdomain = "service";
  enableBasicAuth = true;
};

# Also configure:
basicAuthUsers.username = "$2a$14$hash";
```

### With IP Whitelist
```nix
service-name = {
  backend = "http://localhost:PORT";
  subdomain = "service";
  allowedIPs = [
    "203.0.113.0/24"    # Your network
    "100.64.0.0/10"     # Tailscale range
  ];
};
```

### With Custom Caddy Config
```nix
service-name = {
  backend = "http://localhost:PORT";
  subdomain = "service";
  extraConfig = ''
    header {
      X-Custom-Header "value"
      Strict-Transport-Security "max-age=31536000;"
    }

    # Websocket support
    @websocket {
      header Connection Upgrade
      header Upgrade websocket
    }
    reverse_proxy @websocket http://localhost:PORT
  '';
};
```

## DNS Configuration

### Cloudflare (Example)
```
Type: A
Name: jellyfin
Content: YOUR.PUBLIC.IP.ADDRESS
Proxy: Depends (orange cloud off for direct, on for CF proxy)
TTL: Auto
```

### Wildcard (Recommended)
```
Type: A
Name: *
Content: YOUR.PUBLIC.IP.ADDRESS
TTL: Auto
```
Allows any subdomain to work automatically.

## Firewall & Port Forwarding

### NixOS Firewall (Automatic with module)
```nix
networking.firewall.allowedTCPPorts = [ 80 443 ];
```

### Router Port Forwarding
```
External Port 80  → spirepoint_IP:80   (TCP)
External Port 443 → spirepoint_IP:443  (TCP)
```

## Tailscale Setup

```bash
# Check tailnet name
tailscale status | head -n1

# Test HTTPS capability
sudo tailscale cert --help

# View current status
sudo tailscale serve status

# Enable MagicDNS (if not enabled)
# Go to: https://login.tailscale.com/admin/dns
```

## Troubleshooting

### Check if service is listening
```bash
sudo ss -tlnp | grep :8989  # Replace with your port
curl http://localhost:8989   # Should respond
```

### Test Caddy proxy locally
```bash
curl -H "Host: jellyfin.example.com" http://localhost:80
```

### Check ACME cert status
```bash
journalctl -u caddy | grep -i acme
ls -la /var/lib/caddy/.local/share/caddy/certificates/
```

### View generated Caddyfile
```bash
cat /etc/caddy/Caddyfile
```

### Check DNS propagation
```bash
dig jellyfin.example.com
nslookup jellyfin.example.com 8.8.8.8
```

### Test external access
```bash
# From another network
curl -I https://jellyfin.example.com

# Or use online tool
# https://www.whatsmydns.net/
```

## Security Checklist

- [ ] Admin services (Sonarr, Radarr, etc.) are Tailnet-only
- [ ] Public services have strong authentication enabled
- [ ] Port 80/443 only forwarded (not service ports directly)
- [ ] Regular NixOS updates configured
- [ ] Fail2ban configured (optional but recommended)
- [ ] Monitoring/alerting set up for unauthorized access
- [ ] Backup authentication credentials
- [ ] Document which services are public vs private

## Example Complete Configuration

```nix
spirenix.services.caddy = {
  enable = true;
  email = "admin@example.com";
  baseDomain = "example.com";
  tailnetName = "mytailnet";

  proxiedServices = {
    # Public media
    jellyfin = {
      backend = "http://localhost:8096";
      subdomain = "watch";
    };

    # Private admin
    sonarr = {
      backend = "http://localhost:8989";
      useTailscale = true;
    };

    radarr = {
      backend = "http://localhost:7878";
      useTailscale = true;
    };

    # Private photos with auth
    immich = {
      backend = "http://localhost:2283";
      subdomain = "photos";
      enableBasicAuth = true;
    };
  };

  basicAuthUsers = {
    admin = "$2a$14$...";  # From: caddy hash-password
  };
};
```
