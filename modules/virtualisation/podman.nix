{ config, pkgs, lib, ... }: {
  # Enable common container config files in /etc/containers
  virtualisation.containers.enable = true;
  virtualisation = {
    docker.enable = lib.mkForce false;

    oci-containers.backend = "podman";
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Create docker containers-network  (before launching container
  systemd.services.containers-networks =
    with config.virtualisation.oci-containers; {
      serviceConfig.Type = "oneshot";
      # wantedBy = [
      #   "${backend}-traefik.service"
      #   "${backend}-homepage.service"
      #   "${backend}-portainer.service"
      #   "${backend}-vaultwarden.service"
      #   "${backend}-syncthing.service"
      # ];
      script = ''
        # lan
        ${pkgs.podman}/bin/${backend} network inspect containers-lan >/dev/null 2>&1 || \
        ${pkgs.podman}/bin/${backend} network create containers-lan

        # adm
        ${pkgs.podman}/bin/${backend} network inspect containers-adm >/dev/null 2>&1 || \
        ${pkgs.podman}/bin/${backend} network create containers-adm

        # dmz
        ${pkgs.podman}/bin/${backend} network inspect containers-dmz >/dev/null 2>&1 || \
        ${pkgs.podman}/bin/${backend} network create containers-dmz
      '';
    };

  # Useful other development tools
  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    docker-compose # start group of containers for dev
    podman-compose # start group of containers for dev
  ];
}

