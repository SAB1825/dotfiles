vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" })

local lualine = require("lualine")

local matugen = require("sabari.core.matugen")

local function theme()
	local colors = matugen.colors or {}
	local foreground = colors.on_surface or "#dedede"
	local muted = colors.on_surface_variant or "#969696"
	local surface = colors.surface_container or "#181818"
	local section = { fg = foreground, bg = surface }

	return {
		normal = {
			a = { fg = colors.on_primary or "#161616", bg = colors.primary or "#bcbcbc", gui = "bold" },
			b = section,
			c = { fg = foreground, bg = "NONE" },
		},
		insert = {
			a = { fg = colors.on_secondary or "#161616", bg = colors.secondary or "#dedede", gui = "bold" },
			b = section,
		},
		visual = {
			a = { fg = colors.on_tertiary or "#161616", bg = colors.tertiary or "#c8c8c8", gui = "bold" },
			b = section,
		},
		replace = {
			a = { fg = colors.on_error or "#161616", bg = colors.error or "#b0b0b0", gui = "bold" },
			b = section,
		},
		inactive = {
			a = { fg = muted, bg = colors.surface_container_high or "#242424", gui = "bold" },
			b = { fg = muted, bg = surface },
			c = { fg = muted, bg = "NONE" },
		},
	}
end

local mode = { "mode" }

local diff = {
	"diff",
	colored = false,
	symbols = { added = " ", modified = " ", removed = " " }, -- changes diff symbols
	source = function()
		local summary = vim.b.minidiff_summary
		if summary then
			return { added = summary.add, modified = summary.change, removed = summary.delete }
		end
	end,
}

local filename = {
	"filename",
	file_status = true,
	path = 0,
}

local branch = { "branch", icon = "" }

local config = {
	options = {
		icons_enabled = true,
		globalstatus = true,
		theme = theme,
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
	},
	sections = {
		lualine_a = { mode },
		lualine_b = { branch },
		lualine_c = { diff, filename },
		lualine_x = {
			{ "filetype", colored = false },
		},
	},
}

lualine.setup(config)
vim.api.nvim_create_autocmd("User", {
	group = vim.api.nvim_create_augroup("LualineMatugen", { clear = true }),
	pattern = "MatugenPaletteChanged",
	callback = function()
		lualine.setup(config)
	end,
})
