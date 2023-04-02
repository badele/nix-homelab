{ pkgs, ... }:
let
  pythonEnv = pkgs.python310.withPackages (p: with p; [
    pip
    requests
  ]);
in
{
  home.packages =
    [
      pythonEnv
    ];
}
