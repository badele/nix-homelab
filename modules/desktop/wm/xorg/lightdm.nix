{
  ...
}:
{
  programs.zsh.enable = true;

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
      autoLogin.user = "badele";
      defaultSession = "none+i3";
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
