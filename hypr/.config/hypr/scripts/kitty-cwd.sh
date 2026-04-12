#!/bin/sh
pid=$(hyprctl activewindow -j | jq -r '.pid')
kitty @ --to "unix:@kitty-$pid" launch --cwd=current --type=os-window 2>/dev/null || exec kitty
