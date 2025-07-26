{ lib, config, ... }: {
  programs.ssh = {
    enable = true;
    includes = [ "/home/badele/.ssh/devpod" ];
  };

  # home.persistence = {
  #   "/persist/user/${config.home.username}".directories = [ ".ssh" ];
  # };
}
