{ outputs, lib, config, ... }:

let
  hosts = outputs.nixosConfigurations;
  hostname = config.networking.hostName;
  #  prefix = "/persist/host";
  pubKey = host: ../../hosts/${hostname}/ssh_host_ed25519_key.pub;
in
{
  services.openssh = {
    enable = true;
    passwordAuthentication = true;
    permitRootLogin = "yes";

    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  # programs.ssh = {
  #   # Each hosts public key
  #   knownHosts = builtins.mapAttrs
  #     (name: _: {
  #       publicKeyFile = pubKey name;
  #       extraHostNames = lib.optional (name == hostname) "localhost";
  #     })
  #     hosts;
  # };

  # Passwordless sudo when SSH'ing with keys
  security.pam.enableSSHAgentAuth = true;
}
