##########################################################
# HOME-MANAGER (user)
##########################################################
{ config
, inputs
, pkgs
, lib
, ...
}:
{
  imports = [
    # Modules
    ../../nix/modules/home-manager/font.nix
    ../../nix/modules/home-manager/userconf.nix
    ../../nix/modules/home-manager/wallpaper.nix

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
    # ../../nix/home-manager/features/language/c.nix
    # ../../nix/home-manager/features/language/go.nix
    # ../../nix/home-manager/features/language/python.nix
    #
    # Desktop
    ../../nix/home-manager/features/desktop/commons/base.nix
    ../../nix/home-manager/features/desktop/xorg/base.nix
    ../../nix/home-manager/features/desktop/xorg/wm/i3.nix

    #   # Web browser
    ../../nix/home-manager/features/desktop/commons/google-chrome.nix

    #   # Multimedia
    ../../nix/home-manager/features/desktop/commons/spotify.nix

    #   # Development term
    ../../nix/home-manager/features/term/development/base.nix

    #   # Development desktop
    ../../nix/home-manager/features/desktop/commons/development/packages.nix
    # ../../nix/home-manager/features/desktop/commons/development/vscode.nix

    #   # Virtualisation
    # ../../nix/home-manager/features/desktop/xorg/virtualisation.nix
  ];


  ###############################################################################
  # Packages
  ###############################################################################
  home.packages = with pkgs; [
    # Insert your packages here
  ];

  stylix.autoEnable = false;
  # stylix.targets.gtk.enable = true;
  # stylix.targets.gnome.enable = true;
  # stylix.targets.vscode.enable = true;
  stylix.targets.i3.enable = true;
  stylix.targets.yazi.enable = true;
  stylix.image = pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/0w/wallhaven-0w3pdr.jpg";
    sha256 = "sha256-xrLfcRkr6TjTW464GYf9XNFHRe5HlLtjpB0LQAh/l6M=";
  };
}
