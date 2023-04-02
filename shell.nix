# Shell for bootstrapping flake-enabled nix and home-manager
# You can enter it through 'nix develop' or (legacy) 'nix-shell'

{ pkgs ? (import ./nixpkgs.nix) { } }: {
  default = pkgs.mkShell {
    # Enable experimental features without having to specify the argument
    NIX_CONFIG = "experimental-features = nix-command flakes";
    nativeBuildInputs = with pkgs; [
      nix
      git
      home-manager
      borgbackup
      vim

      sops
      gnupg
      age

      python3.pkgs.invoke
      python3.pkgs.deploykit
      python3.pkgs.xmltodict
      wireguard-tools
      openssl_3_0.bin
    ] ++ lib.optional (stdenv.isLinux) mkpasswd;
  };
}
