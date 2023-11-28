{ pkgs
, ...
}:
{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  hardware.pulseaudio.enable = true;
  services.blueman.enable = true;
}
