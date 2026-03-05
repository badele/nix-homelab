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
    specialArgs = { inherit self inputs; };
    inherit self;

    meta = {
      name = "homelab";
      description = "My personal homelab";
    };

    inventory = {
      machines = { };

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
