{ lib, config, ... }: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "/home/badele/.ssh/devpod" ];
  };

  # home.persistence = {
  #   "/persist/user/${config.home.username}".directories = [ ".ssh" ];
  # };
}
