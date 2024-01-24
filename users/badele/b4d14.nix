##########################################################
# HOME-MANAGER (user)
##########################################################
{ config
, inputs
, outputs
, pkgs
, lib
, ...
}:
let
  feh = "${pkgs.feh}/bin/feh";
in
{
  imports = [
    # User
    ./commons.nix

    # Commons packages
    ../../nix/home-manager/commons/packages.nix

    # Editor
    ../../nix/home-manager/features/term/editor/lazyvim.nix

    # Term
    ../../nix/home-manager/features/term/base.nix
    ../../nix/home-manager/features/term/security

    # Language
    ../../nix/home-manager/features/language/c.nix
    ../../nix/home-manager/features/language/go.nix
    ../../nix/home-manager/features/language/python.nix

    # Desktop
    ../../nix/home-manager/features/desktop/commons/base.nix
    ../../nix/home-manager/features/desktop/xorg/base.nix
    ../../nix/home-manager/features/desktop/xorg/wm/i3.nix

    # Web browser
    ../../nix/home-manager/features/desktop/commons/google-chrome.nix
    ../../users/badele/firefox.nix

    # Multimedia
    ../../nix/home-manager/features/desktop/commons/spotify.nix

    # Development term
    ../../nix/home-manager/features/term/development/base.nix

    # Development desktop
    ../../nix/home-manager/features/desktop/commons/development/packages.nix
    ../../nix/home-manager/features/desktop/commons/development/vscode.nix
  ] ++ (builtins.attrValues outputs.homeManagerModules);


  ###############################################################################
  # Packages
  ###############################################################################
  home.packages = with pkgs; [
    # Communication
    slack
  ];


  programs = {
    ####################################
    # Monitors configuration
    # autorandr --fingerprints
    # autorandr --config
    ####################################
    autorandr = {
      enable = true;

      profiles = {
        "home-up" = {
          fingerprint = {
            eDP1 = "00ffffffffffff0030e4b30600000000001f0104a522157806a205a65449a2250e505400000001010101010101010101010101010101283c80a070b023403020360050d21000001a203080a070b023403020360050d21000001a000000fe00344457564a813135365755310a0000000000024131b2001100000a010a202000ad";
            DP2 = "00ffffffffffff0010acd3a14249343229210104a53b21783be755a9544aa1260d5054a54b00714f8180a9c0d1c00101010101010101565e00a0a0a029503020350055502100001a000000ff00443451334844330a2020202020000000fc0044454c4c20533237323244430a000000fd00304b72723c010a202020202020010c020325f14f101f051404131211030216150706012309070783010000681a00000101304b007e3900a080381f4030203a0055502100001a023a801871382d40582c450055502100001ed97600a0a0a034503020350055502100001a00000000000000000000000000000000000000000000000000000000000000000000000092";
          };
          config = {
            eDP1 = {
              enable = true;
              primary = true;
              crtc = 0;
              position = "320x1440";
              mode = "1920x1200";
              rate = "60.00";
            };
            DP2 = {
              enable = true;
              crtc = 1;
              position = "0x0";
              mode = "2560x1440";
              rate = "60.00";
            };
          };
          hooks.postswitch = ''
            ${pkgs.i3}/bin/i3-msg restart
            ${feh} --bg-scale '${config.wallpaper}'
          '';
        };
      };
    };
  };

  # inv home.deploy ; neofetch ; ll
  wallpaper = pkgs.wallpapers.forest-deer-landscape;
}
