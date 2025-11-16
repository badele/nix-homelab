{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkServiceAliases,
  ...
}:
with lib;
with types;

let
  appName = "homepage-dashboard";
  appCategory = "System Health";
  appDisplayName = "Homepage";
  appPlatform = "nixos";
  appIcon = "homepage";
  appDescription = "${pkgs.${appName}.meta.description}";
  appUrl = pkgs.${appName}.meta.homepage;
  appPinnedVersion = pkgs.${appName}.version;

  cfg = config.homelab.features.${appName};

  listenHttpPort = config.homelab.portRegistry.${appName}.httpPort;

  # Service URL: use nginx domain if firewall is open, otherwise use direct IP:port
  serviceURL =
    if cfg.openFirewall then
      "https://${cfg.serviceDomain}"
    else
      "http://127.0.0.1:${toString listenHttpPort}";

  # Collect all features with homepage configuration
  featuresWithHomepage = lib.filterAttrs (
    name: feature: feature.enable or false && feature.homepage != null
  ) config.homelab.features;

  # Group services by category
  servicesByCategory = lib.foldl' (
    acc: featureName:
    let
      feature = config.homelab.features.${featureName};
      category = feature.appInfos.category;
      serviceEntry = {
        ${featureName} = feature.homepage;
      };
    in
    acc
    // {
      ${category} = (acc.${category} or [ ]) ++ [ serviceEntry ];
    }
  ) { } (builtins.attrNames featuresWithHomepage);

  # Convert to homepage-dashboard format: [ { "Category" = [ ... ]; } ]
  homepageServices = lib.mapAttrsToList (category: services: {
    ${category} = services;
  }) servicesByCategory;
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = mkEnableOption appName;

      serviceDomain = mkOption {
        type = str;
        default = "${appName}.${config.homelab.domain}";
        description = "${appName} service domain name";
      };

      openFirewall = mkEnableOption "Open firewall ports (incoming)";
    };
  };

  ############################################################################
  # Configuration
  ############################################################################
  config =
    with lib;
    mkMerge [
      {
        homelab.features.${appName} = {
          appInfos = {
            category = appCategory;
            displayName = appDisplayName;
            platform = appPlatform;
            icon = appIcon;
            description = appDescription;
            url = appUrl;
            pinnedVersion = appPinnedVersion;
            serviceURL = serviceURL;
          };
        };
      }

      # Only apply when enabled
      (mkIf cfg.enable {
        homelab.features.${appName} = {
          gatus = mkIf cfg.enable {
            name = appDisplayName;
            url = serviceURL;
            group = appCategory;
            type = "HTTP";
            interval = "5m";
            conditions = [
              "[STATUS] == 200"
              ''[BODY] == pat(*<title data-next-head="">*</title>*)''
            ];
          };
        };

        services.homepage-dashboard = {
          enable = true;
          listenPort = listenHttpPort;
          allowedHosts = "${cfg.serviceDomain}";

          settings = {
            title = "Ma Cabane";
            description = "Bienvenue dans ma cabane, trouvez l'ensemble de mes services web.";

            statusStyle = "dot";
            useEqualHeights = true;
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

          services = homepageServices;

          bookmarks = [
            {
              "Applications publiques" = [
                {
                  "Bonnes adresses" = [
                    {
                      icon = "sh-linkding";
                      href = "https://bonnes-adresses.ma-cabane.eu/bookmarks/shared";
                      description = "Mes liens (linkding)";
                    }
                  ];
                }

                {
                  Codes = [
                    {
                      icon = "sh-wastebin";
                      href = "https://codes.ma-cabane.eu";
                      description = "Mes codes copié/collé";
                    }
                  ];
                }

                {
                  Encyclopedie = [
                    {
                      icon = "sh-dokuwiki";
                      href = "https://encyclopedie.ma-cabane.eu/";
                      description = "Partage de notes (dokuwiki)";
                    }
                  ];
                }

                {
                  Lampiotes = [
                    {
                      icon = "sh-grafana";
                      href = "https://lampiotes.ma-cabane.eu";
                      description = "C'est vert ?";
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
                  Radio = [
                    {
                      icon = "si-overcast";
                      href = "https://radio.ma-cabane.eu/";
                      description = "Flux radios";
                    }
                  ];
                }

                {
                  "Visiteurs" = [
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
                  Douane = [
                    {
                      icon = "sh-authelia";
                      href = "https://douane.ma-cabane.eu";
                      description = "Authelia authentification (sso)";
                    }
                  ];
                }

                {
                  Encyclopedie = [
                    {
                      icon = "sh-dokuwiki";
                      href = "https://encyclopedie.ma-cabane.eu/login";
                      description = "dokuwiki (sso)";
                    }
                  ];
                }

                {
                  Journaliste = [
                    {
                      icon = "sh-miniflux";
                      href = "https://journaliste.ma-cabane.eu";
                      description = "Veille flux RSS (sso)";
                    }
                  ];
                }

                {
                  Megaphone = [
                    {
                      icon = "sh-shaarli";
                      href = "https://megaphone.ma-cabane.eu/login";
                      description = "Shaarli (admin)";
                    }
                  ];
                }

                {
                  Radio = [
                    {
                      icon = "si-overcast";
                      href = "https://radio.ma-cabane.eu/panel";
                      description = "radios (admin)";
                    }
                  ];
                }

                {
                  "Bonnes adresses" = [
                    {
                      abbr = "bm";
                      icon = "sh-linkding";
                      href = "https://bonnes-adresses.ma-cabane.eu";
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
                  dokuwiki = [
                    {
                      icon = "sh-dokuwiki";
                      href = "https://www.dokuwiki.org/dokuwiki";
                      description = "The Open Source Wiki Engine ";
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
                  grafana = [
                    {
                      icon = "sh-grafana";
                      href = "https://github.com/grafana/grafana";
                      description = "The open and composable observability";
                    }
                  ];
                }

                {
                  influxdb = [
                    {
                      icon = "sh-influxdb";
                      href = "https://github.com/influxdata/influxdb";
                      description = "Scalable datastore for metrics, events";
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
                  pawtunes = [
                    {
                      icon = "mdi-paw";
                      href = "https://github.com/Jackysi/PawTunes";
                      description = "The Ultimate HTML5 Internet Radio Player";
                    }
                  ];
                }

                {
                  reaction = [
                    {
                      icon = "sh-github";
                      href = "https://reaction.ppom.me/";
                      description = "Scan logs and take action";
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
                  telegrag = [
                    {
                      icon = "sh-telegraf";
                      href = "https://github.com/influxdata/telegraf";
                      description = "Agent for collecting, processing, aggregating";
                    }
                  ];
                }

                {
                  vector = [
                    {
                      icon = "sh-vector";
                      href = "https://github.com/vectordotdev/vector";
                      description = "A high-performance observability data pipeline";
                    }
                  ];
                }

                {
                  wastebin = [
                    {
                      icon = "sh-wastebin";
                      href = "https://github.com/matze/wastebin";
                      description = "Pastebin alternative";
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

        # Open firewall ports if openFirewall is enabled
        networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
          443
        ];

        # Add domain alias
        homelab.alias = [ "${cfg.serviceDomain}" ];

        # Add service alias
        # programs.bash.shellAliases = (mkServiceAliases appName) // {
        #   "@service-${appName}-config" =
        #     "cat $(systemctl cat ${appName} | grep ExecStart= | grep -oP '(?<=--config )\\S+')";
        # };

        # Enable blocky in TLS mode with nginx reverse proxy if openFirewall is enabled
        services.nginx.virtualHosts = mkIf cfg.openFirewall {
          "${cfg.serviceDomain}" = {

            forceSSL = true;
            enableACME = true;
            locations."/" = {
              proxyPass = "http://127.0.0.1:${toString listenHttpPort}";
              recommendedProxySettings = true;
              proxyWebsockets = true;
            };
            extraConfig = ''access_log /var/log/nginx/public.log vcombined;'';
          };
        };
      })
    ];
}
