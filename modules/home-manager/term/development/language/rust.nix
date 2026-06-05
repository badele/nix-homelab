{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rust
    rust-analyzer
    rustc
    rustfmt
  ];
}
