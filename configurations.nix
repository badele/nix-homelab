{ self, ... }:
let
  inherit
    (self.inputs)
    hardware
    home-manager
    nixpkgs
    nur
    sops-nix
    ;
  nixosSystem = nixpkgs.lib.makeOverridable nixpkgs.lib.nixosSystem;

  minimalModules = [
    { _module.args.inputs = self.inputs; }
    { _module.args.self = self; }
    ./nixos/modules/users.nix
    ./nixos/modules/homelab
    ./nixos/modules/system/networking.nix
    ./nixos/modules/system/nix.nix
    ./nixos/modules/system/sshd.nix
    ./nixos/modules/system/zfs.nix


    sops-nix.nixosModules.sops
    ({ pkgs
     , config
     , ...
     }: {
      nix.nixPath = [
        "home-manager=${home-manager}"
        "nixpkgs=${pkgs.path}"
        "nur=${nur}"
      ];

      # Define default secrets.yaml file from target secrets host
      sops.secrets.root-password-hash.neededForUsers = true;
      sops.defaultSopsFile =
        let
          sopsFile = ./. + "/nixos/hosts/${config.networking.hostName}/secrets.yml";
        in
        if builtins.pathExists sopsFile
        then sopsFile
        else null;

      nix.registry = {
        home-manager.flake = home-manager;
        nixpkgs.flake = nixpkgs;
        nur.flake = nur;
      };
      time.timeZone = "UTC";
    })
  ];

  termNodeModules =
    minimalModules
    ++ [
    ];


  dekstopNodeModules =
    minimalModules
    ++ [
    ];
in
{
  flake.nixosConfigurations = {
    rpi40 = nixosSystem {
      system = "aarch64-linux";
      modules =
        dekstopNodeModules
        ++ [
          ./nixos/hosts/rpi40
        ];
    };

    bootstore = nixosSystem {
      system = "x86_64-linux";
      modules =
        termNodeModules
        ++ [
          ./modules/nixos/dashy.nix
          ./nixos/hosts/bootstore
        ];
    };

    # latino = nixosSystem {
    #   system = "x86_64-linux";
    #   modules =
    #     dekstopNodeModules
    #     ++ [
    #       ./hosts/latino.nix
    #       hardware.nixosModules.dell-latitude-5520
    #     ];
    # };

    sam = nixosSystem {
      system = "i386-linux";
      modules =
        minimalModules
        ++ [
          ./nixos/hosts/sam
        ];
    };
  };
}
