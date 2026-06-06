{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rust-analyzer
    rustc
    rustfmt
  ];
}
