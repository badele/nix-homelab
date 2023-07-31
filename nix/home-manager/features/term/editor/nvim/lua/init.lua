local cmd = vim.cmd
local homefolder = "$HOME/ghq" -- Home folder for telescope find_files

vim.g.mapleader = " "

vim.g.loaded_perl_provider = 0 -- Disable perl provider


--------------------------------------------------------------------------------
-- Check some plugins with :checkheath
--------------------------------------------------------------------------------

-- misc utils
local scopes = {o = vim.o, b = vim.bo, w = vim.wo}

local function opt(scope, key, value)
    scopes[scope][key] = value
    if scope ~= "o" then
        scopes["o"][key] = value
    end
end


------------------------
-- Options
------------------------

opt("b", "undofile", true)
opt("o", "ignorecase", true)
opt("o", "splitbelow", true)
opt("o", "splitright", true)
opt("o", "termguicolors", true)
opt("w", "number", true)
opt("w", "relativenumber", true)
opt("o", "numberwidth", 2)
opt("b", "textwidth", 80)
opt("w", "wrap", true)
opt("w", "cursorline", true)
opt("w", "colorcolumn", "+1")
opt("o", "mouse", "a")
opt("b", "spelllang", "en,fr")
opt("w", "signcolumn", "yes")
opt("o", "cmdheight", 1)

-- tabulation / indentline
opt("b", "expandtab", true)
opt("b", "shiftwidth", 4)


-------------------------------
-- Start screen and Colorscheme
-------------------------------
require'colorizer'.setup()
require("gitsigns").setup()
require('Comment').setup()

require('telescope').load_extension('projects')
require("project_nvim").setup {
    patterns = { ".git",  "Makefile" },
}

require("bufferline").setup {
  options = {
    right_mouse_command = nil,
    middle_mouse_command = "bdelete! %d",
    indicator = {
      style = " ",
    },
  },
}

-- Indent guide line
vim.opt.list = true
vim.opt.listchars:append ""
require("indent_blankline").setup {
    show_end_of_line = false,
}

cmd[[colorscheme tokyonight-moon]]
