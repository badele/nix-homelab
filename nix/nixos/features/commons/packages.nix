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
    lshw # Hardware info

    # Disk
    f3 # SSD benchmark
    hdparm # HDD benchmark
    nvme-cli # # nvme disk info
    smartmontools # HDD info
    testdisk # Recovery datas

    # System
    brightnessctl
    dmidecode # Hardwarde info
    pciutils # pci cards info

    # xorg
    xorg.xev
    xorg.xmodmap
    mesa-demos

    # Bluetooth
    bluez-tools

    # Deployment secrets tool
    sops
  ];
}
