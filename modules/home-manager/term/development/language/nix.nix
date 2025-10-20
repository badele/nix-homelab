{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Nix
    alejandra
    deadnix
    nixd
    nil
    nixfmt-rfc-style
    nixpkgs-fmt
    statix
  ];
}
