#!/usr/bin/env bash
# Backup the PostgreSQL database of the attendance stack (compose "db" service).
# Env: BACKUP_DIR (default /var/backups/attendance), RETENTION_DAYS (default 7), COMPOSE_FILE
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/attendance}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
COMPOSE_FILE="${COMPOSE_FILE:-$SCRIPT_DIR/../compose.yml}"
DC=(docker compose -f "$COMPOSE_FILE")

log() { printf '{"ts":"%s","level":"%s","msg":"%s"}\n' "$(date -u +%FT%TZ)" "$1" "$2"; }

mkdir -p "$BACKUP_DIR"
out="$BACKUP_DIR/attendance-$(date +%Y%m%d-%H%M%S).sql.gz"
tmp="$out.partial"

if ! "${DC[@]}" exec -T db sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --no-owner' | gzip -9 > "$tmp"; then
  rm -f "$tmp"
  log error "pg_dump failed"
  exit 1
fi

if ! gzip -t "$tmp"; then
  rm -f "$tmp"
  log error "backup file is corrupt"
  exit 1
fi

mv "$tmp" "$out"
bytes="$(wc -c < "$out" | tr -d ' ')"
find "$BACKUP_DIR" -name 'attendance-*.sql.gz' -type f -mtime +"$RETENTION_DAYS" -delete
log info "backup ok: $out ($bytes bytes), retention ${RETENTION_DAYS}d"