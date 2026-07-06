CREATE TABLE IF NOT EXISTS hotel_bookings (
  id            CHAR(36)     NOT NULL PRIMARY KEY,
  org_id        CHAR(36)     NOT NULL,
  hotel_id      VARCHAR(100) NOT NULL,
  city          VARCHAR(100) NOT NULL,
  checkin_date  DATE         NOT NULL,
  checkout_date DATE         NOT NULL,
  amount        DECIMAL(12, 2) NOT NULL,
  status        VARCHAR(50)  NOT NULL,
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS booking_events (
  id         BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
  booking_id CHAR(36)     NOT NULL,
  event_type VARCHAR(100) NOT NULL,
  payload    JSON         NULL,
  created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_booking_events_booking
    FOREIGN KEY (booking_id) REFERENCES hotel_bookings (id)
);
