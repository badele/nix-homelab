# ###########################################################################
# HOME-MANAGER (user)
# ###########################################################################
{ ... }: {
  imports = [
    # homelab Modules
    ../../nix/modules/home-manager/font.nix
    ../../nix/modules/home-manager/userconf.nix

    # User
    ./commons.nix

    # Tool packages
    ../../nix/home-manager/apps/system/file.nix
    ../../nix/home-manager/apps/tools.nix

    # Term
    ../../nix/home-manager/features/term/base.nix
    ../../nix/home-manager/features/term/security
  ];

  # ###########################################################################
  # Packages
  # ###########################################################################
  home.packages = [ ];
  programs = { };
}
