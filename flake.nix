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

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hardware.url = "git+file:///home/badele/ghq/github.com/badele/fork-nixos-hardware";
    hardware.url = "github:badele/fork-nixos-hardware/xps-15-9530";
    # hardware.url = "github:NixOS/nixos-hardware/master";

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    nur.url = "github:nix-community/NUR";
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Color scheme
    nix-rice = {
      url = "github:bertof/nix-rice";
    };

    # Precomit local generator
    nix-pre-commit = {
      url = "github:jmgilman/nix-pre-commit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , sops-nix
    , hardware
    , nix-pre-commit
    , nix-rice
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
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ nix-rice.overlays.default ];
          };
        in
        import ./nix/pkgs { inherit pkgs; });
      # Devshell for bootstrapping
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./shell.nix { inherit pkgs system nix-pre-commit; });

      # Your custom packages and modifications, exported as overlays
      overlays = import ./nix/overlays { inherit inputs; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./nix/modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./nix/modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      # or 'nixos-rebuild --flake .' for current hostname
      nixosConfigurations = {
        b4d14 = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ inputs.sops-nix.nixosModules.sops ./hosts/b4d14 ];
        };

        badxps = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [ inputs.sops-nix.nixosModules.sops ./hosts/badxps ];
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
            { nixpkgs.overlays = [ nix-rice.overlays.default ]; }
            ./users/root/b4d14.nix
          ];
        };

        "badele@b4d14" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            nur.hmModules.nur
            { nixpkgs.overlays = [ nix-rice.overlays.default ]; }
            ./users/badele/b4d14.nix
          ];
        };

        ########################################################################
        # badxps
        ########################################################################
        "root@badxps" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            { nixpkgs.overlays = [ nix-rice.overlays.default ]; }
            ./users/root/badxps.nix
          ];
        };

        "badele@badxps" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            nur.hmModules.nur
            { nixpkgs.overlays = [ nix-rice.overlays.default ]; }
            ./users/badele/badxps.nix
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
            { nixpkgs.overlays = [ nix-rice.overlays.default ]; }
            ./nix/home-manager/users/root/sadhome.nix
          ];
        };

        "badele@sadhome" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            { nixpkgs.overlays = [ nix-rice.overlays.default ]; }
            ./users/badele/sadhome.nix
          ];
        };

        "sadele@sadhome" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            { nixpkgs.overlays = [ nix-rice.overlays.default ]; }
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
            { nixpkgs.overlays = [ nix-rice.overlays.default ]; }
            ./users/badele/rpi40.nix
          ];
        };
      };
    };
}
