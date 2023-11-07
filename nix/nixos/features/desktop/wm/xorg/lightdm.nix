{ config, pkgs, ... }:
{

  imports = [
    ../../../../../modules/nixos/host.nix
  ];

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw 
  services.xserver = {
    enable = true;
    #xkbVariant = "";
    xkbOptions = "caps:shiftlock";
    layout = "fr";
    videoDrivers = [ "intel" "i965" "nvidia" ];
    displayManager = {
      lightdm.enable = true;
      defaultSession = config.hostprofile.autologin.session;
      autoLogin.user = config.hostprofile.autologin.user;
    };

    # Touchpad
    libinput = {
      enable = true;
      naturalScrolling = true;
      middleEmulation = false;
      tapping = true;
    };
    windowManager.i3.enable = true;
  };
}
