#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_DATABASE="${MYSQL_DATABASE:-triphoria}"
MYSQL_USER="${MYSQL_USER:-triphoria}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-triphoria}"

mysql_exec() {
  mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$@"
}

uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
  python3 -c 'import uuid; print(uuid.uuid4())'
  fi
}

CITIES=(delhi mumbai bangalore chennai kolkata hyderabad pune)
STATUSES=(confirmed cancelled pending completed)
ORGS=(
  "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1"
  "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2"
  "cccccccc-cccc-4ccc-8ccc-ccccccccccc3"
  "dddddddd-dddd-4ddd-8ddd-ddddddddddd4"
)

echo "Seeding ${MYSQL_DATABASE}..."

mysql_exec "$MYSQL_DATABASE" -e "DELETE FROM booking_events; DELETE FROM hotel_bookings;"

BOOKING_IDS=()

for i in $(seq 1 120); do
  booking_id="$(uuid)"
  BOOKING_IDS+=("$booking_id")
  org_id="${ORGS[$((i % ${#ORGS[@]}))]}"
  city="${CITIES[$((i % ${#CITIES[@]}))]}"
  status="${STATUSES[$((i % ${#STATUSES[@]}))]}"
  hotel_id="hotel-$(printf '%03d' "$i")"
  amount=$(awk -v n="$i" 'BEGIN { printf "%.2f", 1500 + (n * 37.5 % 8000) }')
  day_offset=$((i % 45))
  checkin="DATE_SUB(CURDATE(), INTERVAL ${day_offset} DAY)"
  checkout="DATE_ADD(${checkin}, INTERVAL 2 DAY)"
  created="DATE_SUB(NOW(), INTERVAL ${day_offset} DAY)"

  mysql_exec "$MYSQL_DATABASE" -N -e "
    INSERT INTO hotel_bookings
      (id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
    VALUES
      ('${booking_id}', '${org_id}', '${hotel_id}', '${city}', ${checkin}, ${checkout}, ${amount}, '${status}', ${created});
  "
done

for i in "${!BOOKING_IDS[@]}"; do
  if (( i % 3 == 0 )); then
    booking_id="${BOOKING_IDS[$i]}"
    event_type="status_changed"
    mysql_exec "$MYSQL_DATABASE" -N -e "
      INSERT INTO booking_events (booking_id, event_type, payload, created_at)
      VALUES (
        '${booking_id}',
        '${event_type}',
        JSON_OBJECT('from', 'pending', 'to', 'confirmed'),
        NOW()
      );
    "
  fi
done

echo "Seed complete."
mysql_exec "$MYSQL_DATABASE" -e "
  SELECT COUNT(*) AS booking_count FROM hotel_bookings;
  SELECT COUNT(*) AS event_count FROM booking_events;
"
