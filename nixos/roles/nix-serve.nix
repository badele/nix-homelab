# Run on destination nixos installation 
# export DIR_NIXSERVE=/persist/host/data/nix-serve
# mkdir -p $DIR_NIXSERVE && cd $DIR_NIXSERVE  
# nix-store --generate-binary-cache-key $(hostname).$(hostname -d) cache-priv-key.pem cache-pub-key.pem
#
# curl https://nixcache.adele.im:5000/nix-cache-info
{ outputs, lib, config, ... }:
let
  roleName = "nix-serve";
  roleEnabled = lib.elem roleName config.homelab.currentHost.roles;
  alias = "nixcache";
  aliasdefined = !(builtins.elem alias config.homelab.currentHost.alias);
  cert = (import ../../nixos/modules/system/homelab-cert.nix { inherit lib; }).environment.etc."homelab/wildcard-domain.crt.pem".source;
  port_nixserve = 5000;
in
lib.mkIf (roleEnabled)
{
  # Configure sops secret 
  sops.secrets.nixserve-private-key = { };

  networking.firewall.allowedTCPPorts = [
    port_nixserve
    80
  ];

  services.nix-serve = {
    enable = true;
    secretKeyFile = config.sops.secrets.nixserve-private-key.path;
  };

  # Check if host alias is defined in homelab.json alias section
  warnings =
    lib.optional aliasdefined "No `${alias}` alias defined in alias section ${config.networking.hostName}.alias [ ${toString config.homelab.currentHost.alias} ] in `homelab.json` file";

  services.nginx.enable = true;
  services.nginx.virtualHosts."${alias}.${config.homelab.domain}" = {
    # Use wildcard domain
    useACMEHost = config.homelab.domain;
    forceSSL = true;

    locations."/" = {
      extraConfig = ''
        proxy_pass http://127.0.0.1:${toString port_nixserve};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    };
  };
}
