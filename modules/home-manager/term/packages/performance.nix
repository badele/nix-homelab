{ self, pkgs, ... }:
{
  home.packages = with pkgs; [
    atop # Top alternative
    btop # Top alternative
    htop # Top alternative
    procs # Top alternative
  ];
}
