vim.pack.add({ "https://github.com/aktersnurra/no-clown-fiesta.nvim" })

require("no-clown-fiesta").setup({
    transparent = true,
})

vim.cmd.colorscheme("no-clown-fiesta")

local transparent_groups = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
    "SignColumn",
    "EndOfBuffer",
    "LineNr",
    "CursorLineNr",
    "WinSeparator",
    "StatusLine",
    "StatusLineNC",
    "TabLine",
    "TabLineFill",
    "TabLineSel",
    "MiniFilesNormal",
    "MiniFilesBorder",
    "MiniPickNormal",
    "MiniPickBorder",
}

for _, group in ipairs(transparent_groups) do
    local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
    highlight.bg = nil
    highlight.ctermbg = nil
    vim.api.nvim_set_hl(0, group, highlight)
end
