#
# ~/.zlogin — sourced by zsh on login shells, after .zshrc
#

# Auto-launch Hyprland on TTY1 login. Restores the equivalent block from
# ~/.bash_profile, which became orphaned when the dotfiles bootstrap
# switched the login shell from bash to zsh (justfile chsh step). Gated
# on /dev/tty1 so it never fires in DM-launched sessions (pts), ssh
# sessions (pts), or other TTYs.
if [[ "$(tty)" == "/dev/tty1" ]]; then
    if command -v start-hyprland >/dev/null 2>&1; then
        exec start-hyprland
    elif command -v Hyprland >/dev/null 2>&1; then
        exec Hyprland
    fi
fi
