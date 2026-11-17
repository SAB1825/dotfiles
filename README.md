# Sabari's dotfiles — Arch + niri + DankMaterialShell

Selected configs are active through symlinks:

| Config | Active location |
| --- | --- |
| Alacritty | `~/.config/alacritty` |
| Kitty | `~/.config/kitty` |
| Niri | `~/.config/niri/config.kdl` |
| Neovim | `~/.config/nvim` |
| tmux | `~/.config/tmux` |
| Code - OSS | `~/.config/Code - OSS/User/settings.json` |
| Phoenix / Quickshell | `~/.config/quickshell/main` |
| Wallpaper collection | `~/Pictures/Wallpapers` |

Edits in this repository apply to the linked configs. Alacritty's active
symlink points to `config/alacritty`; its previous config remains in
`~/.config.tapes/alacritty`. It uses FiraCode Nerd Font Mono at 14 pt,
10 px padding, and imports the included DMS-generated `dank-theme.toml`.

DankMaterialShell settings and installed plugins are kept as a snapshot in
`config/dms`. See [the DMS README](config/dms/README.md) for restore instructions.
Zsh and Fastfetch are retained as source files and are not activated by this setup.

## Plugin downloads

The selected applications are installed. Run this from a normal terminal with
internet access to install the pinned Neovim plugins:

```sh
nvim --headless -u NONE -l ~/Rice/dotfiles/config/nvim/scripts/bootstrap.lua
```

Initialize tmux plugins with `git submodule update --init` from this repository.
Code OSS uses the `zhuangtongfa.material-theme`, `PKief.material-icon-theme`,
`PKief.material-product-icons`, and `vscodevim.vim` extensions, which can be
installed through its Extensions view.

## Desktop and Kitty

DankMaterialShell provides the desktop shell. Its snapshot includes the current
bar layout, theme settings, plugins, and generated Firefox styling.

**Super+T** opens Kitty. Kitty uses 40% background opacity and imports its
DMS-generated theme and tab styling. Niri's window rules and keybindings live
in `config/niri/config.kdl`. Wallpapers are stored in `wallpapers`.

## Neovim

The original Space leader, transparent No Clown Fiesta theme, completion, file pickers, Git tools,
formatters and diagnostics are preserved. Neovim 0.12's native `vim.pack` installs
plugins using `nvim-pack-lock.json`. Before plugins are downloaded, Neovim still
opens with core settings and a built-in theme, displaying a setup reminder.

Qt tools resolve to `/usr/lib/qt6/bin/qmlls` and `qmlformat` on this Arch install.
Treesitter includes Lua/Rust and the original web, Go, QML and Markdown parsers.
If the tmux navigator plugin is installed, Neovim also loads it for pane switching.

On first normal launch, Treesitter downloads its parsers. Use `:Mason` to install
language servers/formatters you want: `lua-language-server`, `marksman`, `gopls`,
`rust-analyzer` and `stylua`. Qt tools are supplied by the installed Qt packages.
`:ConformInfo` and `:checkhealth vim.lsp` show formatter/server availability.

See [the Neovim README](config/nvim/README.md) for keybindings.

## tmux

The prefix is **backtick (`)**. The original pane bindings and status layout stay.
The status line, pane borders, and popups use a fixed black-and-white palette.

- Prefix + `|` / `-`: split horizontally / vertically.
- Prefix + `r`: reload config.
- Prefix + `f`: project/session picker; without fzf, opens native session selection.
- Prefix + `Ctrl+t`: Bash popup.
- Prefix + `D`: edit Bash, Kitty, tmux, Neovim or niri config.
- Clipboard copies use `wl-copy` under Wayland.

Optional original shortcuts need **sesh, gum, fzf, fd, yazi, lazygit or rmpc**.
They are not needed to start tmux. Only plugins actually referenced by this
configuration are initialized; old CPU/battery/online-status/Catppuccin submodules
are not downloaded. Restore stays manual; automatic session restore remains off.

## Code - OSS

The original compact layout, 16 px JetBrains Nerd Font, One Dark Pro Night Flat,
material icons, Vim key handling and editing preferences are retained. Integrated
terminals use Bash and JetBrains Mono; external terminals use Kitty. The finish
script installs the matching themes/icons/Vim extensions from Code's configured
Open VSX registry. Restart Code after installation if a theme has not activated.

## Validation

Parse Alacritty's TOML files and DMS's JSON files after editing. Neovim uses
0.12's native package manager; see its README for setup and keybindings.
Validate compositor changes with `niri validate` before reloading the desktop.
