#!/usr/bin/env bash
set -o nounset -o pipefail

# Claude Code statusline — parses JSON, exports env vars, renders via Starship

cwd=""

payload="$(cat || true)"
if command -v jq >/dev/null 2>&1 && [[ -n "$payload" ]]; then
    # Parse all JSON fields in a single jq call
    IFS=$'\x1f' read -r cwd model_id ctx_pct ctx_size cost_usd session_name rate_5h < <(
        printf '%s' "$payload" | jq -r '[
            (.workspace.current_dir // .cwd // ""),
            (.model.id // ""),
            (.context_window.used_percentage // ""),
            (.context_window.context_window_size // ""),
            (.cost.total_cost_usd // ""),
            (.session_name // ""),
            (.rate_limits.five_hour.used_percentage // "")
        ] | join("\u001f")' 2>/dev/null
    ) || true

    # Model icon (Nerd Font) + context window size
    ctx_label=""
    if [[ -n "${ctx_size:-}" ]]; then
        if (( ctx_size >= 1000000 )); then
            ctx_label="$(( ctx_size / 1000000 ))M"
        else
            ctx_label="$(( ctx_size / 1000 ))k"
        fi
    fi

    case "${model_id:-}" in
        *opus*)   export CLAUDE_MODEL_ICON="o${ctx_label:+:$ctx_label}" ;;
        *sonnet*) export CLAUDE_MODEL_ICON="s${ctx_label:+:$ctx_label}" ;;
        *haiku*)  export CLAUDE_MODEL_ICON="h${ctx_label:+:$ctx_label}" ;;
        *)        export CLAUDE_MODEL_ICON="${model_id:-}${ctx_label:+:$ctx_label}" ;;
    esac

    # Context % — export to exactly one color-coded variable
    unset CLAUDE_CTX_GREEN CLAUDE_CTX_YELLOW CLAUDE_CTX_RED
    if [[ -n "${ctx_pct:-}" ]]; then
        pct=${ctx_pct%.*}
        if (( pct >= 60 )); then
            export CLAUDE_CTX_RED="$pct"
        elif (( pct >= 40 )); then
            export CLAUDE_CTX_YELLOW="$pct"
        else
            export CLAUDE_CTX_GREEN="$pct"
        fi
    fi

    # Rate limit (5hr)
    unset CLAUDE_RATE
    [[ -n "${rate_5h:-}" ]] && export CLAUDE_RATE="${rate_5h%.*}"

    # Session cost
    unset CLAUDE_COST
    if [[ -n "${cost_usd:-}" && "${cost_usd:-}" != "0" ]]; then
        export CLAUDE_COST=$(printf '$%.2f' "$cost_usd")
    fi

    # Session name
    unset CLAUDE_SESSION
    [[ -n "${session_name:-}" ]] && export CLAUDE_SESSION="$session_name"
fi

# Fast path: use $COLUMNS if Claude Code exports it
if [[ -n "${COLUMNS:-}" ]] && (( COLUMNS > 0 )); then
    term_width=$((COLUMNS - 6))
else
    # Subprocess has no TTY — detect width from parent process TTY
    term_width=120
    parent_tty=$(ps -o tty= -p "$(ps -o ppid= -p $$)" 2>/dev/null) || true
    parent_tty="${parent_tty// /}"
    if [[ -n "$parent_tty" && "$parent_tty" != "??" && "$parent_tty" != "?" ]]; then
        read -r _ w < <(stty size < "/dev/$parent_tty" 2>/dev/null) || true
        if [[ -n "${w:-}" ]] && (( w > 0 )); then
            term_width=$((w - 6))
        fi
    fi
fi

# Render with Starship — always runs, even if parsing failed
cd "${cwd:-}" 2>/dev/null || true
STARSHIP_CONFIG="$HOME/.claude/starship.toml" STARSHIP_SHELL=sh starship prompt -w "$term_width"
