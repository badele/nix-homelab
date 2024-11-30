{
  # See
  # Flake => https://nixos.wiki/wiki/Flakes

  description = "Nixos homelab configuration with flakes";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
      url = "git+https://git.aevoo.com/aevoo/os/nixunits.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , sops-nix
    , hardware
      # , nix-pre-commit
    , stylix
    , nur
    , ...
    }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        # "i686-linux"
        "x86_64-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];
    in
    rec {
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
            ./hosts/iso
          ];
        };

        demovm = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./hosts/demovm

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                backupFileExtension = "hm-backup";
                useGlobalPkgs = true;
                useUserPackages = true;
                verbose = true;
                extraSpecialArgs = { inputs = self.inputs; };
                users = {
                  root = import ./users/root/demovm.nix;
                  demo = {
                    imports = [
                      stylix.homeManagerModules.stylix
                      ./users/demo/demovm.nix
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
            ./hosts/b4d14

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                backupFileExtension = "hm-backup";
                useGlobalPkgs = true;
                useUserPackages = true;
                verbose = true;
                extraSpecialArgs = { inputs = self.inputs; };
                users = {
                  root = import ./users/root/b4d14.nix;
                  badele = {
                    imports = [
                      nur.nixosModules.nur
                      stylix.homeManagerModules.stylix
                      ./users/badele/b4d14.nix
                    ];
                  };
                };
              };
            }
          ];
        };

        badxps = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            ./hosts/badxps

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                backupFileExtension = "hm-backup";
                useGlobalPkgs = true;
                useUserPackages = true;
                verbose = true;
                extraSpecialArgs = { inputs = self.inputs; };
                users = {
                  root = import ./users/root/badxps.nix;
                  badele = {
                    imports = [
                      nur.nixosModules.nur
                      stylix.homeManagerModules.stylix
                      ./users/badele/badxps.nix
                    ];
                  };
                };
              };
            }
          ];
        };

        sadhome = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ inputs.sops-nix.nixosModules.sops ./hosts/sadhome ];
        };

        bootstore = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ inputs.sops-nix.nixosModules.sops ./hosts/bootstore ];
        };

        rpi40 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ inputs.sops-nix.nixosModules.sops ./hosts/rpi40 ];
        };

        hype16 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            inputs.sops-nix.nixosModules.sops
            inputs.crowdsec.nixosModules.crowdsec
            inputs.crowdsec.nixosModules.crowdsec-firewall-bouncer
            inputs.nixunits.nixosModules.default
            ./hosts/hype16

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                verbose = true;
                extraSpecialArgs = { inputs = self.inputs; };
                users = {
                  root = import ./users/root/hype16.nix;
                  badele = {
                    imports = [
                      nur.nixosModules.nur
                      stylix.homeManagerModules.stylix
                      ./users/badele/hype16.nix
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
            ./hosts/hypervised/gw-dmz
          ];
        };

        trilium = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
            inputs.sops-nix.nixosModules.sops
            ./hosts/hypervised/trilium
          ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      # or 'home-manager --flake .' for current user in current hostname
      homeConfigurations = {
        #   ########################################################################
        #   # b4d14
        #   ########################################################################
        #   "root@b4d14" = home-manager.lib.homeManagerConfiguration {
        #     pkgs =
        #       nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        #     extraSpecialArgs = { inherit inputs outputs; };
        #     modules = [
        #       # > Our main home-manager configuration file <
        #       ./users/root/b4d14.nix
        #     ];
        #   };
        #
        #   "badele@b4d14" = home-manager.lib.homeManagerConfiguration {
        #     pkgs =
        #       nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        #     extraSpecialArgs = { inherit inputs outputs; };
        #     modules = [
        #       # > Our main home-manager configuration file <
        #       nur.hmModules.nur
        #       ./users/badele/b4d14.nix
        #     ];
        #   };

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
            ./users/badele/sadhome.nix
          ];
        };

        "sadele@sadhome" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./users/sadele/sadhome.nix
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
            ./users/badele/rpi40.nix
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
            ./users/root/demo.nix
          ];
        };

        "badele@demovm" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            nur.hmModules.nur
            ./users/badele/demo.nix
          ];
        };
      };
    };
}
