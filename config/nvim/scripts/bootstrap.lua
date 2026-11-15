-- Install the repository's pinned plugins without loading the interactive config.
local config = vim.fn.stdpath("config")
local lock = vim.json.decode(table.concat(vim.fn.readfile(config .. "/nvim-pack-lock.json"), "\n"))
local specs = {}
for name, plugin in pairs(lock.plugins) do
    table.insert(specs, {
        src = plugin.src,
        name = name,
        version = name == "nvim-treesitter" and "main" or plugin.version,
    })
end
vim.pack.add(specs, { confirm = false, load = false })
-- Fail clearly if a network/download error left any plugin unavailable.
for name in pairs(lock.plugins) do
    assert(vim.fn.isdirectory(vim.fn.stdpath("data") .. "/site/pack/core/opt/" .. name .. "/.git") == 1,
        "Plugin installation failed: " .. name)
end
vim.cmd.packadd("fff")
require("fff.download").download_or_build_binary()
print("Pinned Neovim plugins installed. Open nvim to initialize Treesitter and Mason.")
