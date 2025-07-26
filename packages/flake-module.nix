{ inputs, ... }:
{
  perSystem = { system, ... }: {
    # Your custom packages
    # Acessible through 'nix build', 'nix shell', etc
    packages = 
      let pkgs = import inputs.nixpkgs { inherit system; };
      in import ../nix/pkgs { inherit pkgs; };
  };
}
