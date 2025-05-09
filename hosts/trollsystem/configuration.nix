{
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    ../../profiles/base
    ./trollsystem.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostId = "327361eb";

  networking.interfaces.enp1s0.useDHCP = true;
  networking.interfaces.enp1s0.ipv6.addresses = [{
    address = "2a01:4f8:1c17:6531::1";
    prefixLength = 64;
  }];
  networking.interfaces.enp1s0.ipv6.routes = [{
    address = "::";
    prefixLength = 0;
    via = "fe80::1";
  }];

  system.stateVersion = "24.11";
}
