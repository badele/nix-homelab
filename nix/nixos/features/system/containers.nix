{ ... }:
{
  # Create /data/docker folder
  systemd.tmpfiles.rules = [
    "d /data/docker 0750 root root -"
  ];

  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    storageDriver = "zfs";

    rootless = {
      enable = false;
      # setSocketVariable = true;
    };

    daemon.settings = {
      experimental = true;
    };
  };
}
