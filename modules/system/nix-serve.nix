# Run on destination nixos installation 
# export DIR_NIXSERVE=/persist/host/data/nix-serve
# mkdir -p $DIR_NIXSERVE && cd $DIR_NIXSERVE  
# nix-store --generate-binary-cache-key $(hostname).$(hostname -d) cache-priv-key.pem cache-pub-key.pem
#
# curl http://nix-server:5000/nix-cache-info
{ outputs, lib, config, ... }:
{
  # Configure sops secret 
  sops.secrets.nixserve-private-key = { };

  networking.firewall.allowedTCPPorts = [ 5000 ];
  services.nix-serve = {
    enable = true;
    secretKeyFile = config.sops.secrets.nixserve-private-key.path;
  };

  systemd.tmpfiles.rules = [
    #    "d /data/nfs/borgbackup/rpi40 0755 root root - -"
  ];

}
