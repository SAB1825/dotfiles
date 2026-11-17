vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" })

local lualine = require("lualine")

local colors = {
	color0 = "#161616",
	color1 = "#b0b0b0",
	color2 = "#dedede",
	color3 = "#242424",
	color4 = "#181818",
	color6 = "#969696",
	color7 = "#bcbcbc",
	color8 = "#c8c8c8",
}
local my_lualine_theme = {
	replace = {
		a = { fg = colors.color0, bg = colors.color1, gui = "bold" },
		b = { fg = colors.color2, bg = colors.color4 },
	},
	inactive = {
		a = { fg = colors.color6, bg = colors.color3, gui = "bold" },
		b = { fg = colors.color6, bg = colors.color4 },
		c = { fg = colors.color6, bg = "NONE" },
	},
	normal = {
		a = { fg = colors.color0, bg = colors.color7, gui = "bold" },
		b = { fg = colors.color2, bg = colors.color4 },
		c = { fg = colors.color2, bg = "NONE" },
	},
	visual = {
		a = { fg = colors.color0, bg = colors.color8, gui = "bold" },
		b = { fg = colors.color2, bg = colors.color4 },
	},
	insert = {
		a = { fg = colors.color0, bg = colors.color2, gui = "bold" },
		b = { fg = colors.color2, bg = colors.color4 },
	},
}

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

lualine.setup({
	options = {
		icons_enabled = true,
		globalstatus = true,
		theme = my_lualine_theme,
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
})
