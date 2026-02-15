home := env("HOME")
dotfiles := home / ".dotfiles"
claude_live := home / ".claude"
claude_repo := dotfiles / "claude"

# ── Claude config (copy-based, not stow) ──────────────────────────

# Copy repo configs → ~/.claude/
claude-deploy:
    @mkdir -p "{{claude_live}}/agents"
    @cp "{{claude_repo}}/CLAUDE.md" "{{claude_live}}/CLAUDE.md"
    @cp "{{claude_repo}}/settings.json" "{{claude_live}}/settings.json"
    @cp "{{claude_repo}}/settings.local.json" "{{claude_live}}/settings.local.json"
    @cp "{{claude_repo}}/statusline-command.sh" "{{claude_live}}/statusline-command.sh"
    @cp "{{claude_repo}}"/agents/*.md "{{claude_live}}/agents/"
    @echo "claude config deployed to ~/.claude/"

# Copy ~/.claude/ configs → repo
claude-pull:
    @cp "{{claude_live}}/CLAUDE.md" "{{claude_repo}}/CLAUDE.md"
    @cp "{{claude_live}}/settings.json" "{{claude_repo}}/settings.json"
    @test -f "{{claude_live}}/settings.local.json" && cp "{{claude_live}}/settings.local.json" "{{claude_repo}}/settings.local.json" || true
    @cp "{{claude_live}}/statusline-command.sh" "{{claude_repo}}/statusline-command.sh"
    @cp "{{claude_live}}"/agents/*.md "{{claude_repo}}/agents/"
    @echo "claude config pulled into repo"

# Show full diff between repo and live configs
claude-diff:
    @diff -ru "{{claude_repo}}/CLAUDE.md" "{{claude_live}}/CLAUDE.md" || true
    @diff -ru "{{claude_repo}}/settings.json" "{{claude_live}}/settings.json" || true
    @diff -ru "{{claude_repo}}/settings.local.json" "{{claude_live}}/settings.local.json" 2>/dev/null || true
    @diff -ru "{{claude_repo}}/statusline-command.sh" "{{claude_live}}/statusline-command.sh" || true
    @diff -ru "{{claude_repo}}/agents" "{{claude_live}}/agents" || true

# Quick summary of what differs
claude-status:
    #!/usr/bin/env bash
    changed=0
    for f in CLAUDE.md settings.json settings.local.json statusline-command.sh; do
        if [ -f "{{claude_repo}}/$f" ] && [ -f "{{claude_live}}/$f" ]; then
            diff -q "{{claude_repo}}/$f" "{{claude_live}}/$f" > /dev/null 2>&1 || { echo "changed: $f"; changed=1; }
        elif [ -f "{{claude_repo}}/$f" ]; then
            echo "repo only: $f"; changed=1
        fi
    done
    agent_diff=$(diff -rq "{{claude_repo}}/agents" "{{claude_live}}/agents"  2>/dev/null) || true
    if [ -n "$agent_diff" ]; then
        echo "$agent_diff" | while read -r line; do echo "changed: agents/ — $line"; done
        changed=1
    fi
    [ "$changed" -eq 0 ] && echo "in sync" || true

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

# Full deploy: stow all packages + deploy claude config
deploy-all: stow-all claude-deploy
