{ lib
, pkgs
, modulesPath
, ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    # ./hardware.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  spirenix.services = {
    openssh.enable = true;
    tailscale.enable = true;
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.neovim
    pkgs.age
    pkgs.sops
  ];

  users.users.root = {
    initialPassword = "n!xos";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9zKXOt7YQW0NK0+GsUQh4cgmcLyurpeTzYXMYysUH1 dtgagnon"
    ]; # Replace "KEY" with your public key
  };

  system.stateVersion = "24.11";
}
