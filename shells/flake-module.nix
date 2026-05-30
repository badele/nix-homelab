{ inputs, ... }:
{
  perSystem =
    {
      inputs', # flake-parts provides this (perSystem)
      pkgs,
      system,
      ...
    }:
    let
      uefi_file = "${pkgs.OVMF.fd}/FV/OVMF.fd";

      convert2Tofu =
        provider:
        provider.override (prev: {
          homepage =
            builtins.replaceStrings
              [ "registry.terraform.io/providers" ]
              [
                "registry.opentofu.org"
              ]
              prev.homepage;
        });
    in
    {
      devShells.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          inputs'.clan-core.packages.clan-cli

          # Required by clan or used for debugging
          tor
          torsocks

          # Required by nix-homelab project
          borgbackup
          deno
          git
          home-manager
          just
          nix
          plantuml
          pre-commit
          termshot

          # Testing nix-homelab
          qemu
          qemu_kvm
          OVMF

          # Nix unentended installation
          nixos-anywhere

          # Credentials
          age
          gnupg
          pass
          pwgen
          sops
          ssh-to-age
          git-crypt

          # diagrams
          graphviz
          d2

          # Wireguard
          wireguard-tools
          openssl_3.bin

          # Openstack
          openstackclient

          # Terraform
          (opentofu.withPlugins (
            p:
            builtins.map convert2Tofu [
              p.hashicorp_external
              p.timohirt_hetznerdns
              p.hetznercloud_hcloud
              p.hashicorp_local
              p.hashicorp_null
            ]
          ))

          # Certificate
          step-cli

          # markdown web server
          inputs.gosect.packages.${system}.gosect
          go-grip
          #
        ];
        env.UEFI_FILE = uefi_file;
      };
    };
}
#
# { inputs, ... }:
# {
#   perSystem =
#     { system, ... }:
#     {
#       # Devshell for bootstrapping
#       # Acessible through 'nix develop' or 'nix-shell' (legacy)
#       devShells.default =
#         let
#           pkgs = inputs.nixpkgs.legacyPackages.${system};
#         in
#         import ../shell.nix { inherit pkgs system; };
#     };
# }
