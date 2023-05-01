{ ... }:
{
  # Create /data/docker folder
  systemd.tmpfiles.rules = [
    "d /data/docker 0750 root root -"
  ];

  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";

    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
