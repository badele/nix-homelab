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

    flake-parts.url = "github:hercules-ci/flake-parts";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hardware.url = "github:NixOS/nixos-hardware/master";
    # hardware.url = "git+file:///home/badele/ghq/github.com/badele/fork-nixos-hardware";
    # hardware.url = "github:badele/fork-nixos-hardware/xps-15-9530";

    impermanence.url = "github:nix-community/impermanence";

    nur.url = "github:nix-community/NUR";
    nur.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";

    nixunits.url = "github:dcasier/nixunits";
    nixunits.inputs.nixpkgs.follows = "nixpkgs";
    # url = "github:badele/fork-nixunits/fix-systemd";
    # url = "path:/home/badele/ghq/github.com/badele/fork-nixunits";

    clan-core.url = "https://git.clan.lol/clan/clan-core/archive/main.zip";
    clan-core.inputs.nixpkgs.follows = "nixpkgs";

    srvos.url = "github:nix-community/srvos";
    srvos.inputs.nixpkgs.follows = "nixpkgs";

    terranix.url = "github:terranix/terranix";
    terranix.inputs.flake-parts.follows = "flake-parts";
    terranix.inputs.nixpkgs.follows = "nixpkgs";

    godown.url = "github:badele/godown";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      # # Hacky way to detect we're in a REPL
      # debug = builtins ? currentSystem;

      imports = [
        inputs.clan-core.flakeModules.default

        ./shells/flake-module.nix
        ./machines/flake-module.nix
        ./modules/flake-module.nix
        ./packages/flake-module.nix

        ./flake-parts/nixos-configurations.nix
        ./flake-parts/home-configurations.nix
      ];

      flake = {
        # Your custom packages and modifications, exported as overlays
        overlays = import ./nix/overlays { inherit inputs; };
        # Reusable nixos modules you might want to export
        # These are usually stuff you would upstream into nixpkgs
        nixosModules = import ./nix/modules/nixos;
        # Reusable home-manager modules you might want to export
        # These are usually stuff you would upstream into home-manager
        # homeManagerModules = import ./nix/modules/home-manager;
      };
    };
}
