{ pkgs, ... }:
let pythonEnv = pkgs.python313.withPackages (p: with p; [ pip requests ]);
in { home.packages = [ pythonEnv ]; }
