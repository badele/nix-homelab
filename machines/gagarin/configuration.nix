{
  self,
  ...
}:
let
  targetHost = "root@192.168.254.137";
  deviceId = "wwn-0x5000000000000314";
in
{
  imports = [
    self.nixosModules.desktop

    # Default configuration for the clan machines.
    ../../modules/disko-encryption-laptop.nix
    ../../modules/commons-installation
  ];

  # This is your user login name.
  # users.users.user.name = "badele";

  # Set this for clan commands use ssh i.e. `clan machines update`
  # If you change the hostname, you need to update this line to root@<new-hostname>
  # This only works however if you have avahi running on your admin machine else use IP
  clan.core.networking.targetHost = "${targetHost}";

  # You can get your disk id by running the following command on the installer:
  # Replace <IP> with the IP of the installer printed on the screen or by running the `ip addr` command.
  # ssh root@<IP> lsblk --output NAME,ID-LINK,FSTYPE,SIZE,MOUNTPOINT
  disko.devices.disk.main.device = "/dev/disk/by-id/${deviceId}";

  # # Zerotier needs one controller to accept new nodes. Once accepted
  # # the controller can be offline and routing still works.
  # clan.core.networking.zerotier.controller.enable = true;
}
