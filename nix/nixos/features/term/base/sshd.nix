{ outputs, lib, config, ... }:
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

  # Passwordless sudo when SSH'ing with keys
  security.pam.enableSSHAgentAuth = true;
}
