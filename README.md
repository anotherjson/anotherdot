# Base setup for a new computer
TODO: write up description

## Ubuntu setup
The goal of the ubuntu setup is to install zsh, wezterm, neovim, pyenv, and python.

We're going to want these anyway:
```bash
sudo apt install git wget curl
```

For [wezTerm](https://wezterm.org/installation.html):
```bash
sudo apt update
sudo apt install wezterm
```
Now open wezTerm.

For [zsh](https://www.zsh.org/):
`bash
sudo apt update
sudo apt install zsh
chsh -s /bin/zsh
exec "$SHELL"
`

For [omz](https://ohmyz.sh/#install):
```zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

If one happens to be on a macbook repurposed for linux:
```zsh
echo "options hid_apple fnmode=2" | sudo tee /etc/modprobe.d/hid_apple.conf
sudo update-initramfs -u
```

Install [pyenv](https://github.com/pyenv/pyenv):
```zsh
curl -fsSL https://pyenv.run | bash
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init - zsh)"' >> ~/.zshrc
echo 'eval "$(pyenv virtualenv-init -)" >> ~/.zshrc
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zprofile
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zprofile
echo 'eval "$(pyenv init - zsh)"' >> ~/.zprofile
exec "$SHELL"
sudo apt update; sudo apt install build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl git \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
```

Now install python3:
```zsh
pyenv install 3
pyenv global 3
```

Setup neovim virtualenv:
```zsh
pyenv virtualenv neovim
```

Install neovim basics:
```zsh
sudo apt install neovim
```

Install stow:
```zsh
sudo apt install stow
mkdir dotfiles
cd ~/dotfiles
cp ~/.zshrc .
mv ~/.zshrc ~/.zshrc.bak
stow .
```

That is the basic install.
