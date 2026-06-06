{ lib, ... }:
{
  imports = [
    ./office.nix
  ];

  # desktop timezone, server use UTC
  time.timeZone = lib.mkDefault "Europe/Paris";
}
