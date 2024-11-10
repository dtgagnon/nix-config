{ lib
, config
, namespace
, ...
}:
let
  inherit (lib) mkForce;
  inherit (lib.${namespace}) enabled;
  makeAdmin = if "${config.${namespace}.user.name}" == "dtgagnon" || "admin" || "root" then true else false;
in
{
  snowfallorg.users.${config.spirenix.user.name} = {
    admin = makeAdmin;
  };
  # `install-iso` adds wireless support that
  # is incompatible with networkmanager.
  networking.wireless.enable = mkForce false;

  spirenix = {
    nix = enabled;

    apps.wezterm = enabled; #need to make sys module?

    cli = {
      neovim = enabled; #need to make sys module?
    };

    tools = {
      general = enabled;
      http = enabled; #check what this module is for in jake h config
    };

    hardware = {
      networking = enabled; #need to make module
    };

    services = {
      openssh = enabled;
    };

    security = {
      age = enabled;
      sops-nix = enabled;
      sudo = enabled;
    };

    system = {
      boot = enabled; #need to make module
      fonts = enabled;
      locale = enabled;
      time = enabled;
      xkb = enabled;
    };
  };
}
