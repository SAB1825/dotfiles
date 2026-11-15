# Sabari’s dotfiles

Arch Linux · niri · Kitty · Phoenix

A focused collection of desktop and terminal configuration.

| Directory | Configuration |
| --- | --- |
| [`config/nvim`](config/nvim/) | Neovim |
| [`config/Code - OSS`](config/Code%20-%20OSS/) | Code - OSS / VSCodium user settings |
| [`config/tmux`](config/tmux/) | tmux, plugins, and wallpaper palette helper |
| [`config/kitty`](config/kitty/) | Kitty appearance and transparency |
| [`config/niri`](config/niri/) | Niri compositor configuration |
| [`config/quickshell`](config/quickshell/) | Phoenix desktop shell |
| [`config/fastfetch`](config/fastfetch/) | Fastfetch layout and image |

The root [`.zshrc`](.zshrc) preserves the previous Zsh setup.
[`wallpapers/`](wallpapers/) contains the wallpaper collection.
Package lists and showcase assets are omitted for now.

## Setup

Back up existing configuration before copying or linking individual directories
from `config/` into `~/.config/`. Install the corresponding applications separately.

Editor settings are saved from `~/.config/Code - OSS/User/settings.json`. For
VSCodium installations using `~/.config/VSCodium/`, copy the saved `settings.json`
into that directory’s `User/` folder instead.

Initialize tmux plugin submodules after cloning:

```sh
git submodule update --init --recursive
```

tmux uses the backtick prefix. Some optional shortcuts need additional tools
such as sesh, fzf, gum, yazi, lazygit, and rmpc. The sessionizer shortcut expects
`~/scripts/tmux-sessionizer.sh`.

## Desktop integration

Phoenix's Quickshell source is included in `config/quickshell`. See its
[README](config/quickshell/README.md) for setup and validation instructions.
The previous `~/Rice/quickshell` path forwards to this directory, preserving
existing links at `~/.config/quickshell/main`.

The Niri configuration is included at `config/niri/config.kdl`; copy or link it
to `~/.config/niri/config.kdl`. Fish configuration has been removed.

Kitty retains 92% background opacity. The retained
Kitty configuration launches Zsh from `~/.config/zsh` when available, otherwise
Bash. For Zsh, copy the root
`.zshrc` to `~/.config/zsh/.zshrc` or adjust Kitty’s shell command.

tmux follows `~/.config/rice/palette.json` from the installed shell, with the old
Matugen palette as a fallback. Built-in fallback colors work without either file.
