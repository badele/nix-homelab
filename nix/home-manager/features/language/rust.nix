{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rustfmt
    rust-analyzer
  ];
}
