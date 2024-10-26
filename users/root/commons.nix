{ config, pkgs, lib, ... }: {
  ##############################################################################
  # User packages
  ##############################################################################
  home.packages = with pkgs; [
    # Makefile like
    just # justfile (Makefile like)
  ];
}
