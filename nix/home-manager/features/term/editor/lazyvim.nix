{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    extraPackages = with pkgs; [
    ];
  };

  home.packages = with pkgs; [
    # treesitter
    tree-sitter
    nodejs
    xclip # Use system clipboard
    yarn # needed by markdown-preview
    # TODO: create package diagon # Diagon diagram
    sqlite # Needed by yanky.nvim
  ];
}
