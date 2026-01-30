{ pkgs, ... }:
{

  # Clone the https://github.com/badele/vide to ~/.config/nvim
  programs.neovim.enable = true;
  programs.neovim.viAlias = true;
  programs.neovim.vimAlias = true;
  programs.neovim.vimdiffAlias = true;

  # All neovim plugins list from the https://github.com/badele/vide project
  home.packages = with pkgs; [
    # vide project requirements
    pre-commit

    # neovim and plugins build requirements
    cargo
    cmake
    curl
    ncurses
    nodejs
    unzip
    yarn

    # Need by plugins
    fd
    lazygit
    ripgrep
    tree-sitter
    xclip

    # Language support packages are now in separate files:
    # - nix/home-manager/features/language/ansible.nix
    # - nix/home-manager/features/language/bash.nix
    # - nix/home-manager/features/language/c.nix
    # - nix/home-manager/features/language/d2.nix
    # - nix/home-manager/features/language/go.nix
    # - nix/home-manager/features/language/javascript.nix
    # - nix/home-manager/features/language/latex.nix
    # - nix/home-manager/features/language/ledger.nix
    # - nix/home-manager/features/language/lua.nix
    # - nix/home-manager/features/language/markdown.nix
    # - nix/home-manager/features/language/nix.nix
    # - nix/home-manager/features/language/openscad.nix
    # - nix/home-manager/features/language/python.nix
    # - nix/home-manager/features/language/scala.nix
    # - nix/home-manager/features/language/terraform.nix
    # - nix/home-manager/features/language/yaml.nix
  ];

}
