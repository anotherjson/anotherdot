# Quicknotes

## nvim

```zsh
yay -Suy wget pyenv pyenv-virtualenv npm ripgrep fd-find fzf python-pip
npm install -g tree-sitter-cli
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init - zsh)"' >> ~/.zshrc
echo 'eval "$(pyenv virtualenv-init -)" >> ~/.zshrc
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zprofile
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zprofile
echo 'eval "$(pyenv init - zsh)"' >> ~/.zprofile
exec "$SHELL"
pyenv virtualenv neovim
```
