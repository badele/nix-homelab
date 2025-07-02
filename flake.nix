{
  # See
  # Flake => https://nixos.wiki/wiki/Flakes

  description = "Nixos homelab configuration with flakes";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:nixos/nixpkgs/23.05";
    # nixpkgs.url = "path:/home/badele/ghq/github.com/badele/fork-nixpkgs";
    # nixpkgs.url = "github:badele/fork-nixpkgs/unstable-fix-smokeping-symbolic-links";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hardware.url = "git+file:///home/badele/ghq/github.com/badele/fork-nixos-hardware";
    # hardware.url = "github:badele/fork-nixos-hardware/xps-15-9530";
    hardware.url = "github:NixOS/nixos-hardware/master";

    impermanence = { url = "github:nix-community/impermanence"; };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Color scheme
    stylix.url = "github:danth/stylix";

    crowdsec = {
      url = "git+https://codeberg.org/kampka/nix-flake-crowdsec.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixunits = {
      url = "github:dcasier/nixunits";
      # url = "github:badele/fork-nixunits/fix-systemd";
      # url = "path:/home/badele/ghq/github.com/badele/fork-nixunits";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, hardware
    # , nix-pre-commit
    , stylix, nur, nixunits, ... }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        # "i686-linux"
        "x86_64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];

      pkgs = import nixpkgs { overlays = [ nur.overlay ]; };
    in rec {
      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; };
        in import ./nix/pkgs { inherit pkgs; });
      # Devshell for bootstrapping
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./shell.nix { inherit pkgs system; });

      # Your custom packages and modifications, exported as overlays
      overlays = import ./nix/overlays { inherit inputs; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./nix/modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      # homeManagerModules = import ./nix/modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      # or 'nixos-rebuild --flake .' for current hostname
      nixosConfigurations = {
        # Build a iso image (NixOS installer)
        iso = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            # "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
            inputs.sops-nix.nixosModules.sops
            ./configuration/hosts/iso
          ];
        };

        demovm = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./configuration/hosts/demovm

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                backupFileExtension = "hm-backup";
                useGlobalPkgs = true;
                useUserPackages = true;
                verbose = true;
                users = {
                  root = import ./configuration/users/root/demovm.nix;
                  demo = {
                    imports = [
                      stylix.homeManagerModules.stylix
                      ./configuration/users/demo/demovm.nix
                    ];
                  };
                };
              };
            }
          ];
        };

        b4d14 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops

            ./nix/modules/nixos/default.nix
            ./configuration/hosts/b4d14

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                backupFileExtension = "hm-backup";
                useGlobalPkgs = true;
                useUserPackages = true;
                verbose = true;
                extraSpecialArgs = { inputs = self.inputs; };
                users = {
                  root = import ./configuration/users/root/b4d14.nix;
                  badele = {
                    imports = [
                      stylix.homeManagerModules.stylix
                      ./configuration/users/badele/b4d14.nix
                    ];
                  };
                };
              };

              nixpkgs.overlays = [ nur.overlay ];
              _module.args.nur = { inherit nur; };
            }
          ];
        };

        badxps = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };

          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.nixunits.nixosModules.default

            ./nix/modules/nixos/default.nix
            ./configuration/hosts/badxps

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                backupFileExtension = "hm-backup";
                useGlobalPkgs = true;
                useUserPackages = true;
                verbose = true;
                extraSpecialArgs = { inputs = self.inputs; };
                users = {
                  root = import ./configuration/users/root/badxps.nix;
                  badele = {
                    imports = [
                      stylix.homeManagerModules.stylix
                      ./configuration/users/badele/badxps.nix
                    ];
                  };
                };
              };

              nixpkgs.overlays = [ nur.overlay ];
              _module.args.nur = { inherit nur; };
            }
          ];
        };

        sadhome = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules =
            [ inputs.sops-nix.nixosModules.sops ./configuration/hosts/sadhome ];
        };

        bootstore = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./configuration/hosts/bootstore
          ];
        };

        rpi40 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules =
            [ inputs.sops-nix.nixosModules.sops ./configuration/hosts/rpi40 ];
        };

        hype10 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.nixunits.nixosModules.default
            ./configuration/hosts/hype10

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                verbose = true;
                extraSpecialArgs = { inputs = self.inputs; };
                users = {
                  root = import ./configuration/users/root/hype10.nix;
                  badele = {
                    imports = [
                      stylix.homeManagerModules.stylix
                      ./configuration/users/badele/hype10.nix
                    ];
                  };
                };
              };
            }
          ];
        };

        #######################################################################
        # Hypervised applications
        #######################################################################

        gw-dmz = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
            inputs.sops-nix.nixosModules.sops
            ./configuration/hosts/hypervised/gw-dmz
          ];
        };

        trilium = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
            inputs.sops-nix.nixosModules.sops
            ./configuration/hosts/hypervised/trilium
          ];
        };

        ########################################################################
        # cab1e (Wireguard VPN server)
        ########################################################################
        cab1e = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.nixunits.nixosModules.default

            ./configuration/hosts/cab1e

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                backupFileExtension = "hm-backup";
                useGlobalPkgs = true;
                useUserPackages = true;
                verbose = true;
                extraSpecialArgs = { inputs = self.inputs; };
                users = {
                  root = import ./configuration/users/root/cab1e.nix;
                  badele = {
                    imports = [
                      stylix.homeManagerModules.stylix
                      ./configuration/users/badele/cab1e.nix
                    ];
                  };
                };
              };
            }
          ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      # or 'home-manager --flake .' for current user in current hostname
      homeConfigurations = {
        ########################################################################
        # b4d14
        ########################################################################
        "root@b4d14" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./configuration/users/root/b4d14.nix
          ];
        };

        "badele@b4d14" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            nur.modules.homeManager
            ./configuration/users/badele/b4d14.nix
          ];
        };

        ########################################################################
        # sadhome
        ########################################################################
        "root@sadhome" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./nix/home-manager/users/root/sadhome.nix
          ];
        };

        "badele@sadhome" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./configuration/users/badele/sadhome.nix
          ];
        };

        "sadele@sadhome" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./configuration/users/sadele/sadhome.nix
          ];
        };

        ########################################################################
        # rpi40
        ########################################################################
        "badele@rpi40" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.aarch64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./configuration/users/badele/rpi40.nix
          ];
        };

        ########################################################################
        # srvhoma
        ########################################################################
        "root@srvhoma" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./configuration/users/root/srvhoma.nix
          ];
        };

        "badele@srvhoma" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            nur.modules.homeManager
            ./configuration/users/badele/srvhoma.nix
          ];
        };

        ########################################################################
        # demo
        ########################################################################
        "root@demovm" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./configuration/users/root/demo.nix
          ];
        };

        "badele@demovm" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            nur.modules.homeManager
            ./configuration/users/badele/demo.nix
          ];
        };
      };

    };
}
