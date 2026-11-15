-- Editor settings and general mappings load before plugins.
require("sabari.core.options")
require("sabari.core.keymaps")
require("sabari.core.commands")
require("sabari.core.autocmds")

require("sabari.core.diagnostics")

-- Keep the editor usable offline before the pinned plugins have been installed.
local lock_path = vim.fn.stdpath("config") .. "/nvim-pack-lock.json"
local lock = vim.json.decode(table.concat(vim.fn.readfile(lock_path), "\n"))
local missing = {}
for name in pairs(lock.plugins) do
    if vim.fn.isdirectory(vim.fn.stdpath("data") .. "/site/pack/core/opt/" .. name .. "/.git") == 0 then
        table.insert(missing, name)
    end
end
if vim.fn.filereadable(vim.fn.stdpath("data") .. "/site/pack/core/opt/fff/target/release/libfff_nvim.so") == 0 then
    table.insert(missing, "fff native library")
end
if #missing > 0 then
    vim.cmd.colorscheme("habamax")
    vim.schedule(function()
        vim.notify("Plugins are not installed yet. Run: nvim --headless -u NONE -l ~/.config/nvim/scripts/bootstrap.lua", vim.log.levels.WARN)
    end)
    return
end

require("sabari.plugins")
