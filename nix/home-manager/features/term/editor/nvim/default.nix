{ config, pkgs, ... }:
{
  # Test comment add new comment
  programs.neovim = {
    enable = true;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;


    extraPackages = with pkgs; [
      # treesitter
      tree-sitter
      nodejs

      luajitPackages.lua-lsp
      rnix-lsp
      xclip
    ];

    plugins = with pkgs; [
      ################################################################################
      # Editor & UI
      ################################################################################
      vimPlugins.nvim-web-devicons # Icons
      vimPlugins.tokyonight-nvim # Colorscheme tokyonight
      vimPlugins.gitsigns-nvim # Git integration for buffers
      vimPlugins.bufferline-nvim # buffer line (with tabpage integration)
      vimPlugins.lualine-nvim # Neovim statusline written in Lua
      vimPlugins.indent-blankline-nvim # Indentation guide
      vimPlugins.alpha-nvim # Start screen
      vimPlugins.which-key-nvim        # Show maps keys
      vimPlugins.neo-tree-nvim         # Folders

      # vimPlugins.scope-nvim # Introducing Enhanced Tab Scoping

      vimPlugins.telescope-nvim # Telescope
      vimPlugins.telescope-file-browser-nvim
      vimPlugins.telescope-fzf-native-nvim
      vimPlugins.telescope-symbols-nvim
      vimPlugins.telescope-zoxide

      #  project
      vimPlugins.project-nvim
      vimPlugins.telescope-project-nvim


      ################################################################################
      # LSP & Completion
      ################################################################################

      # Format some language
      vimPlugins.neoformat

      # Completion
      vimPlugins.cmp-nvim-lsp
      vimPlugins.coq_nvim
      vimPlugins.coq-artifacts
      vimPlugins.coq-thirdparty
      vimPlugins.nvim-cmp

      # LSP
      vimPlugins.nvim-lspconfig

      #vimPlugins.nvim-treesitter.withAllGrammars

      (vimPlugins.nvim-treesitter.withPlugins (p: [
        p.tree-sitter-bash
        p.tree-sitter-dockerfile
        p.tree-sitter-json
        p.tree-sitter-json5
        p.tree-sitter-lua
        p.tree-sitter-python
        p.tree-sitter-toml
        p.tree-sitter-go
        p.tree-sitter-nix
        p.tree-sitter-vim
      ]))
      vimPlugins.vim-nix
      vimPlugins.nvim-colorizer-lua # Colorize RGB color code ex: #444444

      # renders diagnostics using virtual lines on top of the real line of code.
      vimPlugins.lsp_lines-nvim

      # Show function information 
      vimPlugins.lspsaga-nvim

      # Language server to inject LSP diagnostics, code actions, and more via Lua.
      vimPlugins.null-ls-nvim

      # Neovim setup for init.lua and plugin development with full signature help,
      # docs and completion for the nvim lua API.
      vimPlugins.neodev-nvim

      # vscode-like pictograms for neovim lsp completion items

      vimPlugins.lspkind-nvim

      # LSP requirement Packages
      nodePackages.pyright # Python
      tree-sitter
      code-minimap
      luaPackages.lua-lsp

      # Nix
      rnix-lsp

      nodePackages.vim-language-server
      nodePackages.yaml-language-server
      nodePackages.typescript-language-server
      nodePackages.vscode-json-languageserver-bin
      nodePackages.vscode-html-languageserver-bin
      nodePackages.vscode-css-languageserver-bin
      nodePackages.pyright
      nodePackages.vscode-langservers-extracted
      vimPlugins.lsp_signature-nvim
    ];

    extraConfig = ''
          lua << EOF
          ${builtins.readFile lua/init.lua}
      ${builtins.readFile lua/web-icons.lua}
      ${builtins.readFile lua/alpha.lua}
      ${builtins.readFile lua/lsp_completion.lua}
      ${builtins.readFile lua/lualine.lua}
      ${builtins.readFile lua/which-key.lua}
      EOF'';
  };
}
