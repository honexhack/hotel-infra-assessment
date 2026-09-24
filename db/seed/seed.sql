-- 200 random bookings across 4 orgs, 5 cities, 4 statuses, last 90 days
INSERT INTO hotel_bookings
    (id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
SELECT
    gen_random_uuid(),
    org_id,
    hotel_id,
    city,
    created_at::date + gap,
    created_at::date + gap + nights,
    amount,
    status,
    created_at
FROM (
    SELECT
        (ARRAY[
            '11111111-1111-1111-1111-111111111111',
            '22222222-2222-2222-2222-222222222222',
            '33333333-3333-3333-3333-333333333333',
            '44444444-4444-4444-4444-444444444444'
        ])[1 + floor(random() * 4)::int]::uuid                                   AS org_id,
        'HOTEL-' || (100 + floor(random() * 20)::int)                            AS hotel_id,
        (ARRAY['delhi', 'mumbai', 'bangalore', 'goa', 'jaipur'])[1 + floor(random() * 5)::int] AS city,
        (ARRAY['pending', 'confirmed', 'cancelled', 'completed'])[1 + floor(random() * 4)::int] AS status,
        round((2000 + random() * 18000)::numeric, 2)                             AS amount,
        NOW() - random() * INTERVAL '90 days'                                    AS created_at,
        1 + floor(random() * 30)::int                                            AS gap,
        1 + floor(random() * 5)::int                                             AS nights
    FROM generate_series(1, 200)
) t;

INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT id,
       'booking_created',
       jsonb_build_object('city', city, 'amount', amount),
       created_at
FROM hotel_bookings;

INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT id,
       'booking_' || status,
       jsonb_build_object('status', status),
       created_at + INTERVAL '2 hours'
FROM hotel_bookings
WHERE status <> 'pending';