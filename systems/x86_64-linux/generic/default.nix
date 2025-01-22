{ lib
, pkgs
, config
, inputs
, ...
}:

{
  imports = [
    ./disk-config.nix
    ./hardware.nix
  ];

  fileSystems."/boot".options = [ "umask=0077" ];
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = lib.mkDefault 3;
        consoleMode = lib.mkDefault "max";
        editor = false;
      };
    };
    initrd = {
      systemd.enable = true;
      systemd.emergencyAccess = true; # don't need to enter password in emergency mode
      luks.forceLuksSupportInInitrd = true;
      availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "sd_mod" "rtsx_usb_sdmmc" ];
      kernelModules = [ "dm-snapshot" ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    kernelParams = [
      "systemd.setenv=SYSTEMD_SULOGIN_FORCE=1"
      "systemd.show_status=true"
      "systemd.log_target=console"
      "systemd.journald.forward_to_console=1"
    ];
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
    password = "1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID9zKXOt7YQW0NK0+GsUQh4cgmcLyurpeTzYXMYysUH1 dtgagnon"
    ]; # Replace "KEY" with your public key
  };

  # map user disabling across the Attrs of usernames
  snowfallorg.users =
    builtins.mapAttrs
      (username: config: {
        create = false;
        home.enable = false;
      })
      { gachan = null; admin = null; };

  # same thing just using pipe for practice
  # snowfallorg.users =
  #   { dtgagnon = null; gachan = null; admin = null; }
  #     |> builtins.mapAttrs { create = false; home.enable = false; }


  system.stateVersion = "24.11";
}
