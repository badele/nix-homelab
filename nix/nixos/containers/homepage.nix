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

          settings = {
            background = "https://w.wallhaven.cc/full/0w/wallhaven-0w3pdr.jpg";
            backgroundOpacity = "0.2";
            cardBlur = "sm";
          };

          widgets = [
            {
              openmeteo = {
                label = "Montpellier";
                latitude = 43.625;
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
                provider = "google";
                focus = true;
                showSearchSuggestions = true;
                target = "_self";
              };
            }
          ];

          services = [
            {
              "Services" = [

                {
                  traefik = {
                    icon = "traefik";
                    href = "https://traefik.adele.im";
                    siteMonitor = "https://traefik.adele.im";
                    widget = {
                      type = "traefik";
                      fields = [ "routers" "services" "middleware" ];
                      url = "https://traefik.adele.im";
                    };
                  };
                }

                {
                  adguard = {
                    icon = "adguard-home";
                    href = "https://adguard.adele.im";
                    siteMonitor = "https://adguard.adele.im";
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
