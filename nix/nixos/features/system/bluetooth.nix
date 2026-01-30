{ pkgs
, ...
}:
{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  services.pulseaudio.enable = true;
  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    bluetuith
  ];
}
