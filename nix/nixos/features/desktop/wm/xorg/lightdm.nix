{
  config,
  lib,
  pkgs,
  ...
}:
{

  imports = [ ../../../../../modules/nixos/homelab ];

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw
  services =
    let
      autoLogin =
        if config.homelab.currentHost.autologin != null then
          config.homelab.currentHost.autologin
        else
          config.hostprofile.autologin;
    in
    {
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

      displayManager = lib.mkIf (autoLogin.user != "" && autoLogin.session != "") {
        autoLogin.user = autoLogin.user;
        defaultSession = autoLogin.session;
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
