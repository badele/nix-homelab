{ pkgs
, ...
}: {
  imports = [
    ./domain.nix
    ./hosts.nix
    ./networks.nix
  ];
}
