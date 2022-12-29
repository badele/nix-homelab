# Nix-serve

A standalone Nix binary cache server.

`nix-serve` is a small utility to serve a Nix store as a binary cache, allowing it to be used as a substituter by other Nix installations.

## Installation

Add `nix-serve` on host service section from `homelab.json` file

```
inv init.nix-serve --hostnames <hostname>
inv nix.deploy --hostnames <hostname>
```

## Utilization

Edit `flake.nix` file

```
  nixConfig = {
    extra-substituers = [
      "http://bootstore.h:5000"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys =
      [
        "bootstore.h:+2EnxpRxBCNd5V/2PNoobcq7fW+oXpZ0IhRwL+X2WHI="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
  };
```
