#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

MYSQL_DATABASE="${MYSQL_DATABASE:-triphoria}"
MYSQL_USER="${MYSQL_USER:-triphoria}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-rootsecret}"

BACKUP_FILE="${1:-}"
if [[ -z "$BACKUP_FILE" ]]; then
  BACKUP_FILE="$(ls -1t "$BACKUP_DIR"/*.sql.gz 2>/dev/null | head -n 1 || true)"
  if [[ -n "$BACKUP_FILE" ]]; then
    echo "No backup specified — using latest: ${BACKUP_FILE}"
  fi
else
  echo "Using specified backup: ${BACKUP_FILE}"
fi

if [[ -z "$BACKUP_FILE" || ! -f "$BACKUP_FILE" ]]; then
  echo "Usage: $0 [path/to/backup.sql.gz]" >&2
  exit 1
fi

SQL_FILE="${BACKUP_DIR}/restore.sql"
trap 'rm -f "$SQL_FILE"' EXIT

echo "Extracting ${BACKUP_FILE} -> ${SQL_FILE}"
gunzip -c "$BACKUP_FILE" > "$SQL_FILE"

if [[ ! -s "$SQL_FILE" ]]; then
  echo "Error: extracted SQL file is empty." >&2
  exit 1
fi

for table in hotel_bookings booking_events; do
  if ! grep -q "$table" "$SQL_FILE"; then
    echo "Error: SQL dump does not contain table '${table}'." >&2
    exit 1
  fi
done

echo "SQL dump looks valid ($(wc -l < "$SQL_FILE" | tr -d ' ') lines)"

echo "Dropping and recreating database: ${MYSQL_DATABASE}"
docker compose -f "${ROOT_DIR}/docker-compose.yml" exec -T db \
  mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e \
  "DROP DATABASE IF EXISTS \`${MYSQL_DATABASE}\`; CREATE DATABASE \`${MYSQL_DATABASE}\`; GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%'; FLUSH PRIVILEGES;"

echo "Restoring into ${MYSQL_DATABASE}..."
docker compose -f "${ROOT_DIR}/docker-compose.yml" exec -T db \
  mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" < "$SQL_FILE"

docker compose -f "${ROOT_DIR}/docker-compose.yml" exec -T db \
  mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" -e \
  "SELECT COUNT(*) AS booking_count FROM hotel_bookings; SELECT COUNT(*) AS event_count FROM booking_events;"

echo "Restore complete."
