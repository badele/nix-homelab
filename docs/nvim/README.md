# Neovim

This Neovim configuration aims to provide a comprehensive and optimized
development experience, primarily for **DevOps**. It integrates numerous
features to enhance productivity.

## Configuration

To use this Neovim configuration, simply clone the
[VIDE](https://github.com/badele/vide) project repository to `~/.config/nvim`
using the following command:
`git clone git@github.com:badele/vide.git ~/.config/nvim`

## Capabilities

This Neovim configuration offers a complete and optimized development
experience, primarily for **DevOps**, integrating numerous features to enhance
productivity:

- **Advanced Code Editing**: Support for Language Servers (LSP) for
  autocompletion, linting, formatting (via `conform.lua`, `nvim-lint`), code
  navigation, and refactoring.
- **Git Integration**: Visualization of Git changes (`gitsigns.lua`), repository
  management (`neogit.lua`).
- **Navigation and Search**: File explorer (`neotree.lua`), fuzzy search
  (`telescope.lua`), code structure outline (`outline.lua`), advanced search and
  replace (`spectre.lua`).
- **Productivity**: Autocompletion (`nvim-cmp.lua`), quick comments
  (`comment.lua`), code alignment (`easyalign.lua`), task management
  (`todo-comments.lua`), translation (`translate.lua`).
- **User Interface**: Customizable color schemes (`colorscheme.lua`), status bar
  (`lualine.lua`), dashboard (`dashboard.lua`), enhanced notifications
  (`noice.lua`), buffer management (`bufferline.lua`).
- **AI-Assisted Development**: Integration with tools like `aider.lua` and
  `copilot.lua` for programming assistance.
- **Flexible Configuration**: Customizable keyboard shortcuts with common
  configurations and a Visual Studio style.

## Languages support

The configuration supports a wide range of programming languages and file
formats, with specific features for each:

### Fully supported

| Language   | LSP | HL | FO | Lint | cmp | CA | Plugins                                                          |
| ---------- | --- | -- | -- | ---- | --- | -- | ---------------------------------------------------------------- |
| deno       | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | lspconfig (denols)                                               |
| javascript | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | lspconfig (denols)                                               |
| dockerfile | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | lspconfig (dockerls)                                             |
| lua        | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | lspconfig (lua_ls)                                               |
| markdown   | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | lspconfig (marksman), nvim-lint(markdownlint), conform(deno_fmt) |
| nix        | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | lspconfig (nixd, nil_ls)                                         |
| openscad   | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | lspconfig (openscad-lsp)                                         |
| python     | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | lspconfig (ruff)                                                 |
| scala      | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | lspconfig (metals)                                               |
| shell      | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | lspconfig (bashls), conform(shellharden)                         |
| terraform  | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | lspconfig(terraform, terraform-ls                                |
| tex/latex  | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | vimtex, lspconfig(texlab)                                        |
| typescript | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | lspconfig (denols)                                               |
| yaml       | ✅  | ✅ | ✅ | ✅   | ✅  | ✅ | lspconfig(yamlls)                                                |

### Partially supported

| Language       | LSP | HL | FO | Lint | cmp | CA | Plugins                          |
| -------------- | --- | -- | -- | ---- | --- | -- | -------------------------------- |
| ansible        | ✅  | ✅ | ❌ | ✅   | ❌  | 🔳 | ansiblels, ansible-lint          |
| d2             | ❌  | ✅ | ✅ | ❌   | ❌  | ❌ | d2-vim                           |
| diagram        | 🔳  | ❌ | ❌ | ❌   | 🔳  | 🔳 | venn                             |
| docker-compose | 🔳  | 🔳 | 🔳 | 🔳   | 🔳  | 🔳 | TODO                             |
| gnuplot        | 🔳  | ✅ | 🔳 | 🔳   | 🔳  | 🔳 | Use filetype.nvim type detection |
| go             | 🔳  | 🔳 | 🔳 | 🔳   | 🔳  | 🔳 | TODO                             |
| json           | ✅  | ✅ | ✅ | ✅   | 🔳  | 🔳 | lspconfig(jsonls), efm(fixjson)  |
| justfile       | ❌  | ✅ | ✅ | ✅   | 🔳  | 🔳 | lspconfig(jsonls), efm(fixjson)  |
| ledger         | ❌  | ✅ | ❌ | ❌   | ❌  | ❌ | vim-just                         |
| lua            | ✅  | ✅ | ✅ | ✅   | 🔳  | 🔳 | luacheck, selene, stylua         |
| makefile       | 🔳  | ✅ | ❌ | ✅   | ❌  | 🔳 | checkmake                        |
| vim            | 🔳  | 🔳 | 🔳 | 🔳   | 🔳  | 🔳 | TODO                             |

**Legend :**
`LSP-Language Server Protocol / HL-Highlight / FO-Format / CA-Code Action`

![dashboard](https://raw.githubusercontent.com/badele/vide/refs/heads/main/doc/img/plug_dashboard.png)
![outline](https://raw.githubusercontent.com/badele/vide/refs/heads/main/doc/img/plug_neotree_symbolsoutline.png)
![telescope](https://raw.githubusercontent.com/badele/vide/refs/heads/main/doc/img/plug_telescope.png)
