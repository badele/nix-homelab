# Run on destination nixos installation 
# export DIR_NIXSERVE=/persist/host/data/nix-serve
# mkdir -p $DIR_NIXSERVE && cd $DIR_NIXSERVE  
# nix-store --generate-binary-cache-key $(hostname).$(hostname -d) cache-priv-key.pem cache-pub-key.pem
#
# curl http://nix-server:5000/nix-cache-info
{ outputs, lib, config, ... }:
let
  alias = "nixcache";
  aliasdefined = builtins.elem modName config.networking.homelab.currentHost.alias;
  domain = config.networking.domain;
  modName = "nix-serve";
  modEnabled = lib.elem modName config.networking.homelab.currentHost.modules;
in
lib.mkIf (modEnabled)
{
  # Configure sops secret 
  sops.secrets.nixserve-private-key = { };

  networking.firewall.allowedTCPPorts = [
    5000
    80
  ];

  services.nix-serve = {
    enable = true;
    secretKeyFile = config.sops.secrets.nixserve-private-key.path;
  };

  # Check if host alias is defined in homelab.json alias section
  warnings =
    lib.optional aliasdefined "No `${alias}` alias defined in alias section hosts.alias in `homelab.json`";

  # Install nginx server for human readable files
  services.nginx = {
    enable = true;
    virtualHosts = {
      "nixcache.${domain}" = {
        serverAliases = [ "nixcache" ];
        locations."/".extraConfig = ''
          proxy_pass http://localhost:${toString config.services.nix-serve.port};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        '';
      };
    };
  };
}
