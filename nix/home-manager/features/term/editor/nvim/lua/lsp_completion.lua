function on_attach(client, bufnr)
    local function map(...)
        vim.api.nvim_buf_set_keymap(bufnr, ...)
    end

    local function buf_set_option(...)
        vim.api.nvim_buf_set_option(bufnr, ...)
    end

    buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")

    -- Mappings
    local opts = {noremap = true, silent = true}

    map("n", "gD", "<Cmd>lua vim.lsp.buf.declaration()<CR>", opts)
    map("n", "gd", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)
    map("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
    map("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
    map("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
    map("n", "<leader>wa", "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>", opts)
    map("n", "<leader>wr", "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>", opts)
    map("n", "<leader>wl", "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>", opts)
    map("n", "<leader>D", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
    map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
    map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
    map("n", "<leader>e", "<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>", opts)
    map("n", "[d", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>", opts)
    map("n", "]d", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", opts)
    map("n", "<leader>q", "<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>", opts)
    -- map("n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)

    -- Set some keybinds conditional on server capabilities
    if client.server_capabilities.document_formatting then
        map("n", "<leader>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
    elseif client.server_capabilities.document_range_formatting then
        map("v", "<leader>f", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
    end
end

local lspconf = require "lspconfig"
local servers = {"pyright" , "bashls", "rls", "jsonls", "rnix", "eslint"}
local capabilities = require('cmp_nvim_lsp').default_capabilities()

for k, lang in pairs(servers) do
    lspconf[lang].setup {
        root_dir = vim.loop.cwd,
        on_attach = on_attach,
        capabilities = capabilities,
    }
end

-- Enable diagnostics
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = true,
    signs = true,
    update_in_insert = true,
}
)

-- lua lsp settings
require "lspconfig".lua_ls.setup {
    cmd = {"lua-lsp"},
    root_dir = function()
        return vim.loop.cwd()
    end,
    on_attach = on_attach,
    settings = {
        Lua = {
            runtime = {
                version = "LuaJIT",
                path = vim.split(package.path, ";")
            },
            diagnostics = {
                globals = {"vim"}
            },
            workspace = {
                library = {
                    [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                    [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true
                }
            },
            telemetry = {
                enable = false
            }
        }
    }
}

require "lspconfig".jsonls.setup {
    cmd = {"json-languageserver"},
    root_dir = function()
        return vim.loop.cwd()
    end,
    on_attach = on_attach,
}

require "lspconfig".html.setup {
    cmd = {"html-languageserver"},
    root_dir = function()
        return vim.loop.cwd()
    end,
    on_attach = on_attach,
}

require "lspconfig".cssls.setup {
    cmd = {"css-languageserver"},
    root_dir = function()
        return vim.loop.cwd()
    end,
    on_attach = on_attach,
}

------------------------
-- Completion
------------------------

vim.g.coq_settings = {
    auto_start = 'shut-up',
    xdg = true,

    clients = {
        tabnine = {
            enabled = true,
        },
    },
    display = {
        preview = {
            border = 'shadow',
        },
    },
    limits = {
        completion_auto_timeout = 0.5,
    },
    match = {
        max_results = 100,
    },
}

cmd 'packadd coq_nvim'

-- require 'coq_3p' {
--     { src = "codeium", short_name = "COD", accept_key = "<c-f>" },
-- }

--------------------------------------------------------------------------------
-- Treesitter
--------------------------------------------------------------------------------
