{ config
, pkgs
, ...
}: {

  home.packages = with pkgs; [
    just # justfile (Makefile like)
    meld # Visual diff and merge tool
  ];
}
