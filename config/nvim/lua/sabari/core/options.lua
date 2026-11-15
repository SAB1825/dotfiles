vim.g.netrw_banner = 0
vim.opt.termguicolors = true

-- Reuse the pinned navigator installed by tmux's submodule setup.
local navigator = vim.fn.expand("~/.config/tmux/.tmux/plugins/vim-tmux-navigator")
if vim.fn.filereadable(navigator .. "/plugin/tmux_navigator.vim") == 1 then
    vim.opt.runtimepath:append(navigator)
end

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.fillchars:append({ eob = " " })

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.wrap = false
vim.opt.smartindent = true
vim.opt.inccommand = "split"

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.laststatus = 3

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
vim.opt.undofile = true

vim.opt.completeopt = "menuone,noselect,fuzzy,nosort"
vim.opt.shortmess:append("c")
vim.opt.clipboard:append("unnamedplus")
vim.opt.isfname:append("@-@")
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"
vim.opt.scrolloff = 8

vim.opt.colorcolumn = "0"
vim.opt.signcolumn = "yes"
