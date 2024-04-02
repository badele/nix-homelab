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

    # Virtualisation
    ../../nix/home-manager/features/desktop/xorg/virtualisation.nix

  ] ++ (builtins.attrValues outputs.homeManagerModules);


  ###############################################################################
  # Packages
  ###############################################################################
  home.packages = with pkgs; [
    # DAO/CAO
    openscad
    librecad
    solvespace
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
            eDP1 = "00ffffffffffff004d109a1400000000041c0104a52213780ede50a3544c99260f505400000001010101010101010101010101010101ac3780a070383e403020350058c210000018000000000000000000000000000000000000000000fe00544b365237804c513135364d31000000000002410328001200000a010a2020002b";
            DP3 = "00ffffffffffff0009d107779c0200000b110103802f1e78eecf75a455499927135054bdef80454f614f01018180818f714f0101010121399030621a274068b03600b10f1100001cd50980a0205e631010605208782d1100001a000000fd00384c1e5411000a202020202020000000fc0042656e51204650323232570a0a01d002031b71230907078301000067030c002000802d43100403e2000f8c0ad08a20e02d10103e9600a05a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018";
          };
          config = {
            eDP1 = {
              enable = true;
              primary = true;
              crtc = 0;
              position = "1680x0";
              mode = "1920x1080";
              rate = "60.00";
            };
            DP3 = {
              enable = true;
              crtc = 1;
              position = "0x0";
              mode = "1680x1050";
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
