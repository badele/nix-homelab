{
  moduleWithSystem,
  flake-parts-lib,
  self,
  inputs,
  ...
}:
{
  flake.nixosModules = {
    hardware-hetzner-cloud =
      {
        config,
        lib,
        pkgs,
        modulesPath,
        ...
      }:
      {
        imports = [
          (import ./nixos/hardware-hetzner-cloud.nix {
            inherit
              config
              lib
              pkgs
              modulesPath
              ;
          })
        ];
      };

    # Server profile
    server.imports = [
      inputs.srvos.nixosModules.server
      inputs.srvos.nixosModules.mixins-terminfo
      inputs.srvos.nixosModules.mixins-telegraf
    ];

    # Homelab common modules
    homelab =
      { lib, ... }:
      {
        imports = [
          # Import authentik-nix module to make services.authentik available
          inputs.authentik-nix.nixosModules.default

          # Import common homeab definition
          ./nixos/homelab

          # Import all features definition
          (import ./nixos/features { inherit lib inputs; })
        ];
      };

  };

  #############################################################################
  # Terraform recipes
  #############################################################################
  flake.lib.terranixModules.base = ./nixos/terranix/base.nix;

  flake.lib.terranixModules.with-dns = moduleWithSystem (
    { config }: flake-parts-lib.importApply ./nixos/terranix/with-dns.nix { config' = config; }
  );
  flake.lib.terranixModules.dns = ./nixos/terranix/dns.nix;

  flake.lib.terranixModules.hcloud = ./nixos/terranix/hcloud.nix;
}
