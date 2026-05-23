# Quicknotes

## nvim

The dotfiles' `.zshrc` and `.zprofile` already source pyenv if it's on
PATH (guarded by `command -v pyenv`), so just install pyenv plus the
support tools nvim needs, then re-source your shell:

```zsh
yay -Suy wget pyenv pyenv-virtualenv npm ripgrep fd fzf python-pip
npm install -g tree-sitter-cli
exec "$SHELL"
pyenv virtualenv neovim
```
