{ self, clan, ... }:
{
  imports = [
    # Install server profile
    # see ./modules/flake-module.nix
    self.nixosModules.server

    self.nixosModules.houston

    # Default shared configuration for the clan machines.
    ../../modules/disko.nix
    ../../modules/commons-installation
    ../../modules/server.nix

    # houston specific configuration
    ./modules/kanidm.nix
    ./modules/miniflux.nix
  ];

  # This is your user login name.
  # users.users.user.name = "badele";

  # Set this for clan commands use ssh i.e. `clan machines update`
  # If you change the hostname, you need to update this line to root@<new-hostname>
  # This only works however if you have avahi running on your admin machine else use IP
  clan.core.networking.targetHost = "root@91.99.130.127";

  # You can get your disk id by running the following command on the installer:
  # Replace <IP> with the IP of the installer printed on the screen or by running the `ip addr` command.
  # lsblk --output NAME,ID-LINK,FSTYPE,SIZE,MOUNTPOINT
  disko.devices.disk.main.device = "/dev/sda";

  # # Zerotier needs one controller to accept new nodes. Once accepted
  # # the controller can be offline and routing still works.
  # clan.core.networking.zerotier.controller.enable = true;
  nixpkgs.hostPlatform = "x86_64-linux";
}
