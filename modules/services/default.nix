{ pkgs
, lib
, config
, ...
}:
{
  imports = [
    ./coredns.nix
    ./grafana
    ./loki
    ./prometheus
    ./nfs.nix
    ./nix-serve.nix
  ];
}

