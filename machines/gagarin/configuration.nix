{
  self,
  config,
  pkgs,
  ...
}:
let
  targetIP = "192.168.254.147";
  secrets = config.clan.core.vars.generators;
in
{
  imports = [
    self.nixosModules.desktop

    # Default configuration for the clan machines.
    ./disko.nix
    ../../modules/shared.nix
    ../../modules/system/tailscale.nix
  ];
  homelab = {
    nameServer = "192.168.254.154";
    host = {
      hostname = "gagarin";
      description = "A gagarin desktop";
      interface = "enp1s0";
      address = targetIP;
      gateway = "192.168.254.254";

      nproc = 8;
    };
  };

  clan.core.vars.generators = {

    # Root CA
    step-ca-root-ca = {
      share = true;
      files."root-password.txt" = {
        secret = true;
        deploy = false;
      };
      files."root-ca.key" = {
        secret = true;
        deploy = false;
      };
      files."root-ca.crt" = {
        secret = false; # exportable aux autres machines
      };

      runtimeInputs = [ pkgs.step-cli ];
      script = ''
        # Générer mot de passe root CA
        step crypto rand --format upper 32 > $out/root-password.txt

        # Créer root CA
        step certificate create "The ${config.homelab.domain} Root CA" \
          $out/root-ca.crt $out/root-ca.key \
          --profile root-ca \
          --password-file $out/root-password.txt \
          --not-after 87600h
      '';
    };
  };
  # Trust the root CA system-wide
  security.pki.certificateFiles = [
    secrets.step-ca-root-ca.files."root-ca.crt".path

  ];

  # Static DNS resolver configuration using systemd-resolved
  environment.etc."resolv.conf".source = "/run/systemd/resolve/stub-resolv.conf";
  services.resolved = {
    enable = true;
    dnssec = "false";
    llmnr = "false";
    fallbackDns = [
      "9.9.9.9"
      "1.1.1.1"
      "8.8.8.8"
    ];

    domains = [ config.homelab.domain ];

    # extraConfig = ''
    #   DNS=${config.homelab.nameServer}:${config.homelab.portRegistry.block.httpPort + 1}
    #   DNSStubListener=yes
    #
    #   # routing to local domain (resolution, not use the fallbacks resolvers)
    #   Domains=~.${config.homelab.domain}
    # '';
  };

  # Static networking configuration
  networking = {
    enableIPv6 = false;

    useDHCP = false;
    interfaces."${config.homelab.host.interface}" = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = config.homelab.host.address;
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = {
      address = config.homelab.host.gateway;
      interface = config.homelab.host.interface;
    };

    resolvconf.enable = false;
    nameservers = [
      config.homelab.nameServer
    ];
  };

  # Enable nix-ld to allow running Nix programs without a full Nix installation
  programs.nix-ld.enable = true;

  # networking.firewall = {
  #   enable = true;
  #
  #   extraCommands = ''
  #     # Allow SSH from Tailscale network only (if needed)
  #     # iptables -A nixos-fw -i tailscale0 -p tcp --dport 22 -j nixos-fw-accept
  #   '';
  #
  #   extraStopCommands = ''
  #     iptables -D nixos-fw -i tailscale0 -p tcp --dport 11435 -j nixos-fw-accept 2>/dev/null || true
  #   '';
  # };

  # Set this for clan commands use ssh i.e. `clan machines update`
  # If you change the hostname, you need to update this line to root@<new-hostname>
  # This only works however if you have avahi running on your admin machine else use IP
  clan.core.networking.targetHost = "root@${targetIP}";

}
