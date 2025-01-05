{ ... }: {
  imports = [
    ./disk.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./packages.nix
    ./security.nix
    ./sops.nix
    ./sshd.nix
    ./zfs.nix
  ];

  programs = { zsh.enable = true; };
}
