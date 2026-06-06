{ pkgs, ... }:
{
  home.packages = with pkgs; [
    libxml2 # xmllint
  ];
}
