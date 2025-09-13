{
  self,
  inputs,
  ...
}:
let
  houston_ipv4 = "91.99.130.127";

  borgUser = "u444061";
  borgHost = "${borgUser}.your-storagebox.de";
  borgPort = "23";

in
{
  imports = [
    inputs.terranix.flakeModule
  ];

  flake.clan = {
    # Make flake available in modules
    specialArgs = { inherit self; };
    inherit self;

    meta = {
      name = "homelab";
      description = "My personal homelab";
    };

    inventory = {
      machines = {
        hype10 = {
          tags = [ "hypervisor" ];
        };
      };

      instances = {
        # home-manager
        # https://docs.clan.lol/guides/getting-started/add-user/#using-home-manager
        badele-user = {
          module.name = "users";

          roles.default.machines."gagarin" = { };

          roles.default.settings = {
            user = "badele";
            groups = [
              "audio"
              "input"
              "networkmanager"
              "video"
              "wheel"
            ];
          };

          roles.default.extraModules = [
            ./../modules/users/badele/gagarin.nix
          ];
        };

        # Docs: https://docs.clan.lol/reference/clanServices/admin/
        # Admin service for managing machines
        # This service adds a root password and SSH access.
        admin = {
          roles.default.tags."all" = { };
          roles.default.settings.allowedKeys = {
            badele = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDsXvfr+qp9EtSfsNtLfp0mfrr/TMUk48RGjqRFXJEJwkpE2BDhjnBIjz/ijdNRfnwUQFE589y4L+eyG1SpJ5XD1Ia3lRPPK2ofA64h/tueS6HPBxcuQJtbZpZlcYqHFaXVxULIYqgF3VASqsZdUMMn55HfZzb1snUPgBNvsrFiuiVgIQZsrxxwtlBz+yh7cjRoyMC0QT/DPZELT29+QnSIC4CgRj9yiYZSgBxvxrWwLJvIxx87wN8xAo4dZQCIuVy55WcNd3VVW/cOVImpQKQw0NpyshUsBCHrPddNF0IU9kUBeBtVmWypYCOFi2zfaoa3aRjgkkpBmh1BCUN6XJxKb1Mde+wYzGHswTkiiHOv1iEmFjDgOmrr+Ad72Kd3J4+8ecuKqeN7TUopiLhcqwZSKIow5R1+xfxOI0K5JmPVNomurI8F0UOSgTHvz2hRREoBJ4pXFlhqYpv4J80IZpuJLhixWgm3ZUa8+CvAlaMCYOsrpFtB2d0uITOe540T4f9l1ngVVtj3FA8T/TXKY8gdHrxbj0C0whNT+yHKtaWHjXBEBgIfhjTvLGlo3F4RWr+Cko/zY9GSd7ACmT/nbQKSYwN77kqSMoeDVa3KFfCT1XCFBBvb9CrviFx+anb1nEeqAXYqWP0a3nqv1Vlvxn5QSPFCdFxex7K2kFObaniJiQ== cardno:18_150_451";
          };
        };

        # Docs: https://docs.clan.lol/reference/clanServices/emergency-access/
        # Set recovery password for emergency access to machine
        emergency-access = {
          roles.default.tags."all" = { };
        };

        # Docs: https://docs.clan.lol/reference/clanServices/users/
        # Automatically generates and configures a password for the specified user account.
        user-badele = {
          module.name = "users";

          roles.default.tags."all" = { };
          roles.default.settings = {
            user = "badele";
            prompt = true;
          };
        };

        # https://docs.clan.lol/guides/mesh-vpn/
        # list zerotier network ID - zerotier-cli info
        zerotier = {
          roles.controller.machines."houston" = { };
          roles.moon.machines."houston".settings.stableEndpoints = [ houston_ipv4 ];
          roles.peer.machines."gagarin" = { };
        };

        borgbackup = {
          roles.client.machines."houston".settings = {
            destinations."storagebox" = {
              repo = "${borgUser}@${borgHost}:/./borgbackup";
              rsh = ''ssh -oPort=${borgPort} -i /run/secrets/vars/borgbackup/borgbackup.ssh'';
            };
          };

          roles.server.machines = { };
        };

      };
    };
  };

  perSystem =
    {
      inputs',
      config,
      pkgs,
      ...
    }:
    {
      terranix =
        let
          package = pkgs.opentofu.withPlugins (p: [
            p.external
            p.hetznerdns
            p.local
            p.hcloud
            p.null
            p.tls
          ]);
        in
        {
          # `nix run .#dns` will fail
          # This is used as a module from the `terraform` terranix config
          terranixConfigurations.dns = {
            workdir = "terraform";
            modules = [
              self.modules.terranix.base
              self.modules.terranix.dns
            ];
            terraformWrapper.package = package;
            terraformWrapper.extraRuntimeInputs = [ inputs'.clan-core.packages.default ];
            terraformWrapper.prefixText = ''
              TF_VAR_passphrase=$(clan secrets get tf-encryption-passphrase)
              export TF_VAR_passphrase
            '';
          };

          # `nix run .#terraform`
          terranixConfigurations.terraform = {
            workdir = "terraform";
            modules = [
              self.modules.terranix.base
              self.modules.terranix.with-dns
              self.modules.terranix.hcloud
              ./houston/terraform-configuration.nix
            ];
            terraformWrapper.package = package;
            terraformWrapper.extraRuntimeInputs = [ inputs'.clan-core.packages.default ];
            terraformWrapper.prefixText = ''
              TF_VAR_passphrase=$(clan secrets get tf-encryption-passphrase)
              export TF_VAR_passphrase
              TF_ENCRYPTION=$(cat <<EOF
              key_provider "pbkdf2" "state_encryption_password" {
                passphrase = "$TF_VAR_passphrase"
              }
              method "aes_gcm" "encryption_method" {
                keys = "\''${key_provider.pbkdf2.state_encryption_password}"
              }
              state {
                enforced = true
                method = "\''${method.aes_gcm.encryption_method}"
              }
              EOF
              )

              # shellcheck disable=SC2090
              export TF_ENCRYPTION
            '';
          };
        };
    };
}
