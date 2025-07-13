{
  perSystem =
    {
      inputs', # flake-parts provides this (perSystem)
      pkgs,
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
        packages = [
          inputs'.clan-core.packages.clan-cli

          # Required by nix-homelab project
          pkgs.borgbackup
          pkgs.deno
          pkgs.git
          pkgs.home-manager
          pkgs.just
          pkgs.nix
          pkgs.plantuml
          pkgs.pre-commit
          pkgs.termshot

          # Testing nix-homelab
          pkgs.qemu
          pkgs.qemu_kvm
          pkgs.OVMF

          # Nix unentended installation
          pkgs.nixos-anywhere

          # Credentials
          pkgs.age
          pkgs.gnupg
          pkgs.pass
          pkgs.pwgen
          pkgs.sops
          pkgs.ssh-to-age
          pkgs.git-crypt

          # diagrams
          pkgs.graphviz
          pkgs.d2

          # Wireguard
          pkgs.wireguard-tools
          pkgs.openssl_3_0.bin

          # Openstack
          pkgs.openstackclient

          # Terraform
          (pkgs.opentofu.withPlugins (
            p:
            builtins.map convert2Tofu [
              p.external
              p.hetznerdns
              p.hcloud
              p.local
              p.null
            ]
          ))

          # Certificate
          pkgs.step-cli

          # kanidm
          pkgs.kanidm

        ];
        env.KANIDM_URL = "https://auth.jesuislibre.org";
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
