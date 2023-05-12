{ ...
}:
{
  imports = [
    ./fuse.nix
    ./locale.nix
    ./nix.nix
    ./security.nix
    ./sops.nix
    ./sshd.nix
    ./zfs.nix
    ./networking.nix
  ];

  programs = {
    zsh.enable = true;
  };
}
