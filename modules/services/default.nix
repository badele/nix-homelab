{ pkgs
, lib
, config
, ...
}:
{
  imports = [
    ./coredns.nix
    ./nfs.nix
    ./nix-serve.nix
  ];
}

