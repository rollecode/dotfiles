#!/usr/bin/env bash
# Deterministic backstop for catastrophic commands, in every permission mode.
# Deliberately narrow: the auto mode classifier handles the grey zone, this only
# hard-blocks the small set of things that are unrecoverable when it misjudges.
set -uo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

decide() {
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
  exit 0
}
deny() { decide deny "$1"; }
ask()  { decide ask  "$1"; }

match() { grep -qE "$1" <<<"$cmd"; }
imatch() { grep -qiE "$1" <<<"$cmd"; }

# A path token that means "wipe the machine or the whole home directory"
ROOTISH='(/home/[^/[:space:]]+|/(home|etc|usr|var|boot|bin|sbin|lib|lib64|opt|srv|root|dev|proc|sys)|\$\{?HOME\}?|~|/)'
TARGET="(^|[[:space:]])${ROOTISH}/?\*?([[:space:]]|;|$)"

# --- Hard block: unrecoverable ---

match '(^|[^-A-Za-z0-9_])rm([[:space:]]|$)' && match '(^|[[:space:]])-[a-zA-Z]*[rR]' && match "$TARGET" \
  && deny "Recursive rm targeting a system or home root. Blocked outright; run it yourself if you truly mean it."
match 'no-preserve-root' \
  && deny "--no-preserve-root removes the last safety net on rm. Blocked outright."
match '(^|[^-A-Za-z0-9_])(mkfs[.a-z0-9]*|wipefs|fdisk|parted)([[:space:]]|$)' \
  && deny "Filesystem/partition command destroys a disk. Blocked outright."
match '(^|[^-A-Za-z0-9_])dd([[:space:]]|$).*[[:space:]]of=/dev/' \
  && deny "dd writing to a block device. Blocked outright."
match '>[[:space:]]*/dev/(sd|nvme|vd|hd)' \
  && deny "Writing directly to a block device. Blocked outright."

# Raw SQL only counts when something can actually execute it, so that grepping or
# reading a migration file for "DROP TABLE" is not mistaken for running it.
DBCLIENT='(^|[^-A-Za-z0-9_])(mysql|mysqladmin|mariadb|psql|pg_[a-z]*|sqlite3|mongo|mongosh|redis-cli|clickhouse-client|sqlcmd|wp|drush|artisan|prisma|sequelize|knex|rails|flyway|liquibase)([[:space:]]|$)'
if match "$DBCLIENT"; then
  imatch '\b(drop[[:space:]]+(database|schema|table)|truncate[[:space:]]+table)\b' \
    && deny "DROP DATABASE/SCHEMA/TABLE or TRUNCATE. Blocked outright; run it yourself if intended."
  imatch '\bdelete[[:space:]]+from\b' && ! imatch '\bwhere\b' \
    && deny "DELETE FROM with no WHERE clause empties the table. Blocked outright."
fi
imatch '\b(dropdb|flushall|flushdb|dropDatabase)\b|\bwp[[:space:]]+db[[:space:]]+(drop|reset)\b|\bdrush[[:space:]]+sql-drop\b|\bartisan[[:space:]]+(migrate:(fresh|reset)|db:wipe)\b' \
  && deny "Database drop/reset command. Blocked outright; run it yourself if intended."

match '\btmux[[:space:]]+kill-|\bscreen[[:space:]]+-X[[:space:]]+quit\b' \
  && deny "Tears down live multiplexer sessions. Blocked outright."
match '\bsystemctl[[:space:]]+(--user[[:space:]]+)?(stop|restart|kill)[[:space:]]+.*(user@|user-[0-9]|session-|graphical-session|gdm|display-manager|sddm|lightdm)' \
  && deny "Would kill the graphical session. Blocked outright."
match '\bloginctl[[:space:]]+(terminate|kill)-' \
  && deny "Terminates a live login session. Blocked outright."
match '(^|[^-A-Za-z0-9_])(reboot|poweroff|halt)([[:space:]]|$)|\bshutdown[[:space:]]+-' \
  && deny "System power command. Blocked outright."

# --- Prompt: destroys work but recoverable or intentional ---

match '\bgit[[:space:]]+push\b.*(--force([^-]|$)|[[:space:]]-f([[:space:]]|$)|--delete|[[:space:]]:)' \
  && ask "Force/delete push rewrites remote history."
match '\bgit[[:space:]]+(.*[[:space:]])?(reset[[:space:]]+--hard|clean[[:space:]]+-[a-zA-Z]*[fd]|branch[[:space:]]+-D|stash[[:space:]]+(drop|clear)|filter-branch|filter-repo|reflog[[:space:]]+expire)' \
  && ask "Discards commits or uncommitted work."
match '\bch(mod|own)[[:space:]]+-[a-zA-Z]*R' && match "$TARGET" \
  && ask "Recursive ownership/permission change on a system or home root."

exit 0
