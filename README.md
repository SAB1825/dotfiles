# Sabari’s dotfiles

A monochrome Arch Linux desktop with niri, a custom Quickshell shell, and a terminal-based workflow.

[![Arch Linux desktop showing Fastfetch with a custom Gojo image](assets/fastfetch.jpg)](assets/fastfetch.jpg)

## Desktop showcase

https://github.com/user-attachments/assets/89ebb0ff-aa4c-4569-a52f-0d469fe39800

[Download the Quickshell showcase (MP4)](assets/quickshell_showcase.mp4)

The Quickshell island brings together niri workspaces, an app launcher, clipboard history, a dashboard, notifications, connectivity controls, and a wallpaper picker.

[![Neovim and tmux with split panes and a monochrome status line](assets/tmux%26nvim.jpg)](assets/tmux%26nvim.jpg)

Neovim and tmux share a transparent, monochrome setup.

## The setup

| Component | Config |
| --- | --- |
| Compositor | [niri](config/niri/config.kdl) |
| Desktop shell | [Quickshell](config/quickshell/shell.qml) |
| Terminals | [Kitty](config/kitty/) · [Alacritty](config/alacritty/) |
| Editor | [Neovim](config/nvim/) · [Code - OSS](config/Code%20-%20OSS/User/settings.json) |
| Multiplexer | [tmux](config/tmux/) |
| System info | [Fastfetch](config/fastfetch/) |
| Wallpapers | [Collection](wallpapers/) |

## Setup notes

These are personal configs, with selected files linked into `~/.config`.
Back up your existing configs and review paths before linking or copying them.
Changes to linked files apply directly to the active setup.

- **Desktop:** link the niri and Quickshell config directories into `~/.config`. niri starts Quickshell from its default config location. Check niri changes with `niri validate`.
- **Neovim:** requires Neovim 0.12 for native `vim.pack` support. See the [editor guide](config/nvim/README.md) for mappings and tools.
- **tmux:** run `git submodule update --init` from this repository to initialize plugins.
- **Code - OSS:** install One Dark Pro, Material Icon Theme, Material Product Icons, and Vim from the Extensions view.
- **Zsh and Fastfetch:** included as source configs; activation is manual.

Install the pinned Neovim plugins from the repository root:

```sh
nvim --headless -u NONE -l config/nvim/scripts/bootstrap.lua
```

Treesitter installs parsers on first launch. Use `:Mason` to install language
servers and formatters; Qt’s `qmlls` and `qmlformat` are installed separately.

<details>
<summary>Everyday shortcuts</summary>


| Keys | Action |
| --- | --- |
| `Super + Enter` | Open Kitty |
| `Super + Space` | Toggle the app launcher |
| `Super + V` | Toggle clipboard history |
| `Super + W` | Toggle the wallpaper picker |
| `Super + Shift + N` | Toggle focus mode |
| `Space` in Neovim | Leader key |
| Backtick in tmux | Prefix key |
| Prefix + `\|` / `-` | Split tmux panes |
| Prefix + `r` | Reload tmux config |
| Prefix + `f` | Project / session picker |
| Prefix + `Ctrl + t` | Bash popup |

Tmux clipboard integration uses `wl-copy`. Extra pickers and shortcuts may need
`sesh`, `gum`, `fzf`, `fd`, `yazi`, `lazygit`, or `rmpc`.

</details>
