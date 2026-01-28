{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;
  cfg = config.${namespace}.services.radicale;
in
{
  options.${namespace}.services.radicale = {
    enable = mkBoolOpt false "Enable Radicale CalDAV/CardDAV server";

    host = mkOpt types.str "127.0.0.1" "Address to bind to (use 0.0.0.0 for all interfaces)";
    port = mkOpt types.port 5232 "Port to listen on";

    auth = {
      type = mkOpt (types.enum [
        "none"
        "htpasswd"
      ]) "htpasswd" "Authentication type";
      htpasswdFile = mkOpt (types.nullOr types.path) null "Path to htpasswd file for authentication";
      encryption = mkOpt (types.enum [
        "plain"
        "bcrypt"
      ]) "bcrypt" "Password encryption method (bcrypt recommended)";
    };

    storage = {
      path = mkOpt types.str "/var/lib/radicale/collections" "Path to store calendar/contact data";
      gitBackup = mkBoolOpt false "Enable git-based version control for calendar data";
    };

    settings = mkOpt (types.attrsOf (
      types.attrsOf types.anything
    )) { } "Additional Radicale settings (INI format sections)";

    rights = mkOpt (types.attrsOf (types.attrsOf types.str)) { } "Access control rights configuration";

    openFirewall = mkBoolOpt false "Open firewall port for Radicale";
  };

  config = mkIf cfg.enable {
    services.radicale = {
      enable = true;

      settings = lib.recursiveUpdate {
        server.hosts = [ "${cfg.host}:${toString cfg.port}" ];

        auth =
          lib.mkIf (cfg.auth.type == "htpasswd") {
            type = "htpasswd";
            htpasswd_filename = cfg.auth.htpasswdFile;
            htpasswd_encryption = cfg.auth.encryption;
          }
          // lib.optionalAttrs (cfg.auth.type == "none") {
            type = "none";
          };

        storage = {
          filesystem_folder = cfg.storage.path;
        }
        // lib.optionalAttrs cfg.storage.gitBackup {
          hook = "${pkgs.git}/bin/git add -A && (${pkgs.git}/bin/git diff --cached --quiet || ${pkgs.git}/bin/git commit -m 'Changes by %(user)s')";
        };
      } cfg.settings;

      rights = lib.mkIf (cfg.rights != { }) cfg.rights;
    };

    # Default rights: users can read/write their own calendars
    services.radicale.rights = lib.mkIf (cfg.rights == { }) {
      root = {
        user = ".+";
        collection = "";
        permissions = "R";
      };
      principal = {
        user = ".+";
        collection = "{user}";
        permissions = "RW";
      };
      calendars = {
        user = ".+";
        collection = "{user}/[^/]+";
        permissions = "rw";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    # Initialize git repo if gitBackup is enabled
    systemd.services.radicale.preStart = lib.mkIf cfg.storage.gitBackup ''
      if [ ! -d "${cfg.storage.path}/.git" ]; then
        ${pkgs.git}/bin/git -C "${cfg.storage.path}" init
        ${pkgs.git}/bin/git -C "${cfg.storage.path}" config user.email "radicale@localhost"
        ${pkgs.git}/bin/git -C "${cfg.storage.path}" config user.name "Radicale"
      fi
    '';
  };
}
