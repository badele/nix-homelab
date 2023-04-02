{ pkgs, lib, inputs, ... }:
{
  programs.google-chrome = {
    enable = true;
  };

  # home.persistence = {
  #   "/persist/user/${config.home.username}".directories = [ ".config/google-chrome" ];
  # };
}
