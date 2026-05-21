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

# stow-bundle linked the hypr package
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

# host-init linked the desktop variants (no BAT* in CI container)
assert_resolves_to "$HOME/.config/hypr/host.conf" \
    "$dotfiles/hosts/hypr/host.conf.desktop"
assert_resolves_to "$HOME/.config/waybar/host.jsonc" \
    "$dotfiles/hosts/waybar/host.jsonc.desktop"

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

# claude/ and guides/ must be excluded from stow-bundle
[ ! -L "$HOME/.config/claude" ] \
    || { echo "FAIL: claude/ got stowed"; exit 1; }
[ ! -e "$HOME/guides" ] \
    || { echo "FAIL: guides/ got stowed"; exit 1; }

# Production-only stow packages must NOT land for base
[ ! -e "$HOME/.config/opencode" ] \
    || { echo "FAIL: opencode/ stowed for base (should be production-only)"; exit 1; }
[ ! -e "$HOME/.config/gemini" ] \
    || { echo "FAIL: gemini/ stowed for base (should be production-only)"; exit 1; }

# install-claude must not have run for base (the $CI guard is verified in a
# dedicated workflow step; assert defensively here too)
[ ! -x "$HOME/.local/bin/claude" ] \
    || { echo "FAIL: claude binary present after base deploy"; exit 1; }

# claude-deploy must not have run for base
[ ! -e "$HOME/.claude/settings.json" ] \
    || { echo "FAIL: ~/.claude/settings.json present after base deploy"; exit 1; }

echo "all assertions passed"
