{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    docker.enable = lib.mkForce false;

    oci-containers.backend = "podman";
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = false;
    };
  };

  # Useful other development tools
  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    docker-compose # start group of containers for dev
    podman-compose # start group of containers for dev
  ];
}
