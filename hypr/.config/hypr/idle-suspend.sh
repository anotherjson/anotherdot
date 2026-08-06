#!/usr/bin/env bash
# Suspend guard for hypridle's 30min listener.
#
# hypridle measures idleness from Wayland input events only: keyboard and
# mouse. Work arriving over SSH does not reset that timer, so calling
# `systemctl suspend-then-hibernate` directly from on-timeout drops remote
# sessions mid-work — and, because suspend-then-hibernate escalates to
# hibernate after ~2h, leaves the host off the network until someone walks
# over to it.
#
# This defers suspend while an SSH session is doing something, but the
# deferral is always bounded. Suspend still happens if:
#   - no SSH session is established               -> immediately, as before
#   - every remote session goes quiet             -> after IDLE_GRACE_SECONDS
#   - a session stays busy indefinitely           -> after MAX_DEFER_SECONDS
# A forgotten session left open on the laptop therefore costs at most
# IDLE_GRACE_SECONDS of extra uptime, not a whole night.
#
# The one case that cancels suspend outright is the user physically coming
# back, detected via hyprlock exiting (the 10min listener locks the session
# long before this 30min one fires). hypridle re-arms after that, so the next
# idle period re-evaluates from scratch.
#
# Remote activity is read from the atime/mtime of each remote session's tty,
# which covers both typed input and command output. A no-tty transfer
# (rsync/scp/port-forward) shows no tty activity, so it is protected only up
# to IDLE_GRACE_SECONDS.

set -uo pipefail

readonly POLL_SECONDS=60
readonly IDLE_GRACE_SECONDS=$((15 * 60))  # quiet remote sessions stop holding suspend off
readonly MAX_DEFER_SECONDS=$((2 * 60 * 60))  # hard ceiling on total deferral
readonly LOCKFILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/idle-suspend.lock"

log() { logger -t idle-suspend -- "$*"; }

# Any established inbound SSH connection, regardless of which user owns it.
ssh_active() {
    [[ -n "$(ss -tnH state established '( sport = :22 )' 2>/dev/null)" ]]
}

# hyprlock running == session still locked == user still away.
session_locked() { pidof hyprlock >/dev/null 2>&1; }

# tty device of every remote (ssh) login session.
remote_ttys() {
    local sid remote tty
    while read -r sid _; do
        [[ -n "$sid" ]] || continue
        remote=$(loginctl show-session "$sid" -p Remote --value 2>/dev/null)
        [[ "$remote" == "yes" ]] || continue
        tty=$(loginctl show-session "$sid" -p TTY --value 2>/dev/null)
        [[ -n "$tty" ]] || continue
        printf '/dev/%s\n' "$tty"
    done < <(loginctl list-sessions --no-legend 2>/dev/null)
}

# Seconds since the most recently active remote tty. Fails if none has a tty,
# which is the caller's cue that there is no activity signal to go on.
seconds_since_remote_activity() {
    local now newest="" t stamps latest
    printf -v now '%(%s)T' -1
    while read -r t; do
        [[ -e "$t" ]] || continue
        # atime covers input, mtime covers output; newest of the two wins.
        stamps=$(stat -c '%X %Y' "$t" 2>/dev/null) || continue
        latest=${stamps%% *}
        [[ ${stamps##* } -gt $latest ]] && latest=${stamps##* }
        [[ -z "$newest" || $latest -gt $newest ]] && newest=$latest
    done < <(remote_ttys)
    [[ -n "$newest" ]] || return 1
    printf '%s\n' $((now - newest))
}

suspend_now() {
    log "suspending: $1"
    exec systemctl suspend-then-hibernate
}

# Serialize: hypridle fires on-timeout once per idle period, but a deferral
# loop from a previous period could still be alive.
exec 9>"$LOCKFILE" || exit 0
if ! flock -n 9; then
    log "another instance is already deferring suspend, exiting"
    exit 0
fi

if ! ssh_active; then
    suspend_now "no active ssh sessions"
fi

# An SSH session exists, so defer — but only within the bounds above.
# Whether hyprlock was up at entry decides if we can detect the user's return;
# if it was not, we simply lose that abort signal and the bounds still apply.
was_locked=false
session_locked && was_locked=true
$was_locked || log "session not locked at entry; cannot detect user return, bounds still apply"

log "ssh session active, deferring suspend (idle grace ${IDLE_GRACE_SECONDS}s, cap ${MAX_DEFER_SECONDS}s)"
deferred=0
while ssh_active; do
    if $was_locked && ! session_locked; then
        log "session unlocked, user is back, aborting suspend"
        exit 0
    fi

    if ((deferred >= MAX_DEFER_SECONDS)); then
        suspend_now "deferral cap of ${MAX_DEFER_SECONDS}s reached with ssh still connected"
    fi

    if idle=$(seconds_since_remote_activity) && ((idle >= IDLE_GRACE_SECONDS)); then
        suspend_now "remote sessions quiet for ${idle}s"
    fi

    sleep "$POLL_SECONDS"
    ((deferred += POLL_SECONDS))
done

if $was_locked && ! session_locked; then
    log "session unlocked, user is back, aborting suspend"
    exit 0
fi

suspend_now "last ssh session disconnected"
