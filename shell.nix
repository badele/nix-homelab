# Shell for bootstrapping flake-enabled nix and home-manager
# You can enter it through 'nix develop' or (legacy) 'nix-shell'

{ pkgs ? (import ./nixpkgs.nix) { }, system }:
let
  uefi_file = "${pkgs.OVMF.fd}/FV/OVMF.fd";
in
{
  default = pkgs.mkShell {
    # Enable experimental features without having to specify the argument
    NIX_CONFIG = "experimental-features = nix-command flakes";
    nativeBuildInputs = with pkgs; [

      # Required by nix-homelab project
      borgbackup
      deno
      git
      home-manager
      just
      nix
      plantuml
      pre-commit

      # Testing nix-homelab
      qemu
      qemu_kvm
      OVMF

      # Credentials
      age
      gnupg
      pass
      pwgen
      sops
      ssh-to-age

      # Required by invoke
      python3.pkgs.invoke
      python3.pkgs.deploykit
      python3.pkgs.xmltodict

      # Wireguard
      openssl_3_0.bin
      wireguard-tools

    ] ++ lib.optional (stdenv.isLinux) mkpasswd;

    shellHook = ''
      export UEFI_FILE=${uefi_file};
    '';
  };
}
