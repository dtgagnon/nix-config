# Example Caddy Reverse Proxy Configuration for Spirepoint
# This file demonstrates how to configure Caddy to serve your services
#
# To use: Add the spirenix.services.caddy configuration block to your
# systems/x86_64-linux/spirepoint/default.nix file

{
  spirenix.services.caddy = {
    enable = true;
    email = "your-email@example.com";  # For Let's Encrypt notifications
    baseDomain = "example.com";  # Replace with your actual domain
    tailnetName = "your-tailnet";  # Replace with your Tailscale tailnet name

    proxiedServices = {
      # === TAILNET-ONLY SERVICES (Admin interfaces) ===
      # These are only accessible when connected to your Tailscale VPN
      # They'll be available at https://SERVICE.your-tailnet.ts.net

      sonarr = {
        backend = "http://localhost:8989";
        useTailscale = true;
      };

      radarr = {
        backend = "http://localhost:7878";
        useTailscale = true;
      };

      prowlarr = {
        backend = "http://localhost:9696";
        useTailscale = true;
      };

      bazarr = {
        backend = "http://localhost:6767";
        useTailscale = true;
      };

      lidarr = {
        backend = "http://localhost:8686";
        useTailscale = true;
      };

      readarr = {
        backend = "http://localhost:8787";
        useTailscale = true;
      };

      qbittorrent = {
        backend = "http://localhost:8080";
        useTailscale = true;
      };

      sabnzbd = {
        backend = "http://localhost:8080";
        useTailscale = true;
      };

      jellyseerr = {
        backend = "http://localhost:5055";
        useTailscale = true;
      };

      homeassistant = {
        backend = "http://localhost:8123";
        useTailscale = true;
        extraConfig = ''
          # Home Assistant requires websocket support
          header {
            X-Forwarded-For {remote_host}
            X-Forwarded-Proto {scheme}
          }
        '';
      };

      # === PUBLIC SERVICES (with authentication) ===
      # These are accessible from the public internet via your domain
      # Make sure to set up DNS records pointing to your server's IP

      jellyfin = {
        backend = "http://localhost:8096";
        subdomain = "jellyfin";  # Creates jellyfin.example.com
        extraConfig = ''
          # Jellyfin-specific headers
          header {
            # Security headers
            Strict-Transport-Security "max-age=31536000;"
            X-Content-Type-Options "nosniff"
            X-Frame-Options "SAMEORIGIN"
            Referrer-Policy "no-referrer-when-downgrade"
          }
        '';
      };

      immich = {
        backend = "http://localhost:2283";
        subdomain = "photos";  # Creates photos.example.com
        # Uncomment to add basic auth:
        # enableBasicAuth = true;
      };

      audiobookshelf = {
        backend = "http://localhost:13378";  # Default ABS port
        subdomain = "audiobooks";
        # Uses service's own authentication
      };

      ntfy = {
        backend = "http://localhost:2586";  # Default ntfy port
        subdomain = "ntfy";
      };

      # === HYBRID APPROACH ===
      # Odoo accessible via both Tailscale AND public domain

      odoo-public = {
        backend = "http://localhost:8069";
        subdomain = "odoo";
        # This creates the public endpoint
      };

      odoo-tailnet = {
        backend = "http://localhost:8069";
        useTailscale = true;
        tailscaleHostname = "odoo.your-tailnet.ts.net";
        # This creates the tailnet endpoint
      };
    };

    # === OPTIONAL: Basic Auth Users ===
    # Generate password hash with: nix run nixpkgs#caddy -- hash-password --plaintext 'yourpassword'
    # Then add to sops secrets and reference here
    # basicAuthUsers = {
    #   admin = "$2a$14$...hash...";
    # };

    # === OPTIONAL: Extra configuration ===
    # extraGlobalConfig = ''
    #   # Global Caddy directives go here
    #   # For example, staging Let's Encrypt for testing:
    #   # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
    # '';
  };
}
