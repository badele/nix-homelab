{ config, lib, ... }:
{
  terraform.required_providers.tls.source = "hashicorp/tls";
  terraform.required_providers.hcloud.source = "hetznercloud/hcloud";

  resource.tls_private_key.ssh_deploy_key = {
    algorithm = "ED25519";
  };

  resource.local_sensitive_file.ssh_deploy_key = {
    filename = "${lib.tf.ref "path.module"}/.terraform-deploy-key";
    file_permission = "600";
    content = config.resource.tls_private_key.ssh_deploy_key "private_key_openssh";
  };

  resource.hcloud_ssh_key."badele" = {
    name = "badele";
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDsXvfr+qp9EtSfsNtLfp0mfrr/TMUk48RGjqRFXJEJwkpE2BDhjnBIjz/ijdNRfnwUQFE589y4L+eyG1SpJ5XD1Ia3lRPPK2ofA64h/tueS6HPBxcuQJtbZpZlcYqHFaXVxULIYqgF3VASqsZdUMMn55HfZzb1snUPgBNvsrFiuiVgIQZsrxxwtlBz+yh7cjRoyMC0QT/DPZELT29+QnSIC4CgRj9yiYZSgBxvxrWwLJvIxx87wN8xAo4dZQCIuVy55WcNd3VVW/cOVImpQKQw0NpyshUsBCHrPddNF0IU9kUBeBtVmWypYCOFi2zfaoa3aRjgkkpBmh1BCUN6XJxKb1Mde+wYzGHswTkiiHOv1iEmFjDgOmrr+Ad72Kd3J4+8ecuKqeN7TUopiLhcqwZSKIow5R1+xfxOI0K5JmPVNomurI8F0UOSgTHvz2hRREoBJ4pXFlhqYpv4J80IZpuJLhixWgm3ZUa8+CvAlaMCYOsrpFtB2d0uITOe540T4f9l1ngVVtj3FA8T/TXKY8gdHrxbj0C0whNT+yHKtaWHjXBEBgIfhjTvLGlo3F4RWr+Cko/zY9GSd7ACmT/nbQKSYwN77kqSMoeDVa3KFfCT1XCFBBvb9CrviFx+anb1nEeqAXYqWP0a3nqv1Vlvxn5QSPFCdFxex7K2kFObaniJiQ== cardno:18_150_451";
  };

  resource.hcloud_ssh_key."clan-homelab" = {
    name = "clan-homelab";
    public_key = config.resource.tls_private_key.ssh_deploy_key "public_key_openssh";
  };
}
