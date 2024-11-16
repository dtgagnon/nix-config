{ lib
, host
, config
, namespace
, ...
}:
let
  inherit (lib.${namespace}) enabled;
  makeAdmin = if "${config.${namespace}.user.name}" == "dtgagnon" || "admin" || "root" then true else false;
in
{
  # imports = [ ./hardware.nix ];

  snowfallorg.users.${config.spirenix.user.name} = {
    admin = makeAdmin;
  };

  networking.hostName = host;

  services.pipewire = { enable = true; pulse.enable = true; };

  spirenix = {
    suites = {
      common = enabled;
      networking = enabled;
    };

    system = {
      disko = { enable = true; device = "/dev/nvme0n1"; };
      impermanence = enabled;
    };

    virtualisation = {
      podman = enabled;
      kvm = enabled;
    };
  };

  system.stateVersion = "24.05";
}
