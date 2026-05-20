home := env("HOME")
dotfiles := home / ".dotfiles"
claude_live := home / ".claude"
claude_repo := dotfiles / "claude"

# ── Claude config (copy-based, not stow) ──────────────────────────

# Copy repo configs → ~/.claude/
claude-deploy:
    @mkdir -p "{{claude_live}}/agents" "{{claude_live}}/hooks" "{{claude_live}}/skills"
    @cp "{{claude_repo}}/CLAUDE.md" "{{claude_live}}/CLAUDE.md"
    @cp "{{claude_repo}}/settings.json" "{{claude_live}}/settings.json"
    @cp "{{claude_repo}}/settings.local.json" "{{claude_live}}/settings.local.json"
    @cp "{{claude_repo}}/statusline-command.sh" "{{claude_live}}/statusline-command.sh"
    @cp "{{claude_repo}}/starship.toml" "{{claude_live}}/starship.toml"
    @cp "{{claude_repo}}"/agents/*.md "{{claude_live}}/agents/"
    @cp "{{claude_repo}}"/hooks/*.sh "{{claude_live}}/hooks/"
    @cp -r "{{claude_repo}}"/skills/* "{{claude_live}}/skills/"
    @echo "claude config deployed to ~/.claude/"

# Copy ~/.claude/ configs → repo
claude-pull:
    @cp "{{claude_live}}/CLAUDE.md" "{{claude_repo}}/CLAUDE.md"
    @cp "{{claude_live}}/settings.json" "{{claude_repo}}/settings.json"
    @test -f "{{claude_live}}/settings.local.json" && cp "{{claude_live}}/settings.local.json" "{{claude_repo}}/settings.local.json" || true
    @cp "{{claude_live}}/statusline-command.sh" "{{claude_repo}}/statusline-command.sh"
    @cp "{{claude_live}}/starship.toml" "{{claude_repo}}/starship.toml"
    @cp "{{claude_live}}"/agents/*.md "{{claude_repo}}/agents/"
    @test -d "{{claude_live}}/hooks" && cp "{{claude_live}}"/hooks/*.sh "{{claude_repo}}/hooks/" || true
    @test -d "{{claude_live}}/skills" && cp -r "{{claude_live}}"/skills/* "{{claude_repo}}/skills/" || true
    @echo "claude config pulled into repo"

# Show full diff between repo and live configs
claude-diff:
    @diff -ru "{{claude_repo}}/CLAUDE.md" "{{claude_live}}/CLAUDE.md" || true
    @diff -ru "{{claude_repo}}/settings.json" "{{claude_live}}/settings.json" || true
    @diff -ru "{{claude_repo}}/settings.local.json" "{{claude_live}}/settings.local.json" 2>/dev/null || true
    @diff -ru "{{claude_repo}}/statusline-command.sh" "{{claude_live}}/statusline-command.sh" || true
    @diff -ru "{{claude_repo}}/starship.toml" "{{claude_live}}/starship.toml" || true
    @diff -ru "{{claude_repo}}/agents" "{{claude_live}}/agents" || true
    @diff -ru "{{claude_repo}}/hooks" "{{claude_live}}/hooks" 2>/dev/null || true
    @diff -ru "{{claude_repo}}/skills" "{{claude_live}}/skills" 2>/dev/null || true

# Quick summary of what differs
claude-status:
    #!/usr/bin/env bash
    changed=0
    for f in CLAUDE.md settings.json settings.local.json statusline-command.sh starship.toml; do
        if [ -f "{{claude_repo}}/$f" ] && [ -f "{{claude_live}}/$f" ]; then
            diff -q "{{claude_repo}}/$f" "{{claude_live}}/$f" > /dev/null 2>&1 || { echo "changed: $f"; changed=1; }
        elif [ -f "{{claude_repo}}/$f" ]; then
            echo "repo only: $f"; changed=1
        fi
    done
    agent_diff=$(diff -rq "{{claude_repo}}/agents" "{{claude_live}}/agents" 2>/dev/null) || true
    if [ -n "$agent_diff" ]; then
        echo "$agent_diff" | while read -r line; do echo "changed: agents/ — $line"; done
        changed=1
    fi
    hooks_diff=$(diff -rq "{{claude_repo}}/hooks" "{{claude_live}}/hooks" 2>/dev/null) || true
    if [ -n "$hooks_diff" ]; then
        echo "$hooks_diff" | while read -r line; do echo "changed: hooks/ — $line"; done
        changed=1
    fi
    skills_diff=$(diff -rq "{{claude_repo}}/skills" "{{claude_live}}/skills" 2>/dev/null) || true
    if [ -n "$skills_diff" ]; then
        echo "$skills_diff" | while read -r line; do echo "changed: skills/ — $line"; done
        changed=1
    fi
    [ "$changed" -eq 0 ] && echo "in sync" || true

# ── Firefox config (symlink-based, not stow) ─────────────────────

# Link firefox/chrome/ into the active Firefox profile
firefox-deploy:
    #!/usr/bin/env bash
    profile=$(find ~/.mozilla/firefox -maxdepth 1 -name "*.default-release" -type d | head -1)
    if [ -z "$profile" ]; then echo "no firefox profile found"; exit 1; fi
    ln -sfn "{{dotfiles}}/firefox/chrome" "$profile/chrome"
    echo "firefox chrome/ linked to $profile/chrome"

# ── Stow wrappers ─────────────────────────────────────────────────

# Stow a single package
stow package:
    stow -d "{{dotfiles}}" -t "{{home}}" {{package}}

# Unstow a single package
unstow package:
    stow -d "{{dotfiles}}" -t "{{home}}" -D {{package}}

# Restow a package (unstow + stow)
restow package:
    stow -d "{{dotfiles}}" -t "{{home}}" -R {{package}}

# Stow all packages (skips claude, guides, .git)
stow-all:
    #!/usr/bin/env bash
    for pkg in "{{dotfiles}}"/*/; do
        name=$(basename "$pkg")
        case "$name" in claude|guides|.git) continue ;; esac
        stow -d "{{dotfiles}}" -t "{{home}}" "$name"
    done
    echo "all packages stowed"

# Full deploy: stow all packages + deploy claude + firefox config
deploy-all: stow-all claude-deploy firefox-deploy

# ── Bootstrap ────────────────────────────────────────────────────

# Single source of truth for system packages. Add new ones here.
_pkgs := "hyprland hyprlock hypridle hyprpaper xdg-desktop-portal-hyprland " + \
         "waybar wofi swaync " + \
         "pipewire wireplumber pavucontrol libnotify " + \
         "kitty wezterm-git neovim zsh starship " + \
         "brightnessctl playerctl hyprshot " + \
         "jq curl " + \
         "adw-gtk-theme ttf-firacode-nerd " + \
         "stow just git " + \
         "udiskie exfatprogs nautilus " + \
         "darktable " + \
         "opencode"

# Print the package list, one per line (used by CI to validate names)
install-deps-list:
    @echo {{_pkgs}} | tr ' ' '\n'

# Install all system packages this repo configures or references
install-deps:
    yay -S --needed {{_pkgs}}

# First-time setup: install deps + stow + special-case deploys
bootstrap: install-deps deploy-all
    @echo ''
    @echo 'Bootstrap complete. Manual steps remaining:'
    @echo '  1. chsh -s $(which zsh)     # set zsh as default login shell'
    @echo '  2. Reload Hyprland (Super+Shift+C) to apply config'
    @echo '  3. Log out and back in once for GTK theme to fully apply'
    @echo '  4. Open a new shell so .zshrc loads (dots alias becomes available)'
    @echo '  5. sudo systemctl enable --now udisks2     # enable removable-media automount for udiskie'
