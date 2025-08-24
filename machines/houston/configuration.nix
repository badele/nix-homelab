{
  self,
  ...
}:
{
  imports = [
    # Install server profile
    # see ./modules/flake-module.nix
    self.nixosModules.server
    self.inputs.srvos.nixosModules.mixins-nginx

    # Default shared configuration for the clan machines.
    ../../modules/disko.nix
    ../../modules/shared.nix

    ../../modules/server.nix
    ../../modules/system/borgbackup.nix

    # houston infra
    ./modules/authelia.nix

    # houston apps
    ./modules/goaccess.nix
    ./modules/homepage-dashboard.nix
    ./modules/linkding.nix
    ./modules/miniflux.nix
    ./modules/shaarli.nix
  ];

  # This is your user login name.
  # users.users.user.name = "badele";

  # Set this for clan commands use ssh i.e. `clan machines update`
  # If you change the hostname, you need to update this line to root@<new-hostname>
  # This only works however if you have avahi running on your admin machine else use IP
  clan.core.networking.targetHost = "root@houston.ma-cabane.eu";

  # You can get your disk id by running the following command on the installer:
  # Replace <IP> with the IP of the installer printed on the screen or by running the `ip addr` command.
  # lsblk --output NAME,ID-LINK,FSTYPE,SIZE,MOUNTPOINT
  disko.devices.disk.main.device = "/dev/sda";

  # # Zerotier needs one controller to accept new nodes. Once accepted
  # # the controller can be offline and routing still works.
  # clan.core.networking.zerotier.controller.enable = true;
  nixpkgs.hostPlatform = "x86_64-linux";
}
