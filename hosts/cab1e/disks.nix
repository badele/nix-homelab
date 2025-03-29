{ inputs, ... }: {

  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices = {
    disk = {
      sda = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            bios_boot = {
              priority = 1;
              name = "BIOS Boot";
              start = "2048s";
              end = "10239s";
              type = "EF02";
            };
            efi = {
              priority = 2;
              name = "EFI System";
              start = "10240s";
              end = "227327s";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            extended_boot = {
              priority = 3;
              name = "Linux extended boot";
              start = "227328s";
              end = "2097152s";
              type = "8300";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/boot/efi";
              };
            };
            root = {
              priority = 4;
              name = "Root";
              start = "2099200s";
              end = "104857566s";
              type = "8300";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/rootfs" = { mountpoint = "/"; };
                  "/home" = {
                    mountOptions = [ "compress=zstd" ];
                    mountpoint = "/home";
                  };
                  "/nix" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/nix";
                  };
                };
                mountpoint = "/partition-root";
              };
            };
          };
        };
      };
    };
  };
}
