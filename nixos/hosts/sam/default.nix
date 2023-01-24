{ lib
, ...
}:
{
  imports = [
    ../../modules/hardware/samsung-n210.nix
  ];

  networking.hostName = "sam";
  networking.useDHCP = lib.mkDefault true;

  system.stateVersion = "22.05";
}
