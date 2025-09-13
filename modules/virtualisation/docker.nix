{ config, pkgs, ... }: {
  virtualisation = {
    docker = {
      enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    oci-containers.backend = "docker";

    containers.registries.search = [ "docker.io" "ghcr.io" "lscr.io" ];

    # Virtual machines
    libvirtd.enable = true;
  };

  networking.firewall = {
    interfaces.containers = { allowedUDPPorts = [ 53 ]; };
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
        ${pkgs.docker}/bin/${backend} network inspect containers-lan >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/${backend} network create containers-lan

        # adm
        ${pkgs.docker}/bin/${backend} network inspect containers-adm >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/${backend} network create containers-adm

        # dmz
        ${pkgs.docker}/bin/${backend} network inspect containers-dmz >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/${backend} network create containers-dmz
      '';
    };
}
