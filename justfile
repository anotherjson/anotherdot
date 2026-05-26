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
    profile=$(find ~/.mozilla/firefox -maxdepth 1 -name "*.default-release" -type d 2>/dev/null | head -1)
    if [ -z "$profile" ]; then
        echo "firefox-deploy: no default-release profile found in ~/.mozilla/firefox/."
        echo "  Launch firefox once interactively (from Hyprland) to seed a profile,"
        echo "  then re-run: 'just firefox-deploy'."
        echo "  Skipping for now — bootstrap can continue."
        exit 0
    fi
    ln -sfn "{{dotfiles}}/firefox/chrome" "$profile/chrome"
    echo "firefox chrome/ linked to $profile/chrome"

# ── Stow wrappers ─────────────────────────────────────────────────

# Stow a single package (auto-runs host-init for hypr/waybar)
stow package:
    #!/usr/bin/env bash
    set -euo pipefail
    stow -d "{{dotfiles}}" -t "{{home}}" {{package}}
    case "{{package}}" in
        hypr|waybar) just host-init ;;
    esac

# Unstow a single package
unstow package:
    stow -d "{{dotfiles}}" -t "{{home}}" -D {{package}}

# Restow a package: unstow + stow (auto-runs host-init for hypr/waybar)
restow package:
    #!/usr/bin/env bash
    set -euo pipefail
    stow -d "{{dotfiles}}" -t "{{home}}" -R {{package}}
    case "{{package}}" in
        hypr|waybar) just host-init ;;
    esac

# ── Bootstrap ────────────────────────────────────────────────────

# git/just/yay must be installed manually before `just bootstrap` can
# start (see _preflight). stow is pulled in by install-deps. These
# tools are also listed in _pkgs_base so subsequent runs keep them
# updated via yay -S --needed.
# Package bundles per type. Add new packages here.
_pkgs_base := "hyprland hyprlock hypridle hyprpaper xdg-desktop-portal-hyprland " + \
              "waybar wofi swaync " + \
              "pipewire wireplumber pavucontrol libnotify " + \
              "easyeffects lsp-plugins-lv2 " + \
              "kitty wezterm-git neovim zsh starship " + \
              "brightnessctl playerctl hyprshot " + \
              "eza jq curl arch-update " + \
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

# Print resolved package list (used by CI to validate names)
install-deps-list type="base":
    @just _pkgs-for {{type}} | tr ' ' '\n'

# Validate the type, required commands, and gaming prerequisites before any
# install attempt. Fails fast with actionable error messages.
_preflight type:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{type}}" in
        type=*)
            echo "ERROR: 'type=...' is just's variable-override syntax, not a recipe argument." >&2
            echo "Use positional form: just bootstrap <base|production|gaming|all>" >&2
            exit 1;;
        base|production|gaming|all) ;;
        *)
            echo "ERROR: unknown type: {{type}}. Valid: base, production, gaming, all" >&2
            echo "  e.g. just bootstrap production" >&2
            exit 1;;
    esac
    missing=()
    for cmd in yay git; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    case "{{type}}" in
        production|all)
            command -v curl >/dev/null 2>&1 || missing+=("curl")
            ;;
    esac
    if [ "${#missing[@]}" -ne 0 ]; then
        echo "ERROR: required commands missing: ${missing[*]}" >&2
        echo "Prerequisites (per README): git, just, yay. For production|all also: curl." >&2
        echo "yay itself is built from AUR and needs git + base-devel; once yay is in place" >&2
        echo "it can install everything else, including stow (pulled in by 'just install-deps')." >&2
        exit 1
    fi
    if [ ! -f "{{dotfiles}}/justfile" ]; then
        echo "ERROR: dotfiles repo not found at {{dotfiles}}/justfile" >&2
        exit 1
    fi
    case "{{type}}" in
        gaming|all)
            if ! grep -qE '^\[multilib\]' /etc/pacman.conf; then
                echo "ERROR: the '{{type}}' bundle installs steam, which requires the multilib repo." >&2
                echo "Enable it: uncomment [multilib] and its Include line in /etc/pacman.conf," >&2
                echo "then refresh: 'sudo pacman -Sy'." >&2
                exit 1
            fi
            ;;
    esac
    echo "preflight: ok for type={{type}}"

# Install system packages for the given type
install-deps type="base": (_preflight type)
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{type}}" in
        base)       pkgs="{{_pkgs_base}}";;
        production) pkgs="{{_pkgs_base}} {{_pkgs_production_extras}}";;
        gaming)     pkgs="{{_pkgs_base}} {{_pkgs_gaming_extras}}";;
        all)        pkgs="{{_pkgs_base}} {{_pkgs_production_extras}} {{_pkgs_gaming_extras}}";;
        *) echo "unknown type: {{type}}. Valid: base, production, gaming, all" >&2; exit 1;;
    esac
    read -ra pkg_arr <<<"$pkgs"
    yay -S --needed "${pkg_arr[@]}"

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
stow-bundle type="base":
    #!/usr/bin/env bash
    set -euo pipefail
    base="hypr waybar wofi kitty wezterm nvim zsh starship gtk udiskie backgrounds easyeffects wireplumber"
    case "{{type}}" in
        base|gaming)    pkgs="$base";;
        production|all) pkgs="$base gemini opencode";;
        *) echo "unknown type: {{type}}. Valid: base, production, gaming, all" >&2; exit 1;;
    esac
    read -ra pkg_arr <<<"$pkgs"
    for p in "${pkg_arr[@]}"; do
        stow -d "{{dotfiles}}" -t "{{home}}" "$p"
    done
    echo "stowed: $pkgs"

# Install Claude Code CLI via the official installer if not already present
install-claude:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "${CI:-}" = "true" ]; then
        echo "install-claude: CI detected, skipping"
        exit 0
    fi
    if [ -x "{{home}}/.local/bin/claude" ]; then
        echo "install-claude: already installed at {{home}}/.local/bin/claude, skipping"
        exit 0
    fi
    echo "install-claude: running official installer (curl | bash)"
    curl -fsSL https://claude.ai/install.sh | bash

# Full deploy for the given type
deploy type="base": (_preflight type)
    #!/usr/bin/env bash
    set -euo pipefail
    just stow-bundle {{type}}
    just host-init
    case "{{type}}" in
        production|all)
            just install-claude
            just claude-deploy
            just firefox-deploy
            ;;
    esac

# Enable TTY1 autologin so Hyprland can launch directly via ~/.zlogin
# without a TTY login prompt. Skipped if a display manager is already
# enabled (sddm/gdm/greetd/ly/lightdm) — DM handles the boot path and
# autologin would race with it.
enable-tty-autologin:
    #!/usr/bin/env bash
    set -euo pipefail
    if systemctl list-unit-files --state=enabled 2>/dev/null \
        | grep -iqE '^(sddm|gdm|greetd|ly|lightdm)\.service'; then
        echo "enable-tty-autologin: display manager is enabled, skipping autologin override."
        exit 0
    fi
    user="${SUDO_USER:-$USER}"
    if [[ "$user" == "root" ]]; then
        echo "ERROR: refusing to configure root autologin." >&2
        echo "  Run as a regular user without sudo: 'just bootstrap'." >&2
        exit 1
    fi
    echo "enable-tty-autologin: configuring TTY1 autologin for user=$user"
    override_dir=/etc/systemd/system/getty@tty1.service.d
    override_file="$override_dir/autologin.conf"
    sudo mkdir -p "$override_dir"
    sudo tee "$override_file" > /dev/null <<EOF
    [Service]
    ExecStart=
    ExecStart=-/usr/bin/agetty --autologin $user --noclear %I \$TERM
    EOF
    sudo systemctl daemon-reload
    echo "enable-tty-autologin: wrote $override_file"

# Drop in `sshd_config.d/99-dotfiles-hardening.conf` to disable password
# auth and root password login. Skipped if sshd is neither enabled nor
# active (no point hardening a service that isn't running). Uses a
# drop-in so pacman updates to /etc/ssh/sshd_config don't clobber it.
harden-sshd:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! systemctl is-enabled sshd >/dev/null 2>&1 \
        && ! systemctl is-active sshd >/dev/null 2>&1; then
        echo "harden-sshd: sshd not enabled or active, skipping."
        exit 0
    fi
    drop=/etc/ssh/sshd_config.d/99-dotfiles-hardening.conf
    sudo mkdir -p /etc/ssh/sshd_config.d
    tmp=$(sudo mktemp --suffix=.conf /etc/ssh/sshd_config.d/99-dotfiles-hardening.XXXXXX)
    sudo tee "$tmp" > /dev/null <<EOF
    # Managed by anotherdot dotfiles (justfile harden-sshd recipe).
    PasswordAuthentication no
    PermitRootLogin prohibit-password
    EOF
    if ! sudo sshd -t; then
        echo "harden-sshd: sshd -t failed; rolling back tempfile." >&2
        sudo rm -f "$tmp"
        exit 1
    fi
    sudo mv "$tmp" "$drop"
    sudo systemctl reload sshd 2>/dev/null || {
        echo "harden-sshd: reload failed, restarting sshd — active ssh sessions may drop" >&2
        sudo systemctl restart sshd
    }
    echo "harden-sshd: wrote $drop, sshd reloaded"

# First-time setup. Runs preflight → install-deps → deploy, then
# system-level activation: chsh to zsh, enable udisks2, configure TTY1
# autologin (no-DM hosts), harden sshd (if active). sudo cache is primed
# at start and refreshed after install-deps to minimize prompts.
bootstrap type="base": (_preflight type) (install-deps type) (deploy type)
    @echo ''
    @echo 'Priming sudo cache (you may be prompted once)...'
    @sudo -v
    @echo 'Setting login shell to zsh...'
    @sudo chsh -s "$(command -v zsh)" "$USER"
    @echo 'Refreshing sudo cache after long-running install-deps...'
    @sudo -v
    @echo 'Enabling udisks2 (system service that udiskie listens to for automount)...'
    @sudo systemctl enable --now udisks2
    @just enable-tty-autologin
    @just harden-sshd
    @echo ''
    @echo 'Bootstrap complete.'
    @echo ''
    @echo 'Behavior changes that take effect on next session/reboot:'
    @echo '  - login shell is now zsh (active on next login)'
    @echo '  - on no-DM hosts: TTY1 auto-logs you in and Hyprland starts at boot'
    @echo '  - if sshd was active: password auth and root password login are now disabled'
    @echo '  - udisks2 is enabled (udiskie automount tray works)'
    @echo ''
    @echo 'Manual steps remaining:'
    @echo '  1. Restart your session (log out + back in, or reboot) to apply all configs'
    @echo '  2. (production|all only) launch firefox once from Hyprland, then `just firefox-deploy` to install userChrome'
