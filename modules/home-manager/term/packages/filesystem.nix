{ self, pkgs, ... }:
{
  home.packages = with pkgs; [
    bashmount # Terminal mount helper
    du-dust # Disk usage in rust
    duf # Disk usage in Go
    eza # ls alternative
    fd # find alternative
    ripgrep # Better grep
    unzip # Unzip files
  ];
}
