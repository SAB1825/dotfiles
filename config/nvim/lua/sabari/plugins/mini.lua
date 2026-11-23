vim.pack.add({
    "https://github.com/nvim-mini/mini.nvim",
    "https://github.com/rafamadriz/friendly-snippets",
})

-- Icons
require("mini.icons").setup()

-- Notifications
require("mini.notify").setup({
    -- only show messages
    content = {
        format = function(notif)
            return notif.msg
        end,
    },
})

-- Command line
require("vim._core.ui2").enable({})

require("mini.cmdline").setup({
    autocorrect = { enable = false },
})

vim.o.cmdheight = 0

-- Files
local MiniFiles = require("mini.files")
MiniFiles.setup({
    mappings = {
        go_in = "<CR>",
        go_in_plus = "L",
        go_out = "_",
        go_out_plus = "H",
    },
})

vim.keymap.set("n", "-", "<cmd>lua MiniFiles.open()<CR>", { desc = "Toggle mini file explorer" })
vim.keymap.set("n", "<leader>-", function()
    MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
    MiniFiles.reveal_cwd()
end, { desc = "Toggle into currently opened file" })

-- Surround
require("mini.surround").setup()

-- sa: add, sd: delete, sr: replace, sf/sF: find, sh: highlight.

-- Git signs
local MiniDiff = require("mini.diff")
MiniDiff.setup({
    source = MiniDiff.gen_source.git({ index = false }),
})

-- Completion
require("mini.completion").setup({
    lsp_completion = {
        auto_setup = true,
    },
})

local matugen = require("sabari.core.matugen")

-- Keep the menu transparent with an opaque selected row.
local function completion_highlights()
    local colors = matugen.colors or {}
    local foregrounds = {
        Pmenu = colors.on_surface,
        PmenuKind = colors.secondary,
        PmenuExtra = colors.on_surface_variant,
        PmenuMatch = colors.primary,
    }
    for _, group in ipairs({ "Pmenu", "PmenuKind", "PmenuExtra", "PmenuMatch", "PmenuSbar" }) do
        local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
        highlight.fg = foregrounds[group] or highlight.fg
        highlight.bg = nil
        highlight.ctermbg = nil
        vim.api.nvim_set_hl(0, group, highlight)
    end

    local selected = vim.api.nvim_get_hl(0, { name = "PmenuSel", link = false })
    selected.bg = colors.primary or selected.bg or "#303030"
    selected.fg = colors.on_primary or selected.fg or "#c6c6c6"
    vim.api.nvim_set_hl(0, "PmenuSel", selected)
    for _, group in ipairs({ "PmenuKindSel", "PmenuExtraSel", "PmenuMatchSel" }) do
        local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
        highlight.fg = colors.on_primary or highlight.fg
        highlight.bg = selected.bg
        highlight.ctermbg = nil
        vim.api.nvim_set_hl(0, group, highlight)
    end

    if colors.outline then
        vim.api.nvim_set_hl(0, "PmenuThumb", { bg = colors.outline })
        vim.api.nvim_set_hl(0, "PmenuBorder", { fg = colors.outline })
    end
    vim.api.nvim_set_hl(0, "MiniCompletionMatugenNormal", colors.on_surface
        and { fg = colors.on_surface } or { link = "NormalFloat" })
    vim.api.nvim_set_hl(0, "MiniCompletionMatugenBorder", colors.outline
        and { fg = colors.outline } or { link = "FloatBorder" })
end

vim.opt.pumblend = 0
if vim.fn.exists("+pumborder") == 1 then
    vim.opt.pumborder = "single"
end
completion_highlights()
local completion_appearance = vim.api.nvim_create_augroup("CompletionAppearance", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
    group = completion_appearance,
    callback = completion_highlights,
})
vim.api.nvim_create_autocmd("User", {
    group = completion_appearance,
    pattern = "MatugenPaletteChanged",
    callback = completion_highlights,
})
vim.api.nvim_create_autocmd("User", {
    group = completion_appearance,
    pattern = "MiniCompletionWindowOpen",
    callback = function(event)
        vim.wo[event.data.win_id].winhighlight =
            "NormalFloat:MiniCompletionMatugenNormal,FloatBorder:MiniCompletionMatugenBorder"
    end,
})

local function map_key(key, action, description)
    vim.keymap.set("i", key, action, { expr = true, desc = description })
end

map_key("<Tab>", function()
    return vim.fn.pumvisible() == 1 and "<C-n>" or "<Tab>"
end, "Next completion or Tab")

map_key("<S-Tab>", function()
    return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, "Previous completion or Shift-Tab")

map_key("<CR>", function()
    if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1 then
        return "<C-y>"
    end
    return "<CR>"
end, "Accept selected completion or newline")

for _, key in ipairs({ "<Up>", "<Down>" }) do
    map_key(key, function()
        return vim.fn.pumvisible() == 1 and "<Ignore>" or key
    end, "Disable arrow navigation during completion")
end

-- Snippets remain disabled. Set this to true to enable them.
local enable_snippets = false
if enable_snippets then
    local MiniSnippets = require("mini.snippets")
    MiniSnippets.setup({
        snippets = {
            MiniSnippets.gen_loader.from_lang(), -- loads friendly-snippets
        },
    })
    MiniSnippets.start_lsp_server({ match = false })
end
