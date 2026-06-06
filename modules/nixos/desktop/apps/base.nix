{ lib, ... }:
{
  imports = [
  ];

  # desktop timezone, server use UTC
  time.timeZone = lib.mkDefault "Europe/Paris";

  # Use compressed swap in RAM to reduce wear on the SSD and improve performance
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 20;
  };
}
