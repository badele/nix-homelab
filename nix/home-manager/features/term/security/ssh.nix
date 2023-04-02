{ lib, config, ... }:
{
  programs.ssh = {
    enable = true;
  };

  # home.persistence = {
  #   "/persist/user/${config.home.username}".directories = [ ".ssh" ];
  # };
}
