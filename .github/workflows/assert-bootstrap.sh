#!/usr/bin/env bash
set -euo pipefail

dotfiles="$HOME/.dotfiles"

# Assert a path resolves (via any number of symlinks) to the expected target.
# Stow tree-folds at whichever level it can, so we can't pin the symlink
# location — but the fully-resolved path must match.
assert_resolves_to() {
    local link="$1" expected="$2"
    [ -e "$link" ] || { echo "FAIL: $link does not exist"; exit 1; }
    local actual canonical_expected
    actual="$(readlink -f "$link")"
    canonical_expected="$(readlink -f "$expected")"
    [ "$actual" = "$canonical_expected" ] || {
        echo "FAIL: $link"
        echo "  expected: $canonical_expected"
        echo "  actual:   $actual"
        exit 1
    }
}

# stow-all linked the hypr package
assert_resolves_to "$HOME/.config/hypr/hyprland.conf" \
    "$dotfiles/hypr/.config/hypr/hyprland.conf"

# swaync ships inside the hypr package
assert_resolves_to "$HOME/.config/swaync/config.json" \
    "$dotfiles/hypr/.config/swaync/config.json"

# kitty package
assert_resolves_to "$HOME/.config/kitty/kitty.conf" \
    "$dotfiles/kitty/.config/kitty/kitty.conf"

# waybar package (note: file is config.jsonc, not config)
assert_resolves_to "$HOME/.config/waybar/config.jsonc" \
    "$dotfiles/waybar/.config/waybar/config.jsonc"

# wofi package
assert_resolves_to "$HOME/.config/wofi/style.css" \
    "$dotfiles/wofi/.config/wofi/style.css"

# gtk package (gtk-3.0 settings.ini, gtk-4.0 gtk.css)
assert_resolves_to "$HOME/.config/gtk-3.0/settings.ini" \
    "$dotfiles/gtk/.config/gtk-3.0/settings.ini"
assert_resolves_to "$HOME/.config/gtk-4.0/gtk.css" \
    "$dotfiles/gtk/.config/gtk-4.0/gtk.css"

# starship package
assert_resolves_to "$HOME/.config/starship.toml" \
    "$dotfiles/starship/.config/starship.toml"

# zsh package (top-level dotfile)
assert_resolves_to "$HOME/.zshrc" "$dotfiles/zsh/.zshrc"

# claude-deploy is copy-based — files must exist and NOT be symlinks
[ -f "$HOME/.claude/settings.json" ] \
    || { echo "FAIL: ~/.claude/settings.json missing"; exit 1; }
[ ! -L "$HOME/.claude/settings.json" ] \
    || { echo "FAIL: ~/.claude/settings.json is a symlink (should be a copy)"; exit 1; }
cmp -s "$HOME/.claude/settings.json" "$dotfiles/claude/settings.json" \
    || { echo "FAIL: ~/.claude/settings.json content differs from repo"; exit 1; }
[ -f "$HOME/.claude/CLAUDE.md" ] \
    || { echo "FAIL: ~/.claude/CLAUDE.md missing"; exit 1; }

# claude/ and guides/ must be excluded from stow-all
[ ! -L "$HOME/.config/claude" ] \
    || { echo "FAIL: claude/ got stowed"; exit 1; }
[ ! -e "$HOME/guides" ] \
    || { echo "FAIL: guides/ got stowed"; exit 1; }

# firefox-deploy linked chrome/ into the fake profile
profile="$HOME/.mozilla/firefox/test.default-release"
[ -L "$profile/chrome" ] \
    || { echo "FAIL: $profile/chrome is not a symlink"; exit 1; }
target="$(readlink "$profile/chrome")"
[ "$target" = "$dotfiles/firefox/chrome" ] || {
    echo "FAIL: firefox chrome/ symlink"
    echo "  expected: $dotfiles/firefox/chrome"
    echo "  actual:   $target"
    exit 1
}

echo "all assertions passed"
