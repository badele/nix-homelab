{ outputs, lib, config, pkgs, ... }:
let
  roleName = "smokeping";
  roleEnabled = lib.elem roleName config.homelab.currentHost.roles;
  alias = "smokeping";
  aliasdefined = !(builtins.elem alias config.homelab.currentHost.dnsalias);
  dnshostname = "nixos.org";
in
lib.mkIf (roleEnabled)
{
  services.smokeping = {
    enable = true;
    webService = false; # Use nginx instead

    probeConfig = ''
      +FPing
      binary = ${config.security.wrapperDir}/fping
      hostinterval = 1.5
      mininterval = 0.001
      offset = 50%
      packetsize = 5000
      pings = 20
      sourceaddress = ${config.homelab.currentHost.ipv4}
      step = 300
      timeout = 1.5

      +DNS
      binary = ${pkgs.dig}/bin/dig
      lookup = ${dnshostname}
      forks = 5
      offset = 50%
      step = 300
      timeout = 15

      + Curl
      binary = ${pkgs.curl}/bin/curl
      forks = 5
      offset = 50%
      step = 300
      urlformat = http://%host/
    '';

    targetConfig = ''
      probe = FPing
      menu = Top
      title = Network Latency Grapher
      remark = Welcome to the SmokePing website of homelab

      + Local
      menu = Local
      title = Homelab network
      ++ ${config.networking.hostName}
      menu = ${config.networking.hostName}
      title = The ${config.networking.hostName} net performance
      host = localhost


      # Host from homelab.json
      ${lib.concatStringsSep "\n"
          (lib.mapAttrsToList
            (hostname: hostinfo:
              ''
              ++ ping-${hostname}
              menu = ${hostname}
              title = The ${hostname} net performance
              host = ${hostinfo.ipv4}
              '')
            config.homelab.hosts)}

      + DNS

      probe = DNS
      menu = DNS
      title = DNS Latency Probes

      ++ dns-${config.networking.hostName}
      menu = ${config.networking.hostName}
      title = ${config.networking.hostName} DNS performance
      server = ${config.networking.hostName}
      host = ${config.networking.hostName}

      ++ all-dns
      menu = all-dns
      title = All DNS comparison
      host = /DNS/numericable1 /DNS/cloudflare0 /DNS/cisco222 /DNS/quad9 /DNS/google8

      ++ all-numericable
      menu = all-numericable
      title = All numericable DNS
      host = /DNS/numericable1 /DNS/numericable2 

      ++ all-cloudflare
      menu = all-cloudflare
      title = All cloudflare DNS
      host = /DNS/cloudflare0 /DNS/cloudflare1

      ++ all-cisco
      menu = all-cisco
      title = All cisco DNS
      host = /DNS/cisco222 /DNS/cisco220

      ++ all-quad9
      menu = all-quad9
      title = All quad9 DNS
      host = /DNS/quad9 /DNS/quad112

      ++ all-google
      menu = all-google
      title = All google DNS
      host = /DNS/google8 /DNS/google4
   
      ++ numericable1
      menu = numericable1
      title = numericable ns1.numericable.net DNS performance
      server = 89.2.0.1
      host = ns1.numericable.net

      ++ numericable2
      menu = numericable2
      title = numericable ns2.numericable.net DNS performance
      server = 89.2.0.2
      host = ns1.numericable.net

      ++ cloudflare0
      menu = cloudflare0
      title = cloudflare 1.0.0.1 DNS performance
      server = 1.0.0.1
      host = ${config.networking.hostName}

      ++ cloudflare1
      menu = cloudflare1
      title = cloudflare 1.1.1.1 DNS performance
      server = 1.1.1.1
      host = ${config.networking.hostName}

      ++ cisco222
      menu = cisco222
      title = cisco 208.67.222.222 DNS performance
      server = 208.67.222.222
      host = resolver1.opendns.com

      ++ cisco220
      menu = cisco220
      title = cisco 208.67.220.220 DNS performance
      server = 208.67.220.220
      host = resolver2.opendns.com

      ++ quad9
      menu = quad9
      title = quad9 9.9.9.9 DNS performance
      server = 9.9.9.9
      host = ${config.networking.hostName}

      ++ quad112
      menu = quad112
      title = quad9 149.112.112.112 DNS performance
      server = 149.112.112.112
      host = ${config.networking.hostName}

      ++ google8
      menu = google8
      title = google 8.8.8.8 DNS performance
      server = 8.8.8.8
      host = ${config.networking.hostName}

      ++ google4
      menu = google4
      title = google 8.8.4.4 DNS performance
      server = 8.8.4.4
      host = ${config.networking.hostName}

      + Site
      probe = Curl
      menu = Website
      title = Website Latency Probes

      ++ Github
      menu = Github
      title = Github
      host = www.github.com

      ++ Google
      menu = Google
      title = Google
      host = www.google.fr

      ++ Nixos
      menu = NixOS
      title = NixOS
      host = nixos.org
    '';
  };

  # Check if host alias is defined in homelab.json alias section
  warnings =
    lib.optional aliasdefined "No `${alias}` alias defined in alias section ${config.networking.hostName}.dnsalias [ ${toString config.homelab.currentHost.dnsalias} ] in `homelab.json` file";

  services.fcgiwrap = {
    enable = true;
  };

  services.nginx.enable = true;
  services.nginx.virtualHosts."${alias}.${config.homelab.domain}" = {
    # Use wildcard domain
    useACMEHost = config.homelab.domain;
    forceSSL = true;

    root = "${pkgs.smokeping}/htdocs";
    extraConfig = ''
      index smokeping.fcgi;
      gzip off;
    '';

    locations."~ \\.fcgi$" = {
      extraConfig = ''
        fastcgi_intercept_errors on;
        include ${pkgs.nginx}/conf/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME ${config.users.users.smokeping.home}/smokeping.fcgi;
        fastcgi_pass unix:/run/fcgiwrap.sock;
      '';
    };

    locations."/cache/" = {
      extraConfig = ''
        alias /var/lib/smokeping/cache/;
        gzip off;
      '';
    };
  };
}
