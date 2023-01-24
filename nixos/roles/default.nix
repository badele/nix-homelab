{ pkgs
, lib
, config
, ...
}:
{
  imports = [
    ./coredns.nix
    ./dashy.nix
    ./grafana
    ./loki/loki.nix
    ./loki/promtail.nix
    ./prometheus
    ./nfs.nix
    ./nix-serve.nix
    ./ntp.nix
    ./smokeping.nix
    ./statping.nix
    ./uptime.nix
  ];
}

