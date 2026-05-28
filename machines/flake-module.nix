{
  self,
  inputs,
  ...
}:
let
  adminKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDsXvfr+qp9EtSfsNtLfp0mfrr/TMUk48RGjqRFXJEJwkpE2BDhjnBIjz/ijdNRfnwUQFE589y4L+eyG1SpJ5XD1Ia3lRPPK2ofA64h/tueS6HPBxcuQJtbZpZlcYqHFaXVxULIYqgF3VASqsZdUMMn55HfZzb1snUPgBNvsrFiuiVgIQZsrxxwtlBz+yh7cjRoyMC0QT/DPZELT29+QnSIC4CgRj9yiYZSgBxvxrWwLJvIxx87wN8xAo4dZQCIuVy55WcNd3VVW/cOVImpQKQw0NpyshUsBCHrPddNF0IU9kUBeBtVmWypYCOFi2zfaoa3aRjgkkpBmh1BCUN6XJxKb1Mde+wYzGHswTkiiHOv1iEmFjDgOmrr+Ad72Kd3J4+8ecuKqeN7TUopiLhcqwZSKIow5R1+xfxOI0K5JmPVNomurI8F0UOSgTHvz2hRREoBJ4pXFlhqYpv4J80IZpuJLhixWgm3ZUa8+CvAlaMCYOsrpFtB2d0uITOe540T4f9l1ngVVtj3FA8T/TXKY8gdHrxbj0C0whNT+yHKtaWHjXBEBgIfhjTvLGlo3F4RWr+Cko/zY9GSd7ACmT/nbQKSYwN77kqSMoeDVa3KFfCT1XCFBBvb9CrviFx+anb1nEeqAXYqWP0a3nqv1Vlvxn5QSPFCdFxex7K2kFObaniJiQ== cardno:18_150_451";

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
    specialArgs = { inherit self inputs; };
    inherit self;

    meta = {
      name = "homelab";
      description = "My personal homelab";
    };
    inventory = {
      ########################################################################
      # Machines
      ########################################################################

      machines = {
        airlock.tags = [
          "desktop"
          "printer"
          "wifi-home"
        ];
      };

      instances = {

        ########################################################################
        # Users
        ########################################################################
        users-root = {
          module.name = "users";

          roles.default.tags = [ "nixos" ];
          roles.default.settings = {
            user = "root";
            prompt = false; # Set to true if you want to be prompted
            groups = [ ];
          };
        };

        user-badele = {
          module.name = "users";

          roles.default.tags = {
            "desktop" = { };
          };

          roles.default.tags."all" = { };
          roles.default.settings = {
            user = "badele";
            share = true;
            prompt = true;
            openssh.authorizedKeys.keys = [
              adminKey
            ];
            groups = [
              "lp" # Allow root to manage printers
              "scanners" # Allow root to manage scanners

              "wheel" # Allow root to use sudo
              "networkmanager" # Allow root to manage network
              "docker" # Allow root to manage docker
            ];
          };

        };

        user-sadele = {
          module.name = "users";

          roles.default.machines = {
            "airlock" = { };
          };

          roles.default.settings = {
            user = "sadele";
            share = true;
            prompt = true;
          };
        };

        user-loadele = {
          module.name = "users";

          roles.default.machines = {
            "airlock" = { };
          };

          roles.default.settings = {
            user = "loadele";
            share = true;
            prompt = true;
          };
        };

        user-luadele = {
          module.name = "users";

          roles.default.machines = {
            "airlock" = { };
          };

          roles.default.settings = {
            user = "luadele";
            share = true;
            prompt = true;
          };
        };

        ########################################################################
        # Role & machines installation
        ########################################################################
        sshd-basic = {
          module.name = "sshd";

          roles.server.tags.all = { };
          roles.server.settings = {
            authorizedKeys = {
              "admin-key" = adminKey;
            };
          };
        };

        base = {
          module.name = "importer";
          roles.default.tags = [ "all" ];
          roles.default.extraModules = [
            ../modules/base.nix
          ];
        };

        desktop = {
          module.name = "importer";
          roles.default.tags = [ "desktop" ];
          roles.default.extraModules = [
            ../modules/desktop/apps/base.nix
          ];
        };

        wm-kde = {
          module.name = "importer";

          roles.default.machines = {
            "airlock" = { };
          };

          roles.default.extraModules = [
            ../modules/desktop/wm/xorg/kde.nix
          ];
        };

        printer-homee = {
          module.name = "importer";

          roles.default.tags = {
            "printer" = { };
          };

          roles.default.extraModules = [
            ../modules/system/printer.nix
          ];
        };

        # Password requested during deployment
        wifi-home = {
          module.name = "wifi";

          roles.default = {
            tags = [ "wifi-home" ];
            settings.networks = {
              home22 = { };
              home55 = { };
              homestreet = { };
            };
          };
        };

        # home-manager
        # https://docs.clan.lol/guides/getting-started/add-user/#using-home-manager
        # user-badele = {
        #   module.name = "users";

        #   roles.default.tags = [ "all" ];
        #   roles.default.settings = {
        #     user = "badele";
        #     share = true;
        #     openssh.authorizedKeys.keys = [
        #       "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ..."
        #     ];
        #   };
        # };

        # badele-user = {
        #   module.name = "users";

        #   roles.default.machines."gagarin" = { };

        # Docs: https://docs.clan.lol/reference/clanServices/emergency-access/
        # Set recovery password for emergency access to machine
        emergency-access = {
          roles.default.tags."all" = { };
        };

        # TODO: add postbackup to write to /var/logs/telegraf/borgbackup metric
        # try to contribute to borgbackup module to add this feature
        borgbackup = {
          roles.client.machines."houston".settings = {
            destinations."storagebox" = {
              repo = "${borgUser}@${borgHost}:/./borgbackup";
              rsh = "ssh -oPort=${borgPort} -i /run/secrets/vars/borgbackup/borgbackup.ssh";
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
            p.hashicorp_external
            p.timohirt_hetznerdns
            p.hashicorp_local
            p.hetznercloud_hcloud
            p.hashicorp_null
            p.hashicorp_tls
          ]);
        in
        {
          # `nix run .#dns` will fail
          # This is used as a module from the `terraform` terranix config
          terranixConfigurations.dns = {
            workdir = "terraform";
            modules = [
              self.lib.terranixModules.base
              self.lib.terranixModules.dns
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
              self.lib.terranixModules.base
              self.lib.terranixModules.with-dns
              self.lib.terranixModules.hcloud
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
