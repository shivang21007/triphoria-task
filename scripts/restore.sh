#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_DATABASE="${MYSQL_DATABASE:-triphoria}"
RESTORE_DATABASE="${RESTORE_DATABASE:-triphoria_restore}"
MYSQL_USER="${MYSQL_USER:-triphoria}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-triphoria}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-rootsecret}"

BACKUP_FILE="${1:-}"

if [[ -z "$BACKUP_FILE" ]]; then
  BACKUP_FILE="$(ls -1t "$BACKUP_DIR"/*.sql.gz 2>/dev/null | head -n 1 || true)"
fi

if [[ -z "$BACKUP_FILE" || ! -f "$BACKUP_FILE" ]]; then
  echo "Usage: $0 [path/to/backup.sql.gz]" >&2
  echo "No backup file found in ${BACKUP_DIR}" >&2
  exit 1
fi

echo "Restoring from: ${BACKUP_FILE}"
echo "Target database: ${RESTORE_DATABASE}"

mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u root -p"$MYSQL_ROOT_PASSWORD" -e \
  "DROP DATABASE IF EXISTS \`${RESTORE_DATABASE}\`; CREATE DATABASE \`${RESTORE_DATABASE}\`;"

gunzip -c "$BACKUP_FILE" | mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u root -p"$MYSQL_ROOT_PASSWORD" "$RESTORE_DATABASE"

mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "
  SELECT '${MYSQL_DATABASE}' AS db_name, COUNT(*) AS bookings FROM \`${MYSQL_DATABASE}\`.hotel_bookings
  UNION ALL
  SELECT '${RESTORE_DATABASE}' AS db_name, COUNT(*) AS bookings FROM \`${RESTORE_DATABASE}\`.hotel_bookings;

  SELECT '${MYSQL_DATABASE}' AS db_name, COUNT(*) AS events FROM \`${MYSQL_DATABASE}\`.booking_events
  UNION ALL
  SELECT '${RESTORE_DATABASE}' AS db_name, COUNT(*) AS events FROM \`${RESTORE_DATABASE}\`.booking_events;
"

echo "Restore complete. Compare row counts above — they should match."
