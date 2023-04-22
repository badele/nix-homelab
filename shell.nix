# Shell for bootstrapping flake-enabled nix and home-manager
# You can enter it through 'nix develop' or (legacy) 'nix-shell'

{ pkgs ? (import ./nixpkgs.nix) { }, nix-pre-commit, system }:
let
  # Precomit configuration
  config = {
    repos = [
      {
        repo = "local";
        hooks = [

          {
            id = "reorder-python-imports";
            entry = "${pkgs.python310Packages.reorder-python-imports}/bin/reorder-python-imports";
            language = "system";
            types = [ "python" ];
          }
          {
            id = "black";
            entry = "${pkgs.python310Packages.black}/bin/black";
            language = "system";
            types = [ "python" ];
            "args" = [
              "--line-length=79"
            ];
          }
          {
            id = "flake8";
            entry = "${pkgs.python310Packages.flake8}/bin/flake8";
            language = "system";
            types = [ "python" ];
          }
        ];
      }
    ];
  };
in
{
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

    shellHook = (nix-pre-commit.lib.${system}.mkConfig {
      inherit pkgs config;
    }).shellHook;
  };
}
