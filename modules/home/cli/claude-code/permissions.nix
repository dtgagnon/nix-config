{
  lib,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf flatten;
  cfg = config.${namespace}.cli.claude-code;

  # Commands allowed both locally AND via SSH to any host
  # These are universally safe read-only commands
  allHostsCommands = [
    # Git read-only operations
    "git diff"
    "git status"
    "git log"
    "git branch"
    "git show"
    "git remote"
    "git rev-parse"
    "git describe"
    "git tag"
    "git ls-files"
    "git ls-tree"
    "git cat-file"
    "git stash list"

    # Systemctl read-only operations (no start/stop/restart/enable/disable)
    "systemctl status"
    "systemctl list-units"
    "systemctl list-unit-files"
    "systemctl is-active"
    "systemctl is-enabled"
    "systemctl show"
    "systemctl cat"
    "systemctl list-dependencies"
    "systemctl list-sockets"
    "systemctl list-timers"
    "systemctl list-jobs"

    # Journalctl (deny rules block secret-related services)
    "journalctl"

    # System information
    "uname"
    "hostname"
    "uptime"
    "free"
    "df"
    "du"
    "lsblk"
    "lscpu"
    "lspci"
    "lsusb"
    "lsmod"
    "ip addr"
    "ip route"
    "ip link"
    "ss"
    "id"
    "whoami"
    "groups"
    "date"
    "cal"

    # Process information
    "ps"
    "pgrep"
    "pidof"

    # File inspection (non-content)
    "which"
    "whereis"
    "type"
    "file"
    "stat"
    "wc"
    "tree"

    # Network diagnostics
    "ping"
    "dig"
    "host"
    "nslookup"
    "traceroute"
    "mtr"
  ];

  # Commands allowed ONLY on localhost (no SSH auto-allow)
  localOnlyCommands = [
    # Nix read-only operations
    "nix flake show"
    "nix flake metadata"
    "nix flake info"
    "nix eval"
    "nix search"
    "nix path-info"
    "nix fmt"
    "nix derivation show"
    "nix-store -q"
    "nix-store --query"
    "nixos-version"
    "nix --version"
  ];

  # Denied substrings for journalctl (secret-related services)
  journalctlDenyPatterns = [
    "sops"
    "vault"
    "secret"
    "password"
    "credential"
    "gpg-agent"
    "ssh-agent"
    "age-"
  ];

  # Generate permission patterns for commands allowed on all hosts (local + SSH)
  mkAllHostsPermissions = cmd: [
    "Bash(${cmd}:*)"
    "Bash(ssh * \"${cmd}\"*)"
    "Bash(ssh * '${cmd}'*)"
  ];

  # Generate permission patterns for local-only commands (no SSH)
  mkLocalOnlyPermissions = cmd: [
    "Bash(${cmd}:*)"
  ];

  # Generate deny patterns for journalctl (local and SSH)
  mkJournalctlDeny = pattern: [
    "Bash(journalctl*${pattern}*)"
    "Bash(ssh * \"journalctl*${pattern}*\"*)"
    "Bash(ssh * 'journalctl*${pattern}*'*)"
  ];

  allHostsPatterns = flatten (map mkAllHostsPermissions allHostsCommands);
  localOnlyPatterns = flatten (map mkLocalOnlyPermissions localOnlyCommands);
  journalctlDenyList = flatten (map mkJournalctlDeny journalctlDenyPatterns);
in
{
  config = mkIf cfg.enable {
    programs.claude-code.settings.permissions = {
      allow = allHostsPatterns ++ localOnlyPatterns ++ [
        # Web search and fetching (not applicable via SSH)
        "WebSearch"
        "WebFetch"
      ];

      ask = [
        "Bash(curl:*)"
        "Bash(ssh * \"curl\"*)"
        "Bash(ssh * 'curl'*)"
      ];

      deny = [
        # Secret files
        "Read(./.env)"
        "Read(./secrets/**)"
        "Read(**/.env)"
        "Read(**/.env.*)"
        "Read(**/secrets/**)"
      ] ++ journalctlDenyList;
    };
  };
}
