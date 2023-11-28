{ config
, pkgs
, ...
}: {

  home.packages = with pkgs; [
    deno # javascript engine
    just # justfile (Makefile like)
    meld # Visual diff and merge tool
  ];
}
