# Don't forget to add :
# - hostname entry on nix/nixos/features/commons/networking.nix
# - firewall rule hosts/hype16/default.nix
{ pkgs, containerIpSuffix, ... }: {
  nixunits = {
    trilium = {
      autoStart = true;

      network = {
        hostIp4 = "192.168.240.${containerIpSuffix}";
        ip4 = "192.168.241.${containerIpSuffix}";
        ip4route = "192.168.240.${containerIpSuffix}";
      };

      config = {

        environment.systemPackages = with pkgs; [ tcpdump dig ];

        services = {
          trilium-server = {
            enable = true;
            host = "0.0.0.0";
            port = 8080;
          };
        };

      };
    };
  };
}
