{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # Hadware informations
    hardinfo2 # System information tool
    cpufetch # get CPU information

    # Performance
    atop # Top alternative
    btop # Top alternative
    htop # Top alternative
    procs # Top alternative
    lurk # strace alternative with better UI and more features
    ltrace # Trace library calls
    strace # Trace system calls and signals

    hl-log-viewer # JSON and logfmt viewer
  ];
}
