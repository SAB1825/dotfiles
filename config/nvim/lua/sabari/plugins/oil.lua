vim.pack.add({ "https://github.com/stevearc/oil.nvim" })

local matugen = require("sabari.core.matugen")

local function apply_highlights()
    local colors = matugen.colors or {}
    local set = vim.api.nvim_set_hl
    set(0, "OilMatugenIcon", { fg = colors.primary or "#ffffff" })
    set(0, "OilMatugenNormal", colors.on_surface
        and { fg = colors.on_surface } or { link = "Normal" })
    set(0, "OilMatugenBorder", colors.outline
        and { fg = colors.outline } or { link = "FloatBorder" })
    set(0, "OilMatugenCursorLine", colors.surface_container_high
        and { bg = colors.surface_container_high } or { link = "CursorLine" })
    if colors.primary then
        set(0, "OilDir", { fg = colors.primary })
        set(0, "OilHidden", { fg = colors.on_surface_variant })
    end
end

local appearance = vim.api.nvim_create_augroup("OilMatugen", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", { group = appearance, callback = apply_highlights })
vim.api.nvim_create_autocmd("User", {
    group = appearance,
    pattern = "MatugenPaletteChanged",
    callback = apply_highlights,
})

require("oil").setup({
    columns = {
        { "icon", highlight = "OilMatugenIcon" },
    },
    float = {
        max_width = 0.6,
        max_height = 0.6,
        border = "rounded",
    },
    win_options = {
        signcolumn = "yes:2",
        winhighlight = table.concat({
            "Normal:OilMatugenNormal",
            "NormalNC:OilMatugenNormal",
            "NormalFloat:OilMatugenNormal",
            "FloatBorder:OilMatugenBorder",
            "CursorLine:OilMatugenCursorLine",
        }, ","),
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
apply_highlights()
vim.keymap.set("n", "<leader>o", "<cmd>Oil --float<cr>", { silent = true, desc = "Open Oil floating explorer" })
vim.keymap.set("n", "<leader>e", "<cmd>Oil --float<cr>", { silent = true, desc = "Open Oil floating explorer" })
