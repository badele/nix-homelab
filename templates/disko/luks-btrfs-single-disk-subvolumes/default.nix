{
  ...
}:
let
  diskId = "@DISKID@";
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
              size = "512M";
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
  # use btrbk, is a backup tool for btrfs subvolumes. It can create snapshots of subvolumes and manage their retention.
  # btrbk -c btrbk -c /etc/btrbk/home.conf
  # https://digint.ch/btrbk/doc/readme.html
  # systemctl start btrbk-<instance>
  services.btrbk = {
    instances."home" = {
      onCalendar = "0/6:00";
      settings = {
        subvolume = "/home";
        snapshot_dir = "/home";
        snapshot_preserve = "3d 2w";
        snapshot_preserve_min = "12h";
      };
    };
  };
}
