{
  # See
  # Flake => https://nixos.wiki/wiki/Flakes

  description = "Nixos homelab configuration with flakes";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs-master is used to temporarily pull packages that are broken in
    # nixos-unstable but already fixed in master (fix merged, not yet propagated).
    # Once the fix reaches nixos-unstable, revert the affected packages to pkgs.*
    # and remove the nixpkgs-master input.
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    # nixpkgs.url = "github:nixos/nixpkgs/23.05";
    # nixpkgs.url = "path:/home/badele/ghq/github.com/badele/fork-nixpkgs";
    # nixpkgs.url = "github:badele/fork-nixpkgs/unstable-fix-smokeping-symbolic-links";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:

    nixpkgs-victoriametrics = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

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
    hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Color scheme
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    clan-core = {
      url = "https://git.clan.lol/clan/clan-core/archive/main.zip";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    terranix = {
      url = "github:terranix/terranix";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gosect = {
      url = "github:badele/gosect";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    radio = {
      url = "github:pinpox/radio";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    proxmox-nixos = {
      url = "github:SaumonNet/proxmox-nixos";
    };

  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        # "aarch64-linux"
        "x86_64-linux"
      ];

      imports = [
        inputs.clan-core.flakeModules.default

        ./flakes/shells/flake-module.nix
        ./machines/flake-module.nix
        ./modules/flake-module.nix
        ./flakes/packages/flake-module.nix
        ./templates/flake-module.nix
      ];
    };
}
