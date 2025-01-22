{ lib
, pkgs
, config
, inputs
, ...
}:

{
  imports = [
    ../slim/disk-config.nix
    ../slim/hardware.nix
  ];

  fileSystems."/boot".options = [ "umask=0077" ];
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        editor = false;
      };
    };
    initrd = {
      systemd.enable = true;
      availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "sd_mod" "rtsx_usb_sdmmc" ];
      kernelModules = [ "dm-snapshot" ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    ports = [ 22 22022 ];
    settings.PermitRootLogin = "yes";
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
  };

  security.pam = {
    rssh.enable = true;
    services.sudo = {
      rssh = true;
    };
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.vim
    pkgs.age
    pkgs.sops
    pkgs.rsync
    pkgs.wget
  ];

  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
    settings = {
      experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
      warn-dirty = false;
    };
  };

  users.users.root = {
    initialPassword = "1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9zKXOt7YQW0NK0+GsUQh4cgmcLyurpeTzYXMYysUH1 dtgagnon"
    ]; # Replace "KEY" with your public key
  };

  system.stateVersion = "24.11";
}
