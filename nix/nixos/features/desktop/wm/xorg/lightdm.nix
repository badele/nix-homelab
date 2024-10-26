{ config, lib, pkgs, ... }:
{

  imports = [
    ../../../../../modules/nixos/host.nix
  ];

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw
  services = {
    xserver = {
      enable = true;
      #xkbVariant = "";
      xkb = {
        options = "caps:shiftlock";
        layout = "fr";
      };
      displayManager = {
        lightdm.enable = true;
        # defaultSession = config.hostprofile.autologin.session;
      };

      windowManager.i3.enable = true;
    };

    displayManager = {
      autoLogin.user = config.hostprofile.autologin.user;
      defaultSession = config.hostprofile.autologin.session;
    };

    # Touchpad
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        middleEmulation = false;
        tapping = true;
      };
    };

  };
}
