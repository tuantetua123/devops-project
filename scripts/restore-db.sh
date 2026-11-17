#!/usr/bin/env bash
# Restore a backup made by backup-db.sh.
# Usage: restore-db.sh <backup.sql.gz> [target_db]
#   Default target is "restore_drill": a throwaway DB, dropped afterwards (restore drill).
#   To overwrite the real database: CONFIRM=yes restore-db.sh <file> <real_db_name>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${COMPOSE_FILE:-$SCRIPT_DIR/../compose.yml}"
DC=(docker compose -f "$COMPOSE_FILE")

log() { printf '{"ts":"%s","level":"%s","msg":"%s"}\n' "$(date -u +%FT%TZ)" "$1" "$2"; }

file="${1:?usage: restore-db.sh <backup.sql.gz> [target_db]}"
target="${2:-restore_drill}"

[ -f "$file" ] || { log error "file not found: $file"; exit 1; }
gzip -t "$file" || { log error "backup file is corrupt: $file"; exit 1; }

real_db="$("${DC[@]}" exec -T db sh -c 'printf %s "$POSTGRES_DB"')"
if [ "$target" = "$real_db" ] && [ "${CONFIRM:-}" != "yes" ]; then
  log error "refusing to overwrite $real_db without CONFIRM=yes"
  exit 1
fi

"${DC[@]}" exec -T -e TARGET="$target" db sh -c '
  psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 \
    -c "DROP DATABASE IF EXISTS \"$TARGET\" WITH (FORCE)" \
    -c "CREATE DATABASE \"$TARGET\""'

gunzip -c "$file" | "${DC[@]}" exec -T -e TARGET="$target" db sh -c \
  'psql -U "$POSTGRES_USER" -d "$TARGET" -v ON_ERROR_STOP=1 -q -o /dev/null'

tables="$("${DC[@]}" exec -T -e TARGET="$target" db sh -c \
  'psql -U "$POSTGRES_USER" -d "$TARGET" -tAc "select count(*) from information_schema.tables where table_schema=current_schema()"' | tr -d '[:space:]')"

if [ "${tables:-0}" -eq 0 ]; then
  log error "restore finished but database has no tables"
  exit 1
fi
log info "restore ok into $target: $tables tables"

if [ "$target" = "restore_drill" ]; then
  "${DC[@]}" exec -T db sh -c \
    'psql -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS restore_drill WITH (FORCE)"' > /dev/null
  log info "drill database dropped"
fi