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

    settings = {
      title = "Ma Cabane";
      description = "Bienvenue dans ma cabane, trouvez l'ensemble de mes services web.";
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
    ];

    bookmarks = [
      {
        "Applications publiques" = [
          {
            "Radio" = [
              {
                icon = "si-overcast";
                href = "https://radio.ma-cabane.eu/";
                description = "Flux radios";
              }
            ];
          }

          {
            "Notes" = [
              {
                icon = "sh-wiki-js";
                href = "https://notes.ma-cabane.eu/";
                description = "Partage de notes (wiki-js)";
              }
            ];
          }

          {
            Megaphone = [
              {
                icon = "sh-shaarli";
                href = "https://megaphone.ma-cabane.eu/";
                description = "Partage de liens (Shaarli)";
              }
            ];
          }

          {
            "Marque pages" = [
              {
                icon = "sh-linkding";
                href = "https://links.ma-cabane.eu/bookmarks/shared";
                description = "Mes liens (linkding)";
              }
            ];
          }

          {
            "codes" = [
              {
                icon = "sh-wastebin";
                href = "https://codes.ma-cabane.eu";
                description = "Mes codes copié/collé";
              }
            ];
          }

          {
            "Les visites" = [
              {
                icon = "sh-goaccess";
                href = "https://stats.ma-cabane.eu";
                description = "Website log stats (goaccess)";
              }
            ];
          }

        ];
      }

      {
        "Applications avec authentifications" = [
          {
            "Radio" = [
              {
                icon = "si-overcast";
                href = "https://radio.ma-cabane.eu/panel";
                description = "radios (admin)";
              }
            ];
          }

          {
            Notes = [
              {
                icon = "sh-wiki-js";
                href = "https://notes.ma-cabane.eu/login";
                description = "wiki-js (sso)";
              }
            ];
          }

          {
            "Megaphone" = [
              {
                icon = "sh-shaarli";
                href = "https://megaphone.ma-cabane.eu/login";
                description = "Shaarli (admin)";
              }
            ];
          }

          {
            "Nouvelle" = [
              {
                icon = "sh-miniflux";
                href = "https://rss.ma-cabane.eu";
                description = "miniflux (sso)";
              }
            ];
          }

          {
            "Marque pages" = [
              {
                abbr = "bm";
                icon = "sh-linkding";
                href = "https://links.ma-cabane.eu";
                description = "linkding (sso)";
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
            shaarli = [
              {
                icon = "sh-shaarli";
                href = "https://github.com/shaarli/Shaarli";
                description = "minimalist, super-fast, bookmarking service";
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
            pawtunes = [
              {
                icon = "mdi-paw";
                href = "https://github.com/Jackysi/PawTunes";
                description = "The Ultimate HTML5 Internet Radio Player";
              }
            ];
          }

          {
            wastebin = [
              {
                icon = "sh-wastebin";
                href = "https://github.com/matze/wastebin";
                description = "wastebin is a pastebin";
              }
            ];
          }

          {
            wiki-js = [
              {
                icon = "sh-wiki-js";
                href = "https://js.wiki/";
                description = "Most powerful and extensible open source Wiki";
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
