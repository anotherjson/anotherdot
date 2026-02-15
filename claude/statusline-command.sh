#!/usr/bin/env bash
# Claude Code status line — mirrors the solarized_osaka Starship prompt

# Solarized Osaka palette (ANSI true-color)
FG='\033[38;2;253;246;227m'          # color_fg  #FDF6E3
PURPLE='\033[38;2;204;207;255m'      # color_purple #CCCFFF
BLUE='\033[38;2;170;220;255m'        # color_blue #AADCFF
BLUE_ITALIC='\033[3;38;2;73;174;245m' # color_blue300 italic
GREEN='\033[38;2;214;255;172m'       # color_green #D6FFAC
YELLOW='\033[38;2;255;233;153m'      # color_yellow #FFE999
CYAN='\033[38;2;185;255;250m'        # color_aqua #B9FFFA
RED='\033[38;2;255;157;155m'         # color_red #FF9D9B
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
RESET='\033[0m'

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
session_name=$(echo "$input" | jq -r '.session_name // empty')

# Shorten home directory to ⌂
home_dir="$HOME"
display_dir="${cwd/#$home_dir/⌂}"

# OS icon (Arch Linux)
os_icon=" "

# Username
user=$(whoami)

# Git info (skip optional locks to avoid blocking)
git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" -c gc.auto=0 symbolic-ref --short HEAD 2>/dev/null \
             || git -C "$cwd" -c gc.auto=0 rev-parse --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        # Check for modifications/untracked
        git_flags=""
        status_output=$(git -C "$cwd" -c gc.auto=0 status --porcelain 2>/dev/null)
        modified=$(echo "$status_output" | grep -c '^ M\|^M ' 2>/dev/null || true)
        untracked=$(echo "$status_output" | grep -c '^??' 2>/dev/null || true)
        staged=$(echo "$status_output" | grep -c '^[MADRC]' 2>/dev/null || true)
        [ "$modified" -gt 0 ]  && git_flags="${git_flags}●◦"
        [ "$untracked" -gt 0 ] && git_flags="${git_flags}◌◦"
        [ "$staged" -gt 0 ]    && git_flags="${git_flags}▪┤${staged}│"

        git_branch_str="${BLUE_ITALIC}${ITALIC}  ${branch}${RESET}"
        if [ -n "$git_flags" ]; then
            git_info="${git_branch_str} ${BOLD}${BLUE}⎪${git_flags}⎥${RESET}"
        else
            git_info="${git_branch_str}"
        fi
    fi
fi

# Context window
ctx_info=""
if [ -n "$used_pct" ]; then
    used_int=${used_pct%.*}
    if [ "$used_int" -ge 80 ]; then
        ctx_color="$RED"
    elif [ "$used_int" -ge 50 ]; then
        ctx_color="$YELLOW"
    else
        ctx_color="$GREEN"
    fi
    ctx_info=" ${DIM}${ctx_color}ctx:${used_int}%${RESET}"
fi

# Model name
model_str=""
if [ -n "$model" ]; then
    model_str=" ${DIM}${CYAN}${model}${RESET}"
fi

# Session name
session_str=""
if [ -n "$session_name" ]; then
    session_str=" ${DIM}${FG}[${session_name}]${RESET}"
fi

printf "${FG}${BOLD}${os_icon}${user}⎪${RESET} ${PURPLE}${BOLD} ${display_dir} ${RESET}${git_info}${model_str}${ctx_info}${session_str}\n"
