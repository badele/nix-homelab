# Don't forget to add :
# - hostname entry on nix/nixos/features/commons/networking.nix
# - firewall rule hosts/hype16/default.nix
{ pkgs, containerIpSuffix, ... }: {
  nixunits = {
    homepage = {
      autoStart = true;

      network = {
        hostIp4 = "192.168.240.${containerIpSuffix}";
        ip4 = "192.168.241.${containerIpSuffix}";
        ip4route = "192.168.240.${containerIpSuffix}";
      };

      config = {

        # environment.systemPackages = with pkgs; [ ];

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
              Entertainment = [
                {
                  YouTube = [{
                    icon = "youtube";
                    href = "https://youtube.com/";
                    description = "Youtube";
                  }];
                }

                {
                  Note = [{
                    icon = "mdi-note-text";
                    href = "https://note.adele.im/";
                    description = "Trilium note";
                  }];
                }
              ];
            }
          ];
        };
      };
    };
  };
}
