{ self, pkgs, ... }:
let
  inxi_recommenced = pkgs.inxi.override {
    withRecommendedSystemPrograms = true;
  };
in
{
  home.packages = with pkgs; [
    # Hardware
    inxi_recommenced # inxi -b

    # xorg
    mesa-demos # glxinfo, glxgears
    # Performance
    atop # Top alternative
    btop # Top alternative
    htop # Top alternative
    procs # Top alternative

    # Trace system calls and signals
    lurk
    ltrace
    strace

  ];
}
