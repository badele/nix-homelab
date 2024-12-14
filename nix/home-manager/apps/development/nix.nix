# Graphics
{ pkgs, ... }: {
  home.packages = with pkgs; [
    haskellPackages.nix-derivation # Analyse derivation with pretty-derivation < packagename.drv
    nix-prefetch-github # Compute SHA256 github repository
    nixpkgs-fmt # Nix formatter
    nix-diff # Check derivation differences
    nvd # Show diff nix packages
  ];
}
