#!/usr/bin/env bash
# hypridle on-timeout handler: suspend unless an ssh session is active.
# Run with --cancel (from hypridle on-resume) to abort a deferral in progress.
#
# hypridle counts only Wayland input as activity, so ssh work never resets its
# timer. Deferral is bounded: suspends immediately with no ssh, after
# IDLE_GRACE_SECONDS of remote quiet, or at MAX_DEFER_SECONDS regardless.
#
# Remote activity = atime/mtime of each remote tty. A remote session with no
# tty (rsync, scp, ssh host cmd, -N tunnels) cannot be measured, so the grace
# is not applied at all while one exists — those defer to the cap.
#
# Failure modes deliberately fall towards suspending on time rather than never
# suspending, except where a live session would be killed.

set -uo pipefail

# Overridable so the wall-clock bounds can be exercised in tests without waiting.
readonly POLL_SECONDS=${POLL_SECONDS:-60}
readonly SETTLE_SECONDS=${SETTLE_SECONDS:-120}   # re-check after an apparent disconnect
readonly IDLE_GRACE_SECONDS=${IDLE_GRACE_SECONDS:-$((15 * 60))}
readonly MAX_DEFER_SECONDS=${MAX_DEFER_SECONDS:-$((2 * 60 * 60))}
readonly LOCKFILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/idle-suspend.lock"

log() { logger -t idle-suspend -- "$*"; }

# First Port in the effective sshd config; drop-ins win, as sshd includes them first.
sshd_port() {
    local f p
    for f in /etc/ssh/sshd_config.d/*.conf /etc/ssh/sshd_config; do
        [[ -r "$f" ]] || continue
        p=$(awk '/^[[:space:]]*[Pp]ort[[:space:]]+[0-9]+/ {print $2; exit}' "$f" 2>/dev/null)
        [[ -n "$p" ]] && { printf '%s' "$p"; return; }
    done
    printf '22'
}

# --cancel: hypridle saw real input, so kill the deferral this instance started.
if [[ ${1:-} == --cancel ]]; then
    pid=$(cat "$LOCKFILE" 2>/dev/null) || exit 0
    [[ "$pid" =~ ^[0-9]+$ ]] || exit 0
    # Confirm the pid is still us before signalling a recycled pid.
    grep -qa 'idle-suspend' "/proc/$pid/cmdline" 2>/dev/null || exit 0
    kill "$pid" 2>/dev/null && log "user returned, cancelling deferral (pid $pid)"
    exit 0
fi

readonly SSH_PORT="$(sshd_port)"

# An ss failure is indistinguishable from "no sessions" if only output is read,
# so check status separately and assume active rather than kill a live session.
ss_failing=0
ssh_active() {
    local out rc
    out=$(ss -tnH state established "( sport = :$SSH_PORT )" 2>/dev/null)
    rc=$?
    if ((rc != 0)); then
        # Log the transition only; polling every 60s would otherwise flood the journal.
        ((ss_failing)) || log "ss failed (exit $rc); assuming an ssh session is active"
        ss_failing=1
        return 0
    fi
    ((ss_failing)) && log "ss recovered"
    ss_failing=0
    [[ -n "$out" ]]
}

# Age of the most recently active remote tty. Returns 1 if any remote session
# cannot be measured, which the caller treats as "no signal, keep deferring".
remote_activity_age() {
    local sid tty dev stamps latest newest="" now
    printf -v now '%(%s)T' -1
    while read -r sid _; do
        [[ -n "$sid" ]] || continue
        [[ $(loginctl show-session "$sid" -p Remote --value 2>/dev/null) == yes ]] || continue
        tty=$(loginctl show-session "$sid" -p TTY --value 2>/dev/null)
        dev="/dev/$tty"
        [[ -n "$tty" && -e "$dev" ]] || return 1
        stamps=$(stat -c '%X %Y' "$dev" 2>/dev/null) || return 1
        latest=${stamps%% *}
        ((${stamps##* } > latest)) && latest=${stamps##* }
        [[ -z "$newest" ]] || ((latest > newest)) && newest=$latest
    done < <(loginctl list-sessions --no-legend 2>/dev/null)
    [[ -n "$newest" ]] || return 1
    printf '%s\n' $((now - newest))
}

suspend_now() {
    log "suspending: $1"
    exec systemctl suspend-then-hibernate
}

# A defer loop from a previous idle period may still be running. Failing to take
# the lock must not mean never suspending again, so carry on unserialised.
if exec 9>"$LOCKFILE"; then
    if ! flock -n 9; then
        log "another instance is already deferring suspend, exiting"
        exit 0
    fi
    printf '%s\n' "$$" >&9
else
    log "cannot open $LOCKFILE; continuing without the instance lock"
fi

trap 'log "deferral cancelled"; exit 0' TERM

if ! ssh_active; then
    suspend_now "no active ssh sessions"
fi

log "ssh session active, deferring suspend (grace ${IDLE_GRACE_SECONDS}s, cap ${MAX_DEFER_SECONDS}s)"
printf -v started '%(%s)T' -1

while :; do
    if ! ssh_active; then
        # A reaped half-open session looks identical to a real logout, so give a
        # dropped link a chance to come back before stranding the host.
        log "no ssh sessions; settling ${SETTLE_SECONDS}s"
        sleep "$SETTLE_SECONDS"
        ssh_active || break
        log "ssh returned during settle, still deferring"
        continue
    fi

    # Wall clock, so time spent suspended still counts towards the cap.
    printf -v now '%(%s)T' -1
    ((now - started >= MAX_DEFER_SECONDS)) &&
        suspend_now "deferral cap of ${MAX_DEFER_SECONDS}s reached with ssh still connected"

    if age=$(remote_activity_age) && ((age >= IDLE_GRACE_SECONDS)); then
        suspend_now "remote sessions quiet for ${age}s"
    fi

    sleep "$POLL_SECONDS"
done

suspend_now "last ssh session disconnected"
