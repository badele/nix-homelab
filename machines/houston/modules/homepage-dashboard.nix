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
  imports = [ ../../../modules/acme.nix ];

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
        ];
      }

      {
        "Public apps(auth)" = [

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
                icon = "sh-linkding";
                href = "https://links.ma-cabane.eu";
                description = "Bookmark manager";
              }
            ];
          }
        ];
      }

      {
        "Infrastructure" = [
          {
            goaccess = [
              {
                icon = "sh-goaccess";
                href = "https://stats.ma-cabane.eu";
                description = "Website log stats";
              }
            ];
          }

          {
            authelia = [
              {
                icon = "sh-authelia";
                href = "https://auth.ma-cabane.eu/";
                description = "Identity manager";
              }
            ];
          }

          {
            zerotier = [
              {
                icon = "sh-zerotier";
                href = "https://zerotier.com/";
                description = "VPN Network";
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
