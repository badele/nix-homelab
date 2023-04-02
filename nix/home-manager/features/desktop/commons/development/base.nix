{ config
, pkgs
, ...
}: {

  home.packages = with pkgs; [
    meld # Visual diff and merge tool
  ];
}
