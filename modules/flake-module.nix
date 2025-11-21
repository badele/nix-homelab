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
          (import ./hardware-hetzner-cloud.nix {
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

    desktop.imports = [
      ./desktop/wm/xorg/lightdm.nix
    ];

    # Homelab common modules
    homelab =
      { lib, ... }:
      {
        imports = [
          # Import authentik-nix module to make services.authentik available
          inputs.authentik-nix.nixosModules.default

          # Import common homeab definition
          ./homelab

          # Import all features definition
          (import ./features { inherit lib inputs; })
        ];
      };

  };

  #############################################################################
  # Terraform recipes
  #############################################################################
  flake.modules.terranix.base = ./terranix/base.nix;

  flake.modules.terranix.with-dns = moduleWithSystem (
    { config }: flake-parts-lib.importApply ./terranix/with-dns.nix { config' = config; }
  );
  flake.modules.terranix.dns = ./terranix/dns.nix;

  flake.modules.terranix.hcloud = ./terranix/hcloud.nix;
}
