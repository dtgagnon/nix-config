# Deploy-rs configuration for remote NixOS hosts
#
# This defines deployment targets for use with `deploy .#hostname`
# SSH configuration should be set up in ~/.ssh/config for each host
{
  # Remote servers - SSH as dtgagnon, run commands as root via sudo
  slim = {
    profiles.system = {
      user = "root";
      sshUser = "dtgagnon";
    };
  };

  spirepoint = {
    profiles.system = {
      user = "root";
      sshUser = "dtgagnon";
    };
  };

  dtg-vps = {
    profiles.system = {
      user = "root";
      sshUser = "dtgagnon";
    };
  };

  oranix = {
    profiles.system = {
      user = "root";
      sshUser = "dtgagnon";
    };
  };

  # Note: DG-PC and DGPC-WSL are local machines
  # Use `nixos-rebuild switch --flake .#hostname` instead of deploy
}
