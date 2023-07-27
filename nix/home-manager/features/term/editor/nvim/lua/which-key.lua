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

map("n", "<F1>", "<Cmd>h MyHelp<CR>", opt)                       -- Search
map("n", "<F25>", "<Cmd>helptags ALL<CR>", {silent=false})          -- Search
map("n", "<C-f>", "<Cmd>Telescope<CR>", {silent=false})          -- Search
map("n", "<C-b>", "<Cmd>Telescope buffers<CR>", {silent=false})  -- Search
map("n", "<C-d>", "<Cmd>NeoTreeRevealToggle<CR>", opt)           -- Show folder
map("n", "<C-s>", "<Cmd>write<CR>", opt)                         -- Save current file
map("i", "<C-s>", "<Esc><Cmd>write<CR>", opt)                    -- Save current file
map("n", "<C-L>", "<C-]>", opt)                                  -- Link to vim help link


local wk = require("which-key")
wk.register({
    ["<leader>"] = {
        s = {
            name = "+Search",
            b = { "<cmd>Telescope buffers<cr>", "Buffers" },
            c = { "<cmd>Telescope commands<cr>", "Commands" },
            f = { "<cmd>Telescope find_files<cr>", "Files" },
            o = { "<cmd>Telescope<cr>", "Other" },
            r = { "<cmd>Telescope oldfiles<cr>", "Recent files" },
            k = { "<cmd>Telescope keymaps<cr>", "Keys" },
        },

        h = {
            name = "+Help",
            k = { "<cmd>WhichKey<cr>", "Show which key" },
        },

        f = {
            name = "+File",
            d = { "<cmd>NeoTreeRevealToggle<cr>", "Toggle folder bar" },
            f = { "<cmd>Telescope find_files<cr>", "Find File" },
            r = { "<cmd>NeoTreeRevealToggle<cr>", "Reveal file in the tree" },
            o = { "<cmd>Telescope oldfiles<cr>", "Open Recent File" },
            n = { "<cmd>enew<cr>", "New File" },
        },
        t = {
            name = "+Text",
            l = { "<cmd>left<cr>", "Left align" },
            c = { "<cmd>center<cr>", "Center align" },
            r = { "<cmd>right<cr>", "Right align" },
            w = { "gqq", "Wrap" },
        },
    },
})
