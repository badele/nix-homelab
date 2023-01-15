{ pkgs
, lib
, config
, ...
}:
{
  imports = [
    ./coredns.nix
    ./grafana
    ./loki/loki.nix
    ./loki/promtail.nix
    ./prometheus
    ./nfs.nix
    ./nix-serve.nix
    ./ntp.nix
    ./smokeping.nix
  ];
}

