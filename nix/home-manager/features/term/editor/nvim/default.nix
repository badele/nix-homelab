{ config, pkgs, ... }:
{
  # Custom help file

  xdg.configFile."nvim/doc/help.txt".text = (builtins.readFile
    ../../../../../../docs/nvim/help.txt);

  programs.neovim = {
    enable = true;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    extraPackages = with pkgs; [
      # treesitter
      tree-sitter
      nodejs
      xclip # Use system clipboard

      luajitPackages.lua-lsp # LUA LSP
      pyright # Python LSP
      rnix-lsp # Nix LSP

      # LSP servers
      nodePackages.bash-language-server
      nodePackages.dockerfile-language-server-nodejs
      nodePackages.pyright # Python
      nodePackages.typescript-language-server
      nodePackages.vim-language-server
      nodePackages.vscode-css-languageserver-bin
      nodePackages.vscode-html-languageserver-bin
      nodePackages.vscode-json-languageserver-bin
      nodePackages.yaml-language-server

      # LSP requirement Packages
      code-minimap
      luaPackages.lua-lsp
    ];

    plugins = with pkgs.vimPlugins; [
      ################################################################################
      # Editor & UI
      ################################################################################
      nvim-web-devicons # Icons
      tokyonight-nvim # Colorscheme tokyonight
      gitsigns-nvim # Git integration for buffers
      bufferline-nvim # buffer line (with tabpage integration)
      lualine-nvim # Neovim statusline written in Lua
      indent-blankline-nvim # Indentation guide
      alpha-nvim # Start screen
      which-key-nvim # Show maps keys
      neo-tree-nvim # Folders

      # scope-nvim # Introducing Enhanced Tab Scoping
      telescope-nvim # Telescope
      telescope-live-grep-args-nvim
      telescope-file-browser-nvim
      telescope-fzf-native-nvim
      telescope-symbols-nvim
      telescope-zoxide

      #  project
      project-nvim
      telescope-project-nvim

      # Tools
      vim-easy-align # Text align

      ################################################################################
      # LSP & Completion
      ################################################################################

      # Format some language
      neoformat
      comment-nvim

      # Completion
      cmp-nvim-lsp
      coq_nvim
      coq-artifacts
      coq-thirdparty
      nvim-cmp

      # LSP
      nvim-lspconfig

      markdown-preview-nvim

      vim-nix
      nvim-colorizer-lua # Colorize RGB color code ex: #444444

      # renders diagnostics using virtual lines on top of the real line of code.
      lsp_lines-nvim

      # Show function information 
      lspsaga-nvim

      # Language server to inject LSP diagnostics, code actions, and more via Lua.
      null-ls-nvim

      # Neovim setup for init.lua and plugin development with full signature help,
      # docs and completion for the nvim lua API.
      neodev-nvim

      # vscode-like pictograms for neovim lsp completion items
      lspkind-nvim

      #nvim-treesitter.withAllGrammars
      (nvim-treesitter.withPlugins (p: [
        p.tree-sitter-bash
        p.tree-sitter-dockerfile
        p.tree-sitter-go
        p.tree-sitter-json
        p.tree-sitter-json5
        p.tree-sitter-jsonc
        p.tree-sitter-lua
        p.tree-sitter-nix
        p.tree-sitter-python
        p.tree-sitter-toml
        p.tree-sitter-vim
      ]))

      lsp_signature-nvim
    ];

    extraConfig = ''
          lua << EOF
      ${builtins.readFile lua/init.lua}
      ${builtins.readFile lua/alpha.lua}
      ${builtins.readFile lua/lsp_completion.lua}
      ${builtins.readFile lua/lualine.lua}
      ${builtins.readFile lua/telescope.lua}
      ${builtins.readFile lua/web-icons.lua}
      ${builtins.readFile lua/which-key.lua}
      EOF'';
  };
}
