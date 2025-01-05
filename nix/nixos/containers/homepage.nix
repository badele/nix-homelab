# Don't forget to add :
# - hostname entry on nix/nixos/features/commons/networking.nix
# - firewall rule hosts/hype16/default.nix
{ pkgs, containerHost, ... }: {
  nixunits = {
    homepage = {
      autoStart = true;

      network = {
        hostIp4 = "192.168.240.${containerHost}";
        ip4 = "192.168.241.${containerHost}";
        ip4route = "192.168.240.${containerHost}";
      };

      config = {

        environment.systemPackages = with pkgs; [ tcpdump dig ];

        services.homepage-dashboard = {
          enable = true;

          widgets = [
            {
              openmeteo = {
                label = "Montpellier";
                lattitude = 43.625;
                longitude = 3.862038;
                units = "metric";
                cache = 5;
              };
            }
            {
              resources = {
                cpu = true;
                disk = "/";
                memory = true;
              };
            }
            {
              search = {
                provider = "duckduckgo";
                target = "_blank";
              };
            }
            {
              traefik = {
                type = "traefik";
                icon = "traefik.svg";
                href = "https://traefik.adele.im/dashboard";
                url = "https://traefik.adele.im/api/overview";
              };
            }
          ];

          services = [
            {
              "My First Group" = [

                {
                  adguard = {
                    icon = "adguard.svg";
                    href = "https://adguard.adele.im";
                    ping = "https://adguard.adele.im";
                    widget = {
                      type = "adguard";
                      fields = [ "queries" "blocked" "filtered" "latency" ];
                      url = "https://adguard.adele.im";
                    };
                  };
                }

                {
                  "My First Service" = {
                    description = "Homepage is awesome";
                    href = "http://localhost/";
                  };
                }
              ];
            }
            {
              "My Second Group" = [{
                "My Second Service" = {
                  description = "Homepage is the best";
                  href = "http://localhost/";
                };
              }];
            }

          ];

          bookmarks = [
            {
              Developer = [{
                Github = [{
                  icon = "github.svg";
                  href = "https://github.com/";
                }];
              }];
            }
            {
              Entertainment = [{
                YouTube = [{
                  icon = "youtube.svg";
                  href = "https://youtube.com/";
                  description = "Youtube";
                }];
              }];
            }
          ];
        };
      };
    };
  };
}
