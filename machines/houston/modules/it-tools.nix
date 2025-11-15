{
  config,
  lib,
  pkgs,
  ...
}:
let
  appName = "it-tools";
  domain = "${config.networking.fqdn}";
  appDomain = "boite-a-outils.${domain}";

  image = "ghcr.io/corentinth/it-tools";
  version = "2024.10.22-7ca5933";

  appId = 12;
  listenPort = 10000 + appId;
in
{
  imports = [
    ../../../modules/system/acme.nix
    ../../../nix/modules/nixos/homelab
  ];

  networking.firewall.allowedTCPPorts = [ 443 ];

  virtualisation.oci-containers.containers.${appName} = {
    image = "${image}:${version}";
    autoStart = true;
    ports = [ "${toString listenPort}:80" ];

    environment = {
      TZ = config.time.timeZone;
    };

    extraOptions = [
      "--cap-drop=ALL"

      # for nginx
      "--cap-add=CHOWN"
      "--cap-add=SETUID"
      "--cap-add=SETGID"
      "--cap-add=NET_BIND_SERVICE"
      "--subgidname=root"
      "--subuidname=root"
    ];
  };

  services.nginx.virtualHosts."${appDomain}" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString listenPort}";
      recommendedProxySettings = true;
      proxyWebsockets = true;

      # Security headers
      extraConfig = ''
        # Force HTTPS (for 1 year)
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

        # XSS and clickjacking protection
        add_header X-Frame-Options "SAMEORIGIN" always;

        # No execution of untrusted MIME types
        add_header X-Content-Type-Options "nosniff" always;

        # Send only domain with URL referer
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;

        # Disable all unused browser features for better privacy
        add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

        # Allow only specific sources to load content (CSP)
        add_header Content-Security-Policy "default-src 'self'; font-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; img-src 'self' data:; media-src 'self' blob:  https:; connect-src 'self' https:;" always;

        # Modern CORS headers
        add_header Cross-Origin-Opener-Policy "same-origin" always;
        add_header Cross-Origin-Resource-Policy "same-origin" always;
        add_header Cross-Origin-Embedder-Policy "require-corp" always;

        # Cross-domain policy
        add_header X-Permitted-Cross-Domain-Policies "none" always;
      '';
    };

    extraConfig = ''
      access_log /var/log/nginx/public.log vcombined;
    '';
  };
}
