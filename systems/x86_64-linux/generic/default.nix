{
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    # ./disk-config.nix
    # ./hardware.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.neovim
  ];

  users.users.root = {
    initialPassword = "n!xos";
    openssh.authorizedKeys.keys = [ "KEY" ]; # Replace "KEY" with your public key
  };

  system.stateVersion = "24.11";
}
