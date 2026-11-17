vim.pack.add({ "https://github.com/stevearc/oil.nvim" })

local function icon_highlights()
    vim.api.nvim_set_hl(0, "OilWhiteIcon", { fg = "#ffffff" })
end

icon_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("OilIconAppearance", { clear = true }),
    callback = icon_highlights,
})

require("oil").setup({
    columns = {
        { "icon", highlight = "OilWhiteIcon" },
    },
    float = {
        max_width = 0.6,
        max_height = 0.6,
        border = "rounded",
    },
    win_options = {
        signcolumn = "yes:2",
    },
    view_options = {
        show_hidden = true,
    },
    watch_for_changes = true,
    use_default_keymaps = false,
    keymaps = {
        ["<CR>"] = "actions.select",
        ["q"] = { "actions.close", mode = "n" },
    },
})
vim.keymap.set("n", "<leader>o", "<cmd>Oil --float<cr>", { silent = true, desc = "Open Oil floating explorer" })
vim.keymap.set("n", "<leader>e", "<cmd>Oil --float<cr>", { silent = true, desc = "Open Oil floating explorer" })
