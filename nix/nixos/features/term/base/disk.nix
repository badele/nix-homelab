{ lib, pkgs, inputs, outputs, ... }: {
  imports = [
  ];

  services.udisks2.enable = true;

  environment.systemPackages = with pkgs; [
    cryptsetup
  ];
}
