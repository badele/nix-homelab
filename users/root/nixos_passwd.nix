##########################################################
# NIXOS
##########################################################
{ pkgs
, config
, lib
, ...
}:
{
  sops.secrets.root-password-hash.neededForUsers = true;

  users.users = {
    # Root
    root = {
      shell = pkgs.zsh;
      passwordFile = config.sops.secrets.root-password-hash.path;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDsXvfr+qp9EtSfsNtLfp0mfrr/TMUk48RGjqRFXJEJwkpE2BDhjnBIjz/ijdNRfnwUQFE589y4L+eyG1SpJ5XD1Ia3lRPPK2ofA64h/tueS6HPBxcuQJtbZpZlcYqHFaXVxULIYqgF3VASqsZdUMMn55HfZzb1snUPgBNvsrFiuiVgIQZsrxxwtlBz+yh7cjRoyMC0QT/DPZELT29+QnSIC4CgRj9yiYZSgBxvxrWwLJvIxx87wN8xAo4dZQCIuVy55WcNd3VVW/cOVImpQKQw0NpyshUsBCHrPddNF0IU9kUBeBtVmWypYCOFi2zfaoa3aRjgkkpBmh1BCUN6XJxKb1Mde+wYzGHswTkiiHOv1iEmFjDgOmrr+Ad72Kd3J4+8ecuKqeN7TUopiLhcqwZSKIow5R1+xfxOI0K5JmPVNomurI8F0UOSgTHvz2hRREoBJ4pXFlhqYpv4J80IZpuJLhixWgm3ZUa8+CvAlaMCYOsrpFtB2d0uITOe540T4f9l1ngVVtj3FA8T/TXKY8gdHrxbj0C0whNT+yHKtaWHjXBEBgIfhjTvLGlo3F4RWr+Cko/zY9GSd7ACmT/nbQKSYwN77kqSMoeDVa3KFfCT1XCFBBvb9CrviFx+anb1nEeqAXYqWP0a3nqv1Vlvxn5QSPFCdFxex7K2kFObaniJiQ== badele@gpg"
      ];
    };
  };

  # needed so that we can set a root password
  users.mutableUsers = false;
  nix.settings.trusted-users = [ "badele" ];

  security.sudo.wheelNeedsPassword = false;
}
