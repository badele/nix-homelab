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
    # Modules
    ../../nix/modules/home-manager/font.nix
    ../../nix/modules/home-manager/userconf.nix

    # Common tools and packages for all demovm user hosts
    ./commons.nix

    # Editor
    # INFO: I use my independant neovim configuration => https://github.com/badele/vides
    # ../../nix/home-manager/features/term/editor/lazyvim.nix

    # Term
    ../../nix/home-manager/features/term/base.nix
    ../../nix/home-manager/features/term/security

    # Desktop
    ../../nix/home-manager/features/desktop/apps/base.nix
    ../../nix/home-manager/features/desktop/xorg/base.nix
    ../../nix/home-manager/features/desktop/xorg/wm/i3.nix

    #   # Web browser
    ../../nix/home-manager/features/desktop/apps/google-chrome.nix

    #   # Multimedia
    ../../nix/home-manager/features/desktop/apps/spotify.nix

    #   # Development term
    ../../nix/home-manager/features/desktop/apps/development/vscode.nix
  ];

  ###############################################################################
  # Packages
  ###############################################################################
  home.packages = with pkgs;
    [
      # Insert your packages here
    ];

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
      package = pkgs.noto-fonts-color-emoji;
      name = "Noto Color Emoji";
    };
  };
}
