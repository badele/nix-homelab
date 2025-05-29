{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Nix
    alejandra
    deadnix
    nixd
    nil
    nixfmt
    nixpkgs-fmt
    statix
  ];
}
