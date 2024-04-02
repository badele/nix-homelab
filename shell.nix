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
      nix
      git
      home-manager
      pass
      borgbackup
      vim

      sops
      gnupg
      age
      ssh-to-age

      python3.pkgs.invoke
      python3.pkgs.deploykit
      python3.pkgs.xmltodict
      wireguard-tools
      openssl_3_0.bin

      plantuml

      just

      qemu
      qemu_kvm
      OVMF
    ] ++ lib.optional (stdenv.isLinux) mkpasswd;

    shellHook = ''
      export UEFI_FILE=${uefi_file};
    '';
  };
}
