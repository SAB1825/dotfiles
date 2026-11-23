local M = {}

local config_home = vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")
local path = config_home .. "/matugen/generated/nvim.json"
local previous_contents

local function reload()
	local readable, lines = pcall(vim.fn.readfile, path)
	if not readable then
		return
	end

	local contents = table.concat(lines, "\n")
	if contents == previous_contents then
		return
	end

	local decoded, colors = pcall(vim.json.decode, contents)
	if decoded and type(colors) == "table" then
		previous_contents = contents
		M.colors = colors
		vim.api.nvim_exec_autocmds("User", { pattern = "MatugenPaletteChanged" })
	end
end

reload()

local watcher = vim.uv.new_fs_poll()
watcher:start(path, 1000, vim.schedule_wrap(reload))
watcher:unref()

return M
