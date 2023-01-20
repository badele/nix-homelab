{ ... }:
{
  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker = {
    storageDriver = "zfs";
  };
}
