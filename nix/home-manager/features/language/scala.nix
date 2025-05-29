{ pkgs, ... }: { home.packages = with pkgs; [ sbt metals ]; }

