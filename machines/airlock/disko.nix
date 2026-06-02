{
  ...
}:
let
  diskId = "ata-Samsung_SSD_850_EVO_500GB_S2RBNX0K135135M";
in

{
  boot.loader.grub = {
    efiInstallAsRemovable = true;
    efiSupport = true;
  };

  disko.devices = {
    disk = {
      "main" = {
        name = "main-${diskId}";
        device = "/dev/disk/by-id/${diskId}";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            "boot" = {
              size = "1M";
              type = "EF02"; # for grub MBR
              priority = 1;
            };
            "ESP" = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            #"swap" = {
            #  size = "8G"; # adjust
            #  content = {
            #    type = "swap";
            #    discardPolicy = "both";
            #  };
            #};
            "luks" = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "--force"
                    "--label root"
                  ];
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = [ ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Automatic local snapshots
  # https://digint.ch/btrbk/doc/readme.html
  # systemctl start btrbk-<instance>
  services.btrbk = {
    instances."nix" = {
      onCalendar = "0/2:00";
      settings = {
        subvolume = "/nix";
        snapshot_create = "onchange";
        snapshot_dir = "/nix";
        snapshot_preserve = "16h 7d 2w";
        snapshot_preserve_min = "3d";
      };
    };
    instances."home" = {
      onCalendar = "0/2:00";
      settings = {
        subvolume = "/home";
        snapshot_dir = "/home";
        snapshot_preserve = "16h 7d 3w 2m";
        snapshot_preserve_min = "3d";
      };
    };
  };
}
