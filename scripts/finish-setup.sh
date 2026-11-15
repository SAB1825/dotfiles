#!/usr/bin/env bash
# Run from a normal terminal: network access is needed for editor/tmux plugins.
set -uo pipefail
dotfiles_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
failed=0
git -C "$dotfiles_dir" submodule sync || failed=1
git -C "$dotfiles_dir" submodule update --init \
    config/tmux/.tmux/plugins/tpm \
    config/tmux/.tmux/plugins/vim-tmux-navigator \
    config/tmux/.tmux/plugins/tmux-resurrect \
    config/tmux/.tmux/plugins/tmux-continuum \
    config/tmux/.tmux/plugins/tmux-sessionx || failed=1
nvim --headless -u NONE -l "$dotfiles_dir/config/nvim/scripts/bootstrap.lua" || failed=1
for extension in zhuangtongfa.material-theme PKief.material-icon-theme PKief.material-product-icons vscodevim.vim; do
    code --install-extension "$extension" || failed=1
done
fc-cache -f
ryuctl reload || true
ryuctl call wallpaper setFolder "$HOME/Pictures/Wallpapers" || true
if [[ $failed == 0 ]]; then
    printf '\nPlugins and Code extensions installed. Open Kitty with Super+T.\n'
else
    printf '\nSome downloads failed. Check the messages above and rerun this script.\n' >&2
fi
exit "$failed"
