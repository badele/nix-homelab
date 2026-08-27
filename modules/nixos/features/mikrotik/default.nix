{
  config,
  lib,
  pkgs,
  mkFeatureOptions,
  mkGrafanaDashboardProvider,
  mkServiceAliases,
  resolveListenInterfaceAddresses,
  ...
}:
with lib;
with types;

let
  appName = "mikrotik";
  appCategory = "Core Services";
  appDisplayName = "MikroTik";
  appIcon = "mikrotik";
  appPlatform = "nixos";
  appDescription = "MikroTik RouterOS management helpers";
  appUrl = "https://mikrotik.com/";
  appPinnedVersion = pkgs.mktxp.version;
  serviceName = "mikrotik-backup";
  prometheusAliasName = "mikrotik-exporter";
  prometheusServiceName = "mikrotik-mktxp";
  cfg = config.homelab.features.${appName};
  prometheusCfg = cfg.prometheus;

  routerOptions = {
    options = {
      name = mkOption {
        type = str;
        description = "Router name used for local backup directory names.";
      };

      host = mkOption {
        type = str;
        description = "Router hostname or IP address.";
      };

      port = mkOption {
        type = port;
        default = 22;
        description = "Router SSH port.";
      };

      apiPort = mkOption {
        type = port;
        default = 8728;
        description = "RouterOS API port used by the Prometheus exporter.";
      };

      user = mkOption {
        type = str;
        default = "backup";
        description = "RouterOS user used to create and fetch backups.";
      };
    };
  };

  routersFile = pkgs.writeText "mikrotik-routers.json" (builtins.toJSON cfg.routers);
  backupRoot = cfg.backupRoot;
  sshKeyFile = config.clan.core.vars.generators.${appName}.files."ssh.id_ed25519".path;
  ageKeyFile = config.clan.core.vars.generators.${appName}.files."age.key".path;
  prometheusCredentialsFile = "/run/secrets/vars/${appName}/prometheus_credentials";
  generatedAgeRecipientFile = config.clan.core.vars.generators.${appName}.files."age.pub".path;
  configuredAgeRecipient = if cfg.ageRecipient == null then "" else cfg.ageRecipient;
  retention = cfg.retention;
  sshKeyComment = "${serviceName}@${config.networking.hostName}";
  listenMetricsPort = 10000 + config.homelab.portRegistry.${appName}.appId;
  prometheusInternalURL = "http://127.0.0.1:${toString listenMetricsPort}";
  prometheusExposedURL = "https://${prometheusCfg.serviceDomain}";
  prometheusDnsTargetAddress =
    let
      resolvedAddresses = resolveListenInterfaceAddresses appName prometheusCfg.listenInterfaces;
    in
    if resolvedAddresses == [ ] then config.homelab.host.address else head resolvedAddresses;

  remoteDhcpServerVlan = prometheusCfg.remoteDhcpServerVlan;
  remoteDhcpVlanExists =
    remoteDhcpServerVlan == null || hasAttr remoteDhcpServerVlan config.homelab.vlans;
  remoteDhcpVlanCfg =
    if remoteDhcpServerVlan != null && remoteDhcpVlanExists then
      config.homelab.vlans.${remoteDhcpServerVlan}
    else
      null;
  remoteDhcpServerIp = if remoteDhcpVlanCfg == null then null else remoteDhcpVlanCfg.dhcpServerIp;
  remoteDhcpEntryName =
    if remoteDhcpServerVlan == null then null else "remote-dhcp-${remoteDhcpServerVlan}";
  remoteDhcpServerVlanMessage =
    if remoteDhcpServerVlan == null then "<unset>" else remoteDhcpServerVlan;
  remoteDhcpEnabled = remoteDhcpServerVlan != null && remoteDhcpServerIp != null;
  mktxpRemoteDhcpEntry = optionalString remoteDhcpEnabled ''
    [${remoteDhcpEntryName}]
        enabled = False
        hostname = ${remoteDhcpServerIp}
        port = 8728
        custom_labels = router:${remoteDhcpEntryName}
  '';

  resolveInterfaceIPv4Addresses =
    interfaceName:
    map (address: address.address) (
      attrByPath
        [
          interfaceName
          "ipv4"
          "addresses"
        ]
        [ ]
        config.networking.interfaces
    );

  mktxpRouterEntries = concatMapStringsSep "\n\n" (router: ''
    [${router.name}]
        hostname = ${router.host}
        port = ${toString router.apiPort}
        custom_labels = router:${router.name}
        ${optionalString remoteDhcpEnabled "remote_dhcp_entry = ${remoteDhcpEntryName}"}
  '') cfg.routers;

  mktxpRoutersConfigFile = pkgs.writeText "mktxp.conf" ''
    ${mktxpRemoteDhcpEntry}

    ${mktxpRouterEntries}

    [default]
        enabled = True
        module_only = False
        hostname = localhost
        port = 8728
        username = ""
        password = ""
        credentials_file = ${prometheusCredentialsFile}
        custom_labels = None
        use_ssl = False
        no_ssl_certificate = False
        ssl_certificate_verify = False
        ssl_check_hostname = True
        ssl_ca_file = ""
        plaintext_login = True

        health = True
        installed_packages = False
        dhcp = True
        dhcp_lease = True
        connections = True
        connection_stats = True
        interface = True
        route = True
        pool = True
        firewall = True
        neighbor = True
        address_list = None
        dns = False
        ipv6_route = False
        ipv6_pool = False
        ipv6_firewall = False
        ipv6_neighbor = False
        ipv6_address_list = None
        poe = True
        monitor = True
        netwatch = True
        public_ip = True
        wireless = True
        wireless_clients = True
        capsman = False
        capsman_clients = False
        w60g = False
        eoip = False
        gre = False
        ipip = False
        lte = False
        ipsec = False
        switch_port = False
        kid_control_assigned = False
        kid_control_dynamic = False
        user = True
        queue = True
        bfd = False
        bgp = False
        routing_stats = False
        certificate = False
        container = False
        remote_dhcp_entry = None
        remote_capsman_entry = None
        interface_name_format = name
        check_for_updates = False
  '';

  mktxpSystemConfigFile = pkgs.writeText "_mktxp.conf" ''
    [MKTXP]
        listen = '127.0.0.1:${toString listenMetricsPort}'
        socket_timeout = 2

        initial_delay_on_failure = 120
        max_delay_on_failure = 900
        delay_inc_div = 5

        bandwidth = False
        bandwidth_test_dns_server = 8.8.8.8
        bandwidth_test_interval = 600
        minimal_collect_interval = 5

        verbose_mode = ${if prometheusCfg.verbose then "True" else "False"}
        fetch_routers_in_parallel = False
        max_worker_threads = 5
        max_scrape_duration = 10
        total_max_scrape_duration = 30
        http_server_threads = 16

        persistent_router_connection_pool = True
        persistent_dhcp_cache = True
        compact_default_conf_values = False
        prometheus_headers_deduplication = False
        probe_connection_pool = False
        probe_connection_pool_ttl = 300
        probe_connection_pool_max_size = 128
  '';

  mkVmalertAlertRule =
    {
      alert,
      expr,
      for,
      severity ? "warning",
      annotations ? { },
      labels ? { },
    }:
    {
      inherit alert expr for;
      annotations = {
        summary = alert;
      }
      // annotations;
      labels = {
        service = appName;
        inherit severity;
      }
      // labels;
    };

  mkRouterMissingAlert =
    router:
    mkVmalertAlertRule {
      alert = "MikroTikRouterMissing";
      expr = ''absent_over_time(mktxp_system_identity_info{router="${router.name}"}[5m])'';
      for = "2m";
      severity = "critical";
      labels.router = router.name;
      annotations.summary = "MikroTik router ${router.name} missing";
      annotations.description = "MKTXP has not exported identity metrics for this router during the last five minutes.";
    };

  mikrotikVmalertRuleGroup = {
    name = "mikrotik";
    interval = "1m";
    rules = (map mkRouterMissingAlert cfg.routers) ++ [
      (mkVmalertAlertRule {
        alert = "MikroTikHighCpu";
        expr = ''mktxp_system_cpu_load{router=~".+"} > 85'';
        for = "10m";
        annotations.summary = "MikroTik high CPU";
        annotations.description = "RouterOS CPU load has stayed above 85 percent for ten minutes.";
      })
      (mkVmalertAlertRule {
        alert = "MikroTikHighMemory";
        expr = ''(1 - mktxp_system_free_memory{router=~".+"} / mktxp_system_total_memory{router=~".+"}) * 100 > 90'';
        for = "10m";
        annotations.summary = "MikroTik high memory";
        annotations.description = "RouterOS memory usage has stayed above 90 percent for ten minutes.";
      })
      (mkVmalertAlertRule {
        alert = "MikroTikHighDisk";
        expr = ''(1 - mktxp_system_free_hdd_space{router=~".+"} / mktxp_system_total_hdd_space{router=~".+"}) * 100 > 85'';
        for = "15m";
        annotations.summary = "MikroTik high disk";
        annotations.description = "RouterOS storage usage has stayed above 85 percent for fifteen minutes.";
      })
      (mkVmalertAlertRule {
        alert = "MikroTikRecentlyRebooted";
        expr = ''mktxp_system_uptime{router=~".+"} < 600'';
        for = "1m";
        annotations.summary = "MikroTik recently rebooted";
        annotations.description = "RouterOS uptime is below ten minutes.";
      })
    ];
  };

  mikrotikGrafanaDeletedAlertRules = [
    {
      orgId = 1;
      uid = "mikrotik-router-missing-metrics";
    }
  ]
  ++ (map (router: {
    orgId = 1;
    uid = "mikrotik-router-missing-${router.name}";
  }) cfg.routers)
  ++ [
    {
      orgId = 1;
      uid = "mikrotik-high-cpu";
    }
    {
      orgId = 1;
      uid = "mikrotik-high-memory";
    }
    {
      orgId = 1;
      uid = "mikrotik-high-disk";
    }
    {
      orgId = 1;
      uid = "mikrotik-recently-rebooted";
    }
  ];

  backupScript = import ./backup-script.nix {
    inherit
      pkgs
      serviceName
      routersFile
      backupRoot
      sshKeyFile
      generatedAgeRecipientFile
      configuredAgeRecipient
      retention
      ;
  };

  listBackupScript = import ./list-backup-script.nix {
    inherit
      pkgs
      backupRoot
      ;
  };

  restoreBackupScript = import ./restore-backup-script.nix {
    inherit
      pkgs
      ageKeyFile
      sshKeyFile
      ;
  };
in
{
  ############################################################################
  # Options
  ############################################################################
  options.homelab.features.${appName} = mkFeatureOptions {
    extraOptions = {
      enable = mkEnableOption appName;

      backup = mkEnableOption "MikroTik configuration backups";

      prometheus = mkOption {
        type = submodule {
          options = {
            enable = mkEnableOption "MikroTik Prometheus integration";

            openFirewall = mkEnableOption "Open MikroTik Prometheus exporter firewall ports";

            serviceDomain = mkOption {
              type = str;
              default = "mikrotik-exporter.${config.homelab.domain}";
              description = "MikroTik Prometheus exporter service domain name.";
            };

            registerScope = mkOption {
              type = listOf str;
              default = [ ];
              description = "DNS registration scopes for the MikroTik Prometheus exporter domain.";
            };

            listenInterfaces = mkOption {
              type = listOf str;
              default = [ ];
              description = "Network interfaces that expose the MikroTik Prometheus exporter reverse proxy when openFirewall is enabled.";
            };

            verbose = mkOption {
              type = bool;
              default = false;
              description = "Enable verbose MKTXP exporter logs for troubleshooting RouterOS API collection.";
            };

            remoteDhcpServerVlan = mkOption {
              type = nullOr str;
              default = null;
              description = "VLAN whose DHCP server RouterOS API is used by MKTXP remote DHCP resolution.";
            };
          };
        };
        default = { };
        description = "MikroTik Prometheus exporter configuration.";
      };

      routers = mkOption {
        type = listOf (submodule routerOptions);
        default = [ ];
        description = "MikroTik routers backed up by this feature.";
      };

      backupRoot = mkOption {
        type = str;
        default = "/data/backup/mikrotik";
        description = "Root directory used to store encrypted MikroTik backups.";
      };

      retention = mkOption {
        type = ints.positive;
        default = 30;
        description = "Number of encrypted backup/export files to retain per router.";
      };

      calendar = mkOption {
        type = str;
        default = "03:30";
        description = "Systemd OnCalendar expression for MikroTik backups.";
      };

      ageRecipient = mkOption {
        type = nullOr str;
        default = null;
        description = "Optional age recipient. If unset, the generated MikroTik age key is used.";
      };

      sshKnownHosts = mkOption {
        type = attrsOf str;
        default = { };
        description = "Known host public keys indexed by router host.";
      };
    };
  };

  ############################################################################
  # Configuration
  ############################################################################
  config = mkMerge [
    {
      homelab.features.${appName}.appInfos = {
        category = appCategory;
        displayName = appDisplayName;
        icon = appIcon;
        platform = appPlatform;
        description = appDescription;
        url = appUrl;
        pinnedVersion = appPinnedVersion;
        serviceURL = "";
      };
    }

    (mkIf cfg.enable {
      assertions = [
        {
          assertion = !cfg.backup || cfg.routers != [ ];
          message = "homelab.features.mikrotik.backup requires at least one router in homelab.features.mikrotik.routers.";
        }
        {
          assertion = !prometheusCfg.enable || cfg.routers != [ ];
          message = "homelab.features.mikrotik.prometheus requires at least one router in homelab.features.mikrotik.routers.";
        }
        {
          assertion = !prometheusCfg.enable || remoteDhcpServerVlan == null || remoteDhcpVlanExists;
          message = "homelab.features.mikrotik.prometheus.remoteDhcpServerVlan references unknown VLAN '${remoteDhcpServerVlanMessage}'.";
        }
        {
          assertion =
            !prometheusCfg.enable
            || remoteDhcpServerVlan == null
            || !remoteDhcpVlanExists
            || remoteDhcpServerIp != null;
          message = "homelab.vlans.${remoteDhcpServerVlanMessage}.dhcpServerIp must be set when used by homelab.features.mikrotik.prometheus.remoteDhcpServerVlan.";
        }
        {
          assertion = !prometheusCfg.openFirewall || prometheusCfg.listenInterfaces != [ ];
          message = "homelab.features.mikrotik.prometheus.listenInterfaces must be set when prometheus.openFirewall is enabled.";
        }
      ]
      ++ (map (interfaceName: {
        assertion = hasAttr interfaceName config.networking.interfaces;
        message = "homelab.features.mikrotik.prometheus.listenInterfaces references unknown interface '${interfaceName}'.";
      }) prometheusCfg.listenInterfaces)
      ++ (map (interfaceName: {
        assertion = resolveInterfaceIPv4Addresses interfaceName != [ ];
        message = "homelab.features.mikrotik.prometheus.listenInterfaces interface '${interfaceName}' has no IPv4 address configured.";
      }) prometheusCfg.listenInterfaces);

      users.groups.${appName} = { };

      users.users.${appName} = {
        isSystemUser = true;
        group = appName;
        home = "/var/lib/${appName}";
        createHome = true;
      };

      clan.core.vars.generators.${appName} = {
        files = {
          "ssh.id_ed25519" = {
            owner = appName;
            group = appName;
          };
          "ssh.id_ed25519.pub" = {
            secret = false;
          };
          "age.key" = {
            owner = appName;
            group = appName;
          };
          "age.pub" = {
            secret = false;
          };
          "prometheus_credentials" = {
            owner = appName;
            group = appName;
          };
        };

        runtimeInputs = [
          pkgs.age
          pkgs.openssh
          pkgs.pwgen
        ];

        script = ''
          ssh-keygen -q -N "" -t ed25519 -C "${sshKeyComment}" -f "$out/ssh.id_ed25519"
          cp "$out/ssh.id_ed25519.pub" "$out/ssh.id_ed25519.pub.tmp"
          mv "$out/ssh.id_ed25519.pub.tmp" "$out/ssh.id_ed25519.pub"

          age-keygen -o "$out/age.key"
          age-keygen -y "$out/age.key" > "$out/age.pub"

          password="$(pwgen -s 32 1)"
          {
            echo "username: prometheus"
            echo "password: $password"
          } > "$out/prometheus_credentials"
        '';
      };

      programs.ssh.knownHosts = mapAttrs (_: publicKey: { inherit publicKey; }) cfg.sshKnownHosts;
    })

    (mkIf (cfg.enable && cfg.backup) {
      environment.systemPackages = [
        listBackupScript
        restoreBackupScript
      ];

      programs.bash.shellAliases = (mkServiceAliases serviceName) // {
        "@mikrotik-list-backup-for-router" = "mikrotik-list-backup-for-router";
        "@mikrotik-restore-backup-file-for-router" = "mikrotik-restore-backup-file-for-router";
      };

      systemd.tmpfiles.rules = [
        "d ${backupRoot} 0750 ${appName} ${appName} -"
        "d /var/lib/${appName}/.ssh 0700 ${appName} ${appName} -"
      ];

      systemd.services.${serviceName} = {
        description = "Backup MikroTik RouterOS configurations";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          Type = "oneshot";
          User = appName;
          Group = appName;
          ExecStart = "${backupScript}/bin/${serviceName}";
          StateDirectory = appName;
          UMask = "0077";
        };
      };

      systemd.timers.${serviceName} = {
        description = "Run MikroTik RouterOS configuration backups";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.calendar;
          Persistent = true;
          RandomizedDelaySec = "15m";
        };
      };
    })

    (mkIf (cfg.enable && prometheusCfg.enable) {
      homelab.alias = mkIf prometheusCfg.openFirewall [ prometheusCfg.serviceDomain ];

      programs.bash.shellAliases = {
        "@service-${prometheusAliasName}-journal" = "journalctl -u ${prometheusServiceName}";
        "@service-${prometheusAliasName}-start" = "systemctl start ${prometheusServiceName}";
        "@service-${prometheusAliasName}-stop" = "systemctl stop ${prometheusServiceName}";
        "@service-${prometheusAliasName}-restart" = "systemctl restart ${prometheusServiceName}";
        "@service-${prometheusAliasName}-status" = "systemctl status ${prometheusServiceName}";
        "@service-${prometheusAliasName}-config-default" = "cat /etc/mktxp/_mktxp.conf";
        "@service-${prometheusAliasName}-config-routers" = "cat /etc/mktxp/mktxp.conf";
      };

      environment.etc = {
        "mktxp/mktxp.conf".source = mktxpRoutersConfigFile;
        "mktxp/_mktxp.conf".source = mktxpSystemConfigFile;
      };

      homelab.domains.localEntries."${appName}-prometheus" = mkIf (prometheusCfg.registerScope != [ ]) {
        domain = prometheusCfg.serviceDomain;
        enabled = true;
        host = config.networking.hostName;
        registerScope = prometheusCfg.registerScope;
        service = appName;
        targetAddress = prometheusDnsTargetAddress;
      };

      homelab.integrations.services.${appName} = mkDefault {
        displayName = appDisplayName;
        category = appCategory;
        icon = appIcon;
        description = appDescription;

        homepage = mkIf config.services.homepage-dashboard.enable {
          icon = "sh-${appIcon}";
          href = prometheusExposedURL;
          description = "${appDescription} metrics [${prometheusCfg.serviceDomain}]";
          siteMonitor = prometheusInternalURL;
        };

        gatus = mkIf config.services.gatus.enable {
          name = "${appDisplayName} Exporter";
          url = prometheusInternalURL;
          group = appCategory;
          type = "HTTP";
          interval = "5m";
          conditions = [
            "[STATUS] == 200"
            "[BODY] == pat(*mktxp*)"
          ];
          ui.hide-hostname = true;
        };

        victoriametrics = {
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString listenMetricsPort}" ];
              labels = {
                instance = config.networking.hostName;
                service = appName;
              };
            }
          ];
        };

        vmalert = {
          ruleGroups = [
            mikrotikVmalertRuleGroup
          ];
        };

        grafana = {
          alerting.rules = {
            deleteRules = mikrotikGrafanaDeletedAlertRules;
          };
          dashboards = [
            ((mkGrafanaDashboardProvider appName ./grafana/dashboards) // {
              folder = "MikroTik";
              folderUid = "mikrotik";
            })
          ];
        };
      };

      networking.firewall.interfaces = mkIf prometheusCfg.openFirewall (
        genAttrs prometheusCfg.listenInterfaces (_: {
          allowedTCPPorts = [ 443 ];
        })
      );

      security.acme.acceptTerms = mkIf prometheusCfg.openFirewall true;

      services.caddy.virtualHosts = mkIf prometheusCfg.openFirewall {
        "${prometheusCfg.serviceDomain}" = {
          listenAddresses = resolveListenInterfaceAddresses appName prometheusCfg.listenInterfaces;
          logFormat = ''
            output file /var/log/caddy/public.log {
              mode 0644
            }
            format json
          '';

          extraConfig = ''
            reverse_proxy ${prometheusInternalURL}

            header {
              # Force HTTPS for one year.
              Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"

              # XSS and clickjacking protection.
              X-Frame-Options "SAMEORIGIN"

              # Prevent execution of untrusted MIME types.
              X-Content-Type-Options "nosniff"

              # Send only the origin as referrer for cross-origin requests.
              Referrer-Policy "strict-origin-when-cross-origin"

              # Disable unused browser features for better privacy.
              Permissions-Policy "geolocation=(), microphone=(), camera=()"

              # Allow Prometheus text output and same-origin access only.
              Content-Security-Policy "default-src 'self';"

              # Modern cross-origin isolation headers.
              Cross-Origin-Opener-Policy "same-origin"
              Cross-Origin-Resource-Policy "same-origin"
              Cross-Origin-Embedder-Policy "require-corp"

              # Cross-domain policy.
              X-Permitted-Cross-Domain-Policies "none"
            }
          '';
        };
      };

      systemd.services.${prometheusServiceName} = {
        description = "Expose MikroTik RouterOS metrics with MKTXP";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          User = appName;
          Group = appName;
          Environment = "PYTHONUNBUFFERED=1";
          StateDirectory = appName;
          UMask = "0077";
          ExecStart = "${pkgs.mktxp}/bin/mktxp --cfg-dir /etc/mktxp export";
          Restart = "on-failure";
          RestartSec = "30s";
        };
      };
    })
  ];
}
