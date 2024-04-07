
--------------------------------------------------------------------------------
-- lualine
--------------------------------------------------------------------------------
local telescope = require("telescope")
local lga_actions = require("telescope-live-grep-args.actions")

telescope.load_extension('fzf')
telescope.load_extension('projects')

telescope.setup {
    defaults = {
        -- Default configuration for telescope goes here:
        -- config_key = value,

        mappings = {
            i = {
                -- map actions.which_key to <C-h> (default: <C-/>)
                -- actions.which_key shows the mappings for your picker,
                -- e.g. git_{create, delete, ...}_branch for the git_branches picker
                ["<C-h>"] = "which_key"
            }
        }
    },

    pickers = {
        find_files = {
            -- theme = "dropdown",
            -- find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        }
    },


-- prompt_prefix = "   ",
--     selection_caret = "  ",
--     entry_prefix = "  ",
--     initial_mode = "insert",
--     selection_strategy = "reset",
--     sorting_strategy = "ascending",
--     layout_strategy = "horizontal",
--     layout_config = {
--       horizontal = {
--         prompt_position = "top",
--         preview_width = 0.55,
--         results_width = 0.8,
--       },
--       vertical = {
--         mirror = false,
--       },
--       width = 0.87,
--       height = 0.80,
--       preview_cutoff = 120,
--     },

    extensions = {
        live_grep_args = {
            auto_quoting = true, -- enable/disable auto-quoting
            mappings = {
                i = {
                    ["<C-k>"] = lga_actions.quote_prompt(),
                    ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                },
            },
        },

        fzf = {
            fuzzy = false,                   -- false will only do exact matching
            override_generic_sorter = true,  -- override the generic sorter
            override_file_sorter = true,     -- override the file sorter
            case_mode = "ignore_case",       -- or "ignore_case" or "respect_case"
        }
    }
}
