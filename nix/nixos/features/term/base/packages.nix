{ lib, pkgs, inputs, outputs, ... }: {
  imports = [
  ];

  services.udisks2.enable = true;

  environment.systemPackages = with pkgs; [
    # System diagnose
    file
    lsof
    ltrace
    strace
    dig # DNS tools
    usbutils

    # Disk
    f3 # SSD benchmark
    hdparm # HDD benchmark
    nvme-cli # # nvme disk info
    smartmontools # HDD info
    testdisk # Recovery datas

    # System
    dmidecode # Hardwarde info
    pciutils # pci cards info

    # Bluetooth
    bluez-tools

    # Deployment secrets tool
    sops
  ];
}
