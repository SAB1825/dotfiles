# Sabari's dotfiles — Arch + niri + Phoenix

Selected configs are active through symlinks:

| Config | Active location |
| --- | --- |
| Kitty | `~/.config/kitty` |
| Neovim | `~/.config/nvim` |
| tmux | `~/.config/tmux` |
| Code - OSS | `~/.config/Code - OSS/User/settings.json` |
| Phoenix / Quickshell | `~/.config/quickshell/main` |
| Wallpaper collection | `~/Pictures/Wallpapers` |

Edits in this repository apply to the linked configs. Phoenix's source lives
in `config/quickshell`, linked at `~/.config/quickshell/main`. The old
`~/Rice/quickshell` path forwards to this directory for existing desktop links.
Niri's configuration is saved in `config/niri/config.kdl`; the active
`~/.config/niri/config.kdl` is an identical copy, not a symlink. Zsh and Fastfetch
are retained as source files and are not activated by this setup. Fish has been removed.

## Finish plugin downloads

The selected applications are installed. Run this from a normal terminal with
internet access to install the pinned tmux/Neovim plugins and the four Code themes,
icons and Vim extensions used by the settings:

```sh
bash ~/Rice/dotfiles/scripts/finish-setup.sh
```

The script reports failures and can be rerun. It does not install system packages,
push commits or start an extra desktop shell. It reloads Phoenix at the end.
Plugin/extension downloads cannot run in the restricted Codex environment.

## Kitty and wallpaper

- **Super+T** opens Kitty. Phoenix also uses Kitty for terminal applications.
- JetBrains Mono Nerd Font Mono, 12 pt, 92% opacity, 20 px padding, hidden tabs.
- Kitty starts the installed Bash shell and exports `EDITOR=nvim` / `VISUAL=nvim`.
- Colours follow Phoenix's wallpaper via `~/.local/state/ryu/kitty.conf`. The
  original `colors.conf` remains a fallback. Wallpaper changes regenerate the
  include and reload running Kitty windows with SIGUSR1; no remote-control socket
  is enabled.
- The wallpaper picker uses `~/Pictures/Wallpapers`. Your current wallpaper is
  preserved until you choose another image in **Super+S → General**.
- Old `rice-flat.conf` is unused; DarkShadow's Shell is not required.

## Neovim

The original Space leader, Moonfly theme, completion, file pickers, Git tools,
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
The palette helper now reads `~/.local/state/ryu/colors.json` first and updates
colours every five seconds. Old palette files remain fallback sources.

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

Kitty config parses and its generated colours match the current Phoenix palette.
Neovim starts headlessly with the installed 0.12 release; all Lua files parse.
Code settings are valid JSON and niri validates. Live tmux socket tests and live
Wayland reloads require your desktop terminal because those sockets are blocked
in the tool environment.
