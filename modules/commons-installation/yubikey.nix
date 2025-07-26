{
  pkgs,
  ...
}:
{
  imports = [
  ];

  # Yubikey
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # Yubikey GPG card mode
  services.pcscd.enable = true;

  security.sudo.wheelNeedsPassword = false;
  security.pam.services = {
    swaylock = { };
  };
  programs.fuse.userAllowOther = true;

  environment.systemPackages = with pkgs; [
    cryptsetup
  ];
}
