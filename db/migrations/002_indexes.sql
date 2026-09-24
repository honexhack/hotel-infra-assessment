
CREATE INDEX IF NOT EXISTS idx_bookings_city_created
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);

CREATE INDEX IF NOT EXISTS idx_events_booking_id
    ON booking_events (booking_id);