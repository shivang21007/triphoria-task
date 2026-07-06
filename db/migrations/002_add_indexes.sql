CREATE INDEX idx_hotel_bookings_city_created_org_status
  ON hotel_bookings (city, created_at, org_id, status);
