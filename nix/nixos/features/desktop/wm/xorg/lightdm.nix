{ config, pkgs, ... }:
{
  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw 
  services.xserver = {
    enable = true;
    #xkbVariant = "";
    xkbOptions = "caps:shiftlock";
    layout = "fr";
    videoDrivers = [ "intel" "i965" "nvidia" ];
    displayManager = {
      defaultSession = "none+i3";
      lightdm.enable = true;
      autoLogin = {
        user = "badele";
      };
    };
    windowManager.i3.enable = true;
    synaptics.enable = true;
  };
}
