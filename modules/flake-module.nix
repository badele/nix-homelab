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
      self.nixosModules.hardware-hetzner-cloud
      inputs.srvos.nixosModules.server
      inputs.srvos.nixosModules.mixins-terminfo
      inputs.srvos.nixosModules.mixins-telegraf
    ];

    houston.imports = [
      self.nixosModules.server
      inputs.srvos.nixosModules.mixins-nginx
    ];
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
