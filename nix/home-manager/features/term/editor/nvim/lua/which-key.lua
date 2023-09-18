--------------------------------------------------------------------------------
-- which-key mappings
--------------------------------------------------------------------------------
-- Keymap Modes
-- c = command_mode 
-- i = insert_mode 
-- n = normal_mode 
-- t = term_mode 
-- v = visual_mode 
-- x = visual_block_mode 

local opt = {silent = true}
local map = vim.api.nvim_set_keymap

map("i", "<C-s>", "<Esc><Cmd>Neoformat <Bar> write<CR>", opt) -- Save current file
map("n", "<C-L>", "<C-]>", opt) -- Link to vim help link
map("n", "<C-b>", "<Cmd>Telescope buffers<CR>", {silent=false}) -- Search buffers
map("n", "<C-d>", "<Cmd>NeoTreeReveal<CR>", opt) -- Show folder
-- map("n", "<C-f>", "<Cmd>Telescope live_grep<CR>", {silent=false}) -- Search content
map("n", "<C-m>", "<Cmd>Alpha<CR>", {silent=false}) -- Search main dashboard
-- map("n", "<C-p>", "<Cmd>Telescope projects<CR>", {silent=false}) -- Search projects
map("n", "<C-s>", "<Cmd>Neoformat <Bar> write<CR>", opt) -- Format and save file
map("n", "<F1>", "<Cmd>h MyHLHelp<CR>", opt) -- Sow my help

local wk = require("which-key")
local telescope = require('telescope')
local telescopb = require('telescope.builtin')

wk.register({
    ["<leader>"] = {
        c = {
            name = "+Code",
            f = {
                name = "Format",
                n = { "<Cmd>Neoformat<Cr>"                 , "Neoformat" },
                a = { "<Cmd>Neoformat<Cr>"                 , "Autoformat" },
            },
            d = { "<Cmd>Telescope lsp_definitions<Cr>" , "Search definitions" },
            r = { "<Cmd>Telescope lsp_references<Cr>"  , "Search references" },
        },
        s = {
            name = "+Search",
            ["/"] = { "<Cmd>let @/ = ''<Cr>"                             , "Cancel search" },
            x = {
                name =" test",
                b = { telescopb.buffers                                  , "Buffers" },
            },

            b = { telescopb.buffers                                  , "Buffers" },
            c = { telescopb.commands                                 , "Commands" },
            f = { telescopb.find_files                               , "Files" },
            g = { telescope.extensions.live_grep_args.live_grep_args , "Grep" },
            h = { telescopb.help_tags                                , "Help tags" }, -- Search MyHL tags
            k = { telescopb.keymaps                                  , "Keys" },
            l = { telescopb.current_buffer_fuzzy_find                , "Search in current buffer" },
            p = { telescopb.projects                                 , "Project" },
            r = { telescopb.oldfiles                                 , "Recent files" },
            s = { "<Cmd>Telescope<Cr>"                               , "Telescope" },
            t = { telescopb.spell_suggest                            , "Translate spell suggestion" },
            v = { telescopb.vim_options                              , "Vim options" },
            w = { telescopb.grep_string                              , "Grep work around" },
        },

        h = {
            name = "+Help",
            k = { "<cmd>WhichKey<cr>"     , "Show which key" },
            r = { "<cmd>helptags ALL<Cr>" , "Refresh helptags" },
        },

        f = {
            name = "+File",
            d = { "<cmd>NeoTreeRevealToggle<cr>"  , "Toggle folder bar" },
            f = { "<cmd>Telescope find_files<cr>" , "Find File" },
            h = { "<cmd>Telescope help_tags<cr>"  , "Help tags" },
            r = { "<cmd>NeoTreeRevealToggle<cr>"  , "Reveal file in the tree" },
            o = { "<cmd>Telescope oldfiles<cr>"   , "Open Recent File" },
            n = { "<cmd>enew<cr>"                 , "New File" },
        },
        t = {
            name = "+Text",
            l = { "<cmd>left<cr>"   , "Left align" },
            c = { "<cmd>center<cr>" , "Center align" },
            r = { "<cmd>right<cr>"  , "Right align" },
            w = { "gqq"             , "Wrap" },
        },
    },
})
