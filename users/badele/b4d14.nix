# #########################################################
# HOME-MANAGER (user)
##########################################################
{ config, inputs, pkgs, lib, ... }:
let
  feh = "${pkgs.feh}/bin/feh";
  theme = "${pkgs.base16-schemes}/share/themes/catppuccin-latte.yaml";
  wallpaper = pkgs.runCommand "image.png" { } ''
    COLOR=$(${pkgs.yq}/bin/yq -r .base00 ${theme})
    COLOR="#"$COLOR
    ${pkgs.imagemagick}/bin/magick convert -size 1920x1080 xc:$COLOR $out
  '';
in {
  imports = [
    # homelab Modules
    ../../nix/modules/home-manager/font.nix
    ../../nix/modules/home-manager/userconf.nix

    # Common tools and packages for all badele user hosts
    ../badele/commons.nix

    # Editor
    # INFO: I use my independant neovim configuration => https://github.com/badele/vides
    # ../../nix/home-manager/features/term/editor/lazyvim.nix

    # Term
    ../../nix/home-manager/features/term/base.nix
    ../../nix/home-manager/features/term/security

    # Language
    ../../nix/home-manager/apps/cloud/aws.nix
    ../../nix/home-manager/features/language/all.nix

    # Desktop
    ../../nix/home-manager/features/desktop/apps/base.nix
    ../../nix/home-manager/features/desktop/xorg/base.nix
    ../../nix/home-manager/features/desktop/xorg/wm/i3.nix

    # Web browser
    ../../nix/home-manager/features/desktop/apps/google-chrome.nix
    ../../users/badele/firefox.nix

    # Multimedia
    ../../nix/home-manager/features/desktop/apps/spotify.nix

    # Development
    ../../nix/home-manager/features/desktop/apps/development/vscode.nix

    # Virtualisation
    ../../nix/home-manager/features/desktop/xorg/virtualisation.nix
  ];

  ###############################################################################
  # Packages
  ###############################################################################
  home.packages = with pkgs; [
    # Communication
    slack

    # VPN
    wireguard-tools
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
            eDP-1 =
              "00ffffffffffff0030e4b30600000000001f0104a522157806a205a65449a2250e505400000001010101010101010101010101010101283c80a070b023403020360050d21000001a203080a070b023403020360050d21000001a000000fe00344457564a813135365755310a0000000000024131b2001100000a010a202000ad";
            DP-2 =
              "00ffffffffffff0010acd3a14249343229210104a53b21783be755a9544aa1260d5054a54b00714f8180a9c0d1c00101010101010101565e00a0a0a029503020350055502100001a000000ff00443451334844330a2020202020000000fc0044454c4c20533237323244430a000000fd00304b72723c010a202020202020010c020325f14f101f051404131211030216150706012309070783010000681a00000101304b007e3900a080381f4030203a0055502100001a023a801871382d40582c450055502100001ed97600a0a0a034503020350055502100001a00000000000000000000000000000000000000000000000000000000000000000000000092";
          };
          config = {
            eDP-1 = {
              enable = true;
              primary = true;
              crtc = 0;
              position = "320x1440";
              mode = "1920x1200";
              rate = "60.00";
            };
            DP-2 = {
              enable = true;
              crtc = 1;
              position = "0x0";
              mode = "2560x1440";
              rate = "60.00";
            };
          };
          hooks.postswitch = ''
            ${pkgs.i3}/bin/i3-msg restart
            ${feh} --bg-scale '${config.stylix.image}'
          '';
        };
      };
    };
  };

  # You can preview the palette at ~/.config/stylix/palette.html
  stylix.enable = true;
  stylix.autoEnable = true;

  stylix.base16Scheme =
    "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/0w/wallhaven-0w3pdr.jpg";
    sha256 = "sha256-xrLfcRkr6TjTW464GYf9XNFHRe5HlLtjpB0LQAh/l6M=";
  };

  # Disable neovim, it managed by https://github.com/badele/vide
  stylix.targets.neovim.enable = false;

  stylix.fonts = {
    serif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Serif";
    };

    sansSerif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans";
    };

    monospace = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans Mono";
    };

    emoji = {
      package = pkgs.noto-fonts-emoji;
      name = "Noto Color Emoji";
    };
  };
}
