{ pkgs, ... }:
{
  networking.nftables.enable = true;

  networking.firewall.interfaces.incusbr0.allowedTCPPorts = [
    53
    67
  ];
  networking.firewall.interfaces.incusbr0.allowedUDPPorts = [
    53
    67
  ];


  environment.systemPackages = with pkgs; [
    distrobuilder
  ];

  virtualisation.incus = {
    enable = true;
    ui.enable = true;
    # preseed = {
    #   networks = [
    #     {
    #       config = {
    #         "ipv4.address" = "10.0.100.1/24";
    #         "ipv4.nat" = "true";
    #       };
    #       name = "incusbr0";
    #       type = "bridge";
    #     }
    #   ];
    #   profiles = [
    #     {
    #       devices = {
    #         eth0 = {
    #           name = "eth0";
    #           network = "incusbr0";
    #           type = "nic";
    #         };
    #         root = {
    #           path = "/";
    #           pool = "default";
    #           size = "35GiB";
    #           type = "disk";
    #         };
    #       };
    #       name = "default";
    #     }
    #   ];
    #   storage_pools = [
    #     {
    #       config = {
    #         source = "/var/lib/incus/storage-pools/default";
    #       };
    #       driver = "dir";
    #       name = "default";
    #     }
    #   ];
    # };
  };
}
