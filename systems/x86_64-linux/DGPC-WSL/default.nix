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
  imports = [ ./hardware.nix ];

  snowfallorg.users.${config.spirenix.user.name} = {
    admin = makeAdmin;
  };

  networking.hostName = "DGPC-WSL";

  spirenix = {
    suites = {
      common = enabled;
    };
    services.tailscale = {
      enable = true;
      authKeyDir = "/run/secrets/tailscale-authKey";
      hostname = host;
    };
		virtualization = {
			podman = enabled;
			kvm = enabled;
			looking-glass = enabled;
		};
  };

  system.stateVersion = "24.05";
}
