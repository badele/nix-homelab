{ ... }:
{
  imports = [
    ./homelab.nix
    ./lib.nix
    ./networks.nix
    ./hosts.nix
    ./hostprofile.nix
  ];
}
