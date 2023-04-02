{ pkgs, ... }:
{

  home.packages = with pkgs; [
    # Disk
    f3 # SSD benchmark
    hdparm # HDD benchmark
    nvme-cli # # nvme disk info
    smartmontools # HDD info
    testdisk # Recovery datas

    # System
    dmidecode # Hardwarde info
    pciutils # pci cards info

    # System diagnose
    lsof
    ltrace
    strace

    # Bluetooth
    bluez-tools
  ];
}
