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
MYSQL_PASSWORD="${MYSQL_PASSWORD:-triphoria}"

mkdir -p "$BACKUP_DIR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/triphoria_${TIMESTAMP}.sql.gz"

echo "Creating backup: ${BACKUP_FILE}"

docker compose -f "${ROOT_DIR}/docker-compose.yml" exec -T db \
  mysqldump \
  -u "$MYSQL_USER" \
  -p"$MYSQL_PASSWORD" \
  --single-transaction \
  --no-tablespaces \
  --routines \
  --triggers \
  "$MYSQL_DATABASE" | gzip > "$BACKUP_FILE"

echo "Backup created successfully."
ls -lh "$BACKUP_FILE"
