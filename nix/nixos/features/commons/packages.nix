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

      # X11 / input
      xorg.libX11
      xorg.libXcursor
      xorg.libXi
      xorg.libXrandr
      xorg.libXrender
      xorg.libXext
      xorg.libXfixes
      xorg.libxcb
      xorg.libXinerama
      libxkbcommon

      # OpenGL / EGL
      libglvnd
      mesa
      libdrm
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
    xorg.xev
    xorg.xmodmap
    mesa-demos

    # Bluetooth
    bluez-tools

    # Deployment secrets tool
    sops

    # Used by nix-homelab deployemnt
    ghq
  ];
}
