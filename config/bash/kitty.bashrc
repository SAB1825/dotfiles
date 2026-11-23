# Load the regular interactive Bash configuration before setting up the prompt.
if [[ -r ~/.bashrc ]]; then
    source ~/.bashrc
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
