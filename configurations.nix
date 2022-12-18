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
    ./modules/users.nix
    ./modules/system/hosts.nix
    ./modules/system/networking.nix
    ./modules/system/nix.nix
    ./modules/system/sshd.nix
    ./modules/system/zfs.nix


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
          sopsFile = ./. + "/hosts/${config.networking.hostName}/secrets.yml";
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
          ./hosts/rpi40
        ];
    };

    bootstore = nixosSystem {
      system = "x86_64-linux";
      modules =
        termNodeModules
        ++ [
          ./hosts/bootstore
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
          ./hosts/sam
        ];
    };
  };
}
