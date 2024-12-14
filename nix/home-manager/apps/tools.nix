# Graphics
{ pkgs, ... }: {
  home.packages = with pkgs; [
    dconf # Dconf editor

    bat # cat alternative
    eva # Calculator
    tmux # Terminal multiplexer
    up # UI interactively pipe
  ];
}
