{
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
{
  imports = [ ];

  services.udisks2.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc

      # Misc
      expat
      zlib

      # X11 / input
      libX11
      libXcursor
      libXi
      libXrandr
      libXrender
      libXext
      libXfixes
      libxcb
      libXinerama
      libxkbcommon

      # OpenGL / EGL
      libglvnd
      mesa
      libdrm
      libGL
    ];
  };

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
    xev
    xmodmap
    mesa-demos

    # Bluetooth
    bluez-tools

    # Deployment secrets tool
    sops

    # Used by nix-homelab deployemnt
    ghq
  ];
}
