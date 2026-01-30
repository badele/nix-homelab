# Graphics
{ pkgs, ... }: {
  home.packages = with pkgs; [
    dust # Disk usage in rust
    duf # Disk usage in Go
    eza # ls alternative
    fd # find alternative
    ripgrep # Better grep
    unzip # Unzip files

    # Floating apps (used in i3)
    bashmount # Terminal mount helper
  ];
}
