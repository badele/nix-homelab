{ inputs, self, ... }:
{
  flake.nixosConfigurations = {
    # Build a iso image (NixOS installer)
    iso = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        outputs = self;
      };
      modules = [
        # "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
        inputs.sops-nix.nixosModules.sops
        ../configuration/hosts/iso
      ];
    };

    demovm = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        outputs = self;
      };
      modules = [
        inputs.sops-nix.nixosModules.sops
        ../configuration/hosts/demovm

        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            backupFileExtension = "hm-backup";
            useGlobalPkgs = true;
            useUserPackages = true;
            verbose = true;
            users = {
              root = import ../configuration/users/root/demovm.nix;
              demo = {
                imports = [
                  inputs.stylix.homeManagerModules.stylix
                  ../configuration/users/demo/demovm.nix
                ];
              };
            };
          };
        }
      ];
    };

    b4d14 = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        outputs = self;
      };
      modules = [
        inputs.sops-nix.nixosModules.sops

        ../nix/modules/nixos/default.nix
        ../configuration/hosts/b4d14

        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            backupFileExtension = "hm-backup";
            useGlobalPkgs = true;
            useUserPackages = true;
            verbose = true;
            extraSpecialArgs = {
              inputs = self.inputs;
            };
            users = {
              root = import ../configuration/users/root/b4d14.nix;
              badele = {
                imports = [
                  inputs.stylix.homeManagerModules.stylix
                  ../configuration/users/badele/b4d14.nix
                ];
              };
            };
          };

          nixpkgs.overlays = [ inputs.nur.overlay ];
          _module.args.nur = { inherit (inputs) nur; };
        }
      ];
    };

    badxps = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        outputs = self;
      };

      modules = [
        inputs.sops-nix.nixosModules.sops
        inputs.nixunits.nixosModules.default

        ../nix/modules/nixos/default.nix
        ../configuration/hosts/badxps

        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            backupFileExtension = "hm-backup";
            useGlobalPkgs = true;
            useUserPackages = true;
            verbose = true;
            extraSpecialArgs = {
              inputs = self.inputs;
            };
            users = {
              root = import ../configuration/users/root/badxps.nix;
              badele = {
                imports = [
                  inputs.stylix.homeManagerModules.stylix
                  ../configuration/users/badele/badxps.nix
                ];
              };
            };
          };

          nixpkgs.overlays = [ inputs.nur.overlay ];
          _module.args.nur = { inherit (inputs) nur; };
        }
      ];
    };

    sadhome = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        outputs = self;
      };
      modules = [
        inputs.sops-nix.nixosModules.sops
        ../configuration/hosts/sadhome
      ];
    };

    bootstore = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        outputs = self;
      };
      modules = [
        inputs.sops-nix.nixosModules.sops
        ../configuration/hosts/bootstore
      ];
    };

    rpi40 = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        outputs = self;
      };
      modules = [
        inputs.sops-nix.nixosModules.sops
        ../configuration/hosts/rpi40
      ];
    };

    # hype10 = inputs.nixpkgs.lib.nixosSystem {
    #   specialArgs = { inherit inputs; outputs = self; };
    #   modules = [
    #     inputs.sops-nix.nixosModules.sops
    #     inputs.nixunits.nixosModules.default
    #     ../configuration/hosts/hype10
    #
    #     inputs.home-manager.nixosModules.home-manager
    #     {
    #       home-manager = {
    #         useGlobalPkgs = true;
    #         useUserPackages = true;
    #         verbose = true;
    #         extraSpecialArgs = { inputs = self.inputs; };
    #         users = {
    #           root = import ../configuration/users/root/hype10.nix;
    #           badele = {
    #             imports = [
    #               inputs.stylix.homeManagerModules.stylix
    #               ../configuration/users/badele/hype10.nix
    #             ];
    #           };
    #         };
    #       };
    #     }
    #   ];
    # };

    #######################################################################
    # Hypervised applications
    #######################################################################

    gw-dmz = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
        inputs.sops-nix.nixosModules.sops
        ../configuration/hosts/hypervised/gw-dmz
      ];
    };

    trilium = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
        inputs.sops-nix.nixosModules.sops
        ../configuration/hosts/hypervised/trilium
      ];
    };

    ########################################################################
    # cab1e (Wireguard VPN server)
    ########################################################################
    cab1e = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        outputs = self;
      };
      modules = [
        inputs.sops-nix.nixosModules.sops
        inputs.nixunits.nixosModules.default

        ../configuration/hosts/cab1e

        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            backupFileExtension = "hm-backup";
            useGlobalPkgs = true;
            useUserPackages = true;
            verbose = true;
            extraSpecialArgs = {
              inputs = self.inputs;
            };
            users = {
              root = import ../configuration/users/root/cab1e.nix;
              badele = {
                imports = [
                  inputs.stylix.homeManagerModules.stylix
                  ../configuration/users/badele/cab1e.nix
                ];
              };
            };
          };
        }
      ];
    };
  };
}
