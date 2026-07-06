DROP TEMPORARY TABLE IF EXISTS seed_bookings;

CREATE TEMPORARY TABLE seed_bookings (
  row_num        INT NOT NULL,
  id             CHAR(36) NOT NULL,
  org_id         CHAR(36) NOT NULL,
  hotel_id       VARCHAR(100) NOT NULL,
  city           VARCHAR(100) NOT NULL,
  checkin_date   DATE NOT NULL,
  checkout_date  DATE NOT NULL,
  amount         DECIMAL(12, 2) NOT NULL,
  status         VARCHAR(50) NOT NULL,
  created_at     TIMESTAMP NOT NULL
);

INSERT INTO seed_bookings
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 120
)
SELECT
  n,
  UUID(),
  ELT(
    1 + MOD(n - 1, 4),
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',
    'cccccccc-cccc-4ccc-8ccc-ccccccccccc3',
    'dddddddd-dddd-4ddd-8ddd-ddddddddddd4'
  ),
  CONCAT('hotel-', LPAD(n, 3, '0')),
  ELT(1 + MOD(n - 1, 7), 'delhi', 'mumbai', 'bangalore', 'chennai', 'kolkata', 'hyderabad', 'pune'),
  DATE_SUB(CURDATE(), INTERVAL MOD(n - 1, 45) DAY),
  DATE_ADD(DATE_SUB(CURDATE(), INTERVAL MOD(n - 1, 45) DAY), INTERVAL 2 DAY),
  ROUND(1500 + MOD(n * 375, 80000) / 10, 2),
  ELT(1 + MOD(n - 1, 4), 'confirmed', 'cancelled', 'pending', 'completed'),
  DATE_SUB(NOW(), INTERVAL MOD(n - 1, 45) DAY)
FROM seq;

INSERT INTO hotel_bookings (
  id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at
)
SELECT
  id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at
FROM seed_bookings;

INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT
  id,
  'status_changed',
  JSON_OBJECT('from', 'pending', 'to', 'confirmed'),
  NOW()
FROM seed_bookings
WHERE MOD(row_num - 1, 3) = 0;

DROP TEMPORARY TABLE seed_bookings;
