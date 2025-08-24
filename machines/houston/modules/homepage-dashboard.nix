{
  config,
  ...
}:
let
  domain = "${config.networking.fqdn}";
  appDomain = "home.${domain}";
  listenPort = 10001;
in
{
  imports = [ ../../../modules/system/acme.nix ];

  # Icons :
  # - https://selfh.st/icons/ (sh-xx)
  # - https://simpleicons.org/ (si-xx)
  # - https://pictogrammers.com/library/mdi/ (mdi-xx)
  # - https://github.com/homarr-labs/dashboard-icons
  services.homepage-dashboard = {
    enable = true;
    listenPort = listenPort;
    allowedHosts = "${appDomain}";

    # HOMEPAGE_ALLOWED_HOSTS
    # settings = {
    #   background = "https://w.wallhaven.cc/full/0w/wallhaven-0w3pdr.jpg";
    #   backgroundOpacity = "0.2";
    #   cardBlur = "sm";
    # };

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
    ];

    bookmarks = [
      {
        "Public apps" = [
          {
            "shared bookmark" = [
              {
                icon = "sh-linkding";
                href = "https://links.ma-cabane.eu/bookmarks/shared";
                description = "Shared bookmarks";
              }
            ];
          }

          {
            goaccess = [
              {
                icon = "sh-goaccess";
                href = "https://stats.ma-cabane.eu";
                description = "Website log stats";
              }
            ];
          }

        ];
      }

      {
        "Apps with authentification" = [

          {
            miniflux = [
              {
                icon = "sh-miniflux";
                href = "https://rss.ma-cabane.eu";
                description = "RSS Reader";
              }
            ];
          }

          {
            linkding = [
              {
                abbr = "bm";
                icon = "sh-linkding";
                href = "https://links.ma-cabane.eu";
                description = "Bookmark manager";
              }
            ];
          }
        ];
      }

      {
        "Homelab use" = [

          {
            authelia = [
              {
                icon = "sh-authelia";
                href = "https://www.authelia.com/";
                description = "Athentication and authorization server";
              }
            ];
          }

          {
            borgbackup = [
              {
                icon = "sh-borg";
                href = "https://www.borgbackup.org/";
                description = "Deduplicating archiver(backup)";
              }
            ];
          }

          {
            clan = [
              {
                icon = "sh-nixos";
                href = "https://clan.lol/";
                description = "Kill the cloud, build your own darknet ♥️";
              }
            ];
          }

          {
            goaccess = [
              {
                icon = "sh-goaccess";
                href = "https://goaccess.io/";
                description = "Real-time web log analyzer";
              }
            ];
          }
          {
            hetzner = [
              {
                icon = "sh-hetzner";
                href = "https://www.hetzner.com/";
                description = "German low-cost provider";
              }
            ];
          }
          {
            linkding = [
              {
                icon = "sh-linkding";
                href = "https://linkding.link/";
                description = "Bookmark manager designed to be minimal, fast";
              }
            ];
          }

          {
            miniflux = [
              {
                icon = "sh-miniflux";
                href = "https://miniflux.app/";
                description = "Minimalist and opinionated feed reader.";
              }
            ];
          }

          {
            nixos = [
              {
                icon = "sh-nixos";
                href = "https://nixos.org/";
                description = "Declarative Linux distribution ♥️";
              }
            ];
          }

          {
            opentofu = [
              {
                icon = "sh-opentofu";
                href = "https://opentofu.org/";
                description = "Infrastructure as Code";
              }
            ];
          }

          {
            postgresql = [
              {
                icon = "sh-postgresql";
                href = "https://www.postgresql.org/";
                description = "The World's Most Advanced Relational Database";
              }
            ];
          }

          {
            zerotier = [
              {
                icon = "sh-zerotier";
                href = "https://zerotier.com/";
                description = "Global Networking Solution for IoT, SD-WAN, and VPN";
              }
            ];
          }
        ];
      }

      {
        "My other stufs" = [
          {
            blog = [
              {
                icon = "sh-hugo";
                href = "https://blog.jesuislibre.org";
                description = "My blog";
              }
            ];
          }

          {
            devops = [
              {
                icon = "sh-mkdocs";
                href = "https://devops.jesuislibre.org/";
                description = "My DevOps docs";
              }
            ];
          }

          {
            github = [
              {
                icon = "sh-github";
                href = "https://github.com/badele";
                description = "My contributions";
              }
            ];
          }

          {
            cv = [
              {
                icon = "sh-adobe-acrobat";
                href = "https://badele.github.io/cv/";
                description = "My curriculum vitae";
              }
            ];
          }
        ];
      }

    ];
  };

  services.nginx.virtualHosts."${appDomain}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString listenPort}";
      recommendedProxySettings = true;
      proxyWebsockets = true;
    };
    extraConfig = ''access_log /var/log/nginx/public.log vcombined;'';
  };

  networking.firewall.allowedTCPPorts = [
    443
  ];
}
