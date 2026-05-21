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

# ── Bootstrap ────────────────────────────────────────────────────

# Package bundles per type. Add new packages here.
_pkgs_base := "hyprland hyprlock hypridle hyprpaper xdg-desktop-portal-hyprland " + \
              "waybar wofi swaync " + \
              "pipewire wireplumber pavucontrol libnotify " + \
              "kitty wezterm-git neovim zsh starship " + \
              "brightnessctl playerctl hyprshot " + \
              "jq curl " + \
              "adw-gtk-theme ttf-firacode-nerd " + \
              "stow just git " + \
              "udiskie exfatprogs"

_pkgs_production_extras := "firefox nautilus darktable opencode"
_pkgs_gaming_extras     := "steam"

# Resolve a type → space-separated package list
_pkgs-for type:
    #!/usr/bin/env bash
    case "{{type}}" in
        base)       echo "{{_pkgs_base}}";;
        production) echo "{{_pkgs_base}} {{_pkgs_production_extras}}";;
        gaming)     echo "{{_pkgs_base}} {{_pkgs_gaming_extras}}";;
        all)        echo "{{_pkgs_base}} {{_pkgs_production_extras}} {{_pkgs_gaming_extras}}";;
        *) echo "unknown type: {{type}}. Valid: base, production, gaming, all" >&2; exit 1;;
    esac

# Resolve a type → space-separated stow package list
_stow-for type:
    #!/usr/bin/env bash
    base="hypr waybar wofi kitty wezterm nvim zsh starship gtk udiskie backgrounds"
    case "{{type}}" in
        base|gaming)    echo "$base";;
        production|all) echo "$base gemini opencode";;
        *) echo "unknown type: {{type}}. Valid: base, production, gaming, all" >&2; exit 1;;
    esac

# Print resolved package list (used by CI to validate names)
install-deps-list type="base":
    @just _pkgs-for {{type}} | tr ' ' '\n'

# Validate the type, required commands, and gaming prerequisites before any
# install attempt. Fails fast with actionable error messages.
_preflight type:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{type}}" in
        base|production|gaming|all) ;;
        *) echo "ERROR: unknown type: {{type}}. Valid: base, production, gaming, all" >&2; exit 1;;
    esac
    missing=()
    for cmd in yay git stow; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    case "{{type}}" in
        production|all)
            command -v curl >/dev/null 2>&1 || missing+=("curl")
            ;;
    esac
    if [ "${#missing[@]}" -ne 0 ]; then
        echo "ERROR: required commands missing: ${missing[*]}" >&2
        echo "On Arch: 'sudo pacman -S --needed git base-devel stow curl', then build yay+just from AUR." >&2
        exit 1
    fi
    if [ ! -f "{{dotfiles}}/justfile" ]; then
        echo "ERROR: dotfiles repo not found at {{dotfiles}}/justfile" >&2
        exit 1
    fi
    case "{{type}}" in
        gaming|all)
            if ! grep -qE '^\[multilib\]' /etc/pacman.conf; then
                echo "ERROR: type={{type}} needs steam, which requires the multilib repo." >&2
                echo "Enable it: uncomment [multilib] in /etc/pacman.conf, then run 'sudo pacman -Syu'." >&2
                exit 1
            fi
            ;;
    esac
    echo "preflight: ok for type={{type}}"

# Install system packages for the given type
install-deps type="base":
    #!/usr/bin/env bash
    set -euo pipefail
    pkgs=$(just _pkgs-for {{type}})
    yay -S --needed $pkgs

# Detect host class (laptop|desktop) and symlink the matching host config variant
host-init:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{home}}/.config/hypr" "{{home}}/.config/waybar"
    if compgen -G "/sys/class/power_supply/BAT*" > /dev/null 2>&1; then
        profile=laptop
    else
        profile=desktop
    fi
    echo "host-init: detected profile=$profile"
    ln -sfn "{{dotfiles}}/hosts/hypr/host.conf.$profile"    "{{home}}/.config/hypr/host.conf"
    ln -sfn "{{dotfiles}}/hosts/waybar/host.jsonc.$profile" "{{home}}/.config/waybar/host.jsonc"
    echo "host-init: linked ~/.config/hypr/host.conf → host.conf.$profile"
    echo "host-init: linked ~/.config/waybar/host.jsonc → host.jsonc.$profile"

# Stow the stow packages relevant to the type
stow-all type="base":
    #!/usr/bin/env bash
    set -euo pipefail
    pkgs=$(just _stow-for {{type}})
    for p in $pkgs; do
        stow -d "{{dotfiles}}" -t "{{home}}" "$p"
    done
    echo "stowed: $pkgs"

# Install Claude Code CLI via the official installer if not already present
install-claude:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -x "{{home}}/.local/bin/claude" ]; then
        echo "install-claude: already installed at {{home}}/.local/bin/claude, skipping"
        exit 0
    fi
    echo "install-claude: running official installer (curl | bash)"
    curl -fsSL https://claude.ai/install.sh | bash

# Ensure firefox has a default-release profile by launching it briefly headless
firefox-profile-init:
    #!/usr/bin/env bash
    set -euo pipefail
    if compgen -G "$HOME/.mozilla/firefox/*.default-release" > /dev/null 2>&1; then
        echo "firefox-profile-init: profile already exists, skipping"
        exit 0
    fi
    if ! command -v firefox > /dev/null; then
        echo "firefox-profile-init: firefox not installed, skipping" >&2
        exit 0
    fi
    echo "firefox-profile-init: launching firefox --headless briefly to create profile"
    firefox --headless &
    pid=$!
    sleep 5
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true

# Full deploy for the given type
deploy-all type="base": host-init
    #!/usr/bin/env bash
    set -euo pipefail
    just stow-all {{type}}
    case "{{type}}" in
        production|all)
            just install-claude
            just claude-deploy
            just firefox-profile-init
            just firefox-deploy
            ;;
    esac

# First-time setup: preflight + install deps + deploy
bootstrap type="base": (_preflight type) (install-deps type) (deploy-all type)
    @echo ''
    @echo 'Bootstrap complete. Manual steps remaining:'
    @echo '  1. chsh -s $(which zsh)     # set zsh as default login shell'
    @echo '  2. Reload Hyprland (Super+Shift+C) to apply config'
    @echo '  3. Log out and back in once for GTK theme to fully apply'
    @echo '  4. Open a new shell so .zshrc loads (dots alias becomes available)'
    @echo '  5. sudo systemctl enable --now udisks2     # enable removable-media automount for udiskie'
