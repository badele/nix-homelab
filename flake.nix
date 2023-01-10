{
  description = "Nixos homelab configuration with flakes";

  nixConfig = {
    extra-substituers = [
      "http://nixcache.h:5000"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys =
      [
        "nixcache.h:+2EnxpRxBCNd5V/2PNoobcq7fW+oXpZ0IhRwL+X2WHI="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
  };

  # nix flake update --recreate-lock-file
  inputs = {
    # Hyprland
    hyprland.url = "github:hyprwm/Hyprland";
    hyprwm-contrib.url = "github:hyprwm/contrib";

    # Nix
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:badele/fork-nixos-hardware/dell-e5540";
    impermanence.url = "github:nix-community/impermanence";
    nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # flake part
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pure  base16-schemes color themes
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , flake-parts
    , ...
    }:
    flake-parts.lib.mkFlake
      { inherit inputs; }
      {
        systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
        imports = [
          ./configurations.nix
        ];
        perSystem = { system, self', inputs', pkgs, ... }: {
          devShells.default = with pkgs; mkShellNoCC {
            buildInputs = [
              python3.pkgs.invoke
              python3.pkgs.deploykit
              python3.pkgs.xmltodict
              age
              sops
              wireguard-tools
              openssl_3_0.bin
            ] ++ lib.optional (stdenv.isLinux) mkpasswd;
          };
        };
        flake = {
          hydraJobs = nixpkgs.lib.mapAttrs' (name: config: nixpkgs.lib.nameValuePair "nixos-${name}" config.config.system.build.toplevel) self.nixosConfigurations // {
            devShells = self.devShells.x86_64-linux.default;
          };
        };
      };
}
