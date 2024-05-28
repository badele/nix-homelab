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

      # Nix unentended installation
      nixos-anywhere

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
      wireguard-tools
      openssl_3_0.bin

      # diagrams
      graphviz

      # Wireguard
      wireguard-tools
      openssl_3_0.bin

      # Wireguard
      openssl_3_0.bin
      wireguard-tools

    ] ++ lib.optional (stdenv.isLinux) mkpasswd;

    shellHook = ''
        export UEFI_FILE=${uefi_file};
        export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib
        export LD_LIBRARY_PATH=${pkgs.zlib}/lib:$LD_LIBRARY_PATH

        # Install virtualenv
        if [ ! -e .venv ]; then
            echo "🔨 Init python environment"
            python3 -m venv .venv
            . .venv/bin/activate
            pip install -r requirements.txt
            deactivate
        fi

      # Enable the virtual environment
      . .venv/bin/activate
    '';
  };
}
