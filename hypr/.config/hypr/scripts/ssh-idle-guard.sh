#!/usr/bin/env bash
# hypridle condition_cmd predicate: exit 1 to defer suspend while an ssh
# session is logged in, exit 0 to allow it. Every failure of its own exits 0 --
# a guard that cannot answer must not be able to strand the machine awake.
# hypridle re-runs this every condition_retry seconds and clears the pending
# retry itself the moment real input arrives, so there is no state to keep.
#
# set -e is deliberately omitted: it would surface an incidental non-zero as
# the script's exit status, and a status of 1 reads as "defer" here.
set -uo pipefail

mapfile -t ids < <(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')
((${#ids[@]})) || exit 0

# A session that vanishes between the two calls makes loginctl exit non-zero
# while still printing the survivors, so read the output and ignore the status.
states=$(loginctl show-session "${ids[@]}" -p Remote --value 2>/dev/null || true)
grep -qx yes <<<"$states" || exit 0

logger -t ssh-idle-guard -p user.debug 'deferring idle suspend: remote session active'
exit 1
