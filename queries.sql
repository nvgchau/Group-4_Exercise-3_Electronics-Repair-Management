
SET NAMES utf8mb4;
USE electronics_mini;

-- -----------------------------------------------------------------------------
-- Query 1. 
-- -----------------------------------------------------------------------------
SELECT
    so.order_id,
    so.received_at,
    so.device_name,
    c.customer_id,
    c.full_name  AS customer_name,
    r.repairer_id,
    r.full_name  AS repairer_name
FROM service_orders so
JOIN customers c ON c.customer_id = so.customer_id
JOIN repairers r ON r.repairer_id = so.repairer_id
WHERE so.status = 'Completed'
  AND so.received_at >= '2025-01-01'
  AND so.received_at <  '2025-02-01'
ORDER BY so.received_at, so.order_id;

-- -----------------------------------------------------------------------------
-- Query 2. 
-- -----------------------------------------------------------------------------
SELECT
    s.specialty_id,
    s.name               AS specialty_name,
    COUNT(so.order_id)   AS total_orders_q1_2025
FROM specialties s
LEFT JOIN repairers r
       ON r.specialty_id = s.specialty_id
LEFT JOIN service_orders so
       ON so.repairer_id = r.repairer_id
      AND so.received_at >= '2025-01-01'
      AND so.received_at <  '2025-04-01'
GROUP BY s.specialty_id, s.name
ORDER BY s.specialty_id;

-- -----------------------------------------------------------------------------
-- Query 3. 
-- -----------------------------------------------------------------------------
SELECT
    c.customer_id,
    c.full_name AS customer_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM service_orders so
    LEFT JOIN service_reports sr ON sr.order_id = so.order_id
    WHERE so.customer_id = c.customer_id
      AND so.status <> 'Cancelled'
      AND sr.report_id IS NULL
)
ORDER BY c.customer_id;

-- -----------------------------------------------------------------------------
-- Query 4.
-- -----------------------------------------------------------------------------
SELECT
    s.specialty_id,
    s.name                     AS specialty_name,
    COUNT(sr.report_id)        AS completed_orders,
    ROUND(AVG(sr.cost), 2)     AS avg_cost_per_completed_order
FROM specialties s
JOIN repairers r        ON r.specialty_id = s.specialty_id
JOIN service_orders so  ON so.repairer_id = r.repairer_id
                       AND so.status = 'Completed'
JOIN service_reports sr ON sr.order_id = so.order_id
GROUP BY s.specialty_id, s.name
HAVING SUM(sr.cost) > 0
ORDER BY s.specialty_id;

-- -----------------------------------------------------------------------------
-- Query 5. 
-- -----------------------------------------------------------------------------
SELECT
    r.repairer_id,
    r.full_name          AS repairer_name,
    COUNT(so.order_id)   AS completed_orders_2025
FROM repairers r
JOIN service_orders so ON so.repairer_id = r.repairer_id
WHERE so.status = 'Completed'
  AND so.received_at >= '2025-01-01'
  AND so.received_at <  '2026-01-01'
GROUP BY r.repairer_id, r.full_name
ORDER BY completed_orders_2025 DESC, r.repairer_id ASC
LIMIT 3;

-- -----------------------------------------------------------------------------
-- Query 6. 
-- -----------------------------------------------------------------------------
SELECT
    c.customer_id,
    c.full_name                          AS customer_name,
    COALESCE(pay.total_paid_2025, 0.00)  AS total_paid_2025
FROM customers c
LEFT JOIN (
    SELECT so.customer_id, SUM(p.amount) AS total_paid_2025
    FROM payments p
    JOIN service_orders so ON so.order_id = p.order_id
    WHERE p.payment_date >= '2025-01-01'
      AND p.payment_date <  '2026-01-01'
    GROUP BY so.customer_id
) pay ON pay.customer_id = c.customer_id
ORDER BY c.customer_id;

-- -----------------------------------------------------------------------------
-- Query 7. 
-- -----------------------------------------------------------------------------
SELECT
    c.customer_id,
    c.full_name AS customer_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM service_orders so
    JOIN payments p ON p.order_id = so.order_id
    WHERE so.customer_id = c.customer_id
)
ORDER BY c.customer_id;

-- -----------------------------------------------------------------------------
-- Query 8. 
-- -----------------------------------------------------------------------------
SELECT
    c.customer_id,
    c.full_name                    AS customer_name,
    COALESCE(SUM(sr.cost), 0.00)   AS total_confirmed_cost
FROM customers c
LEFT JOIN service_orders so  ON so.customer_id = c.customer_id
LEFT JOIN service_reports sr ON sr.order_id = so.order_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_confirmed_cost DESC, c.customer_id ASC;

-- -----------------------------------------------------------------------------
-- Query 9. 
-- -----------------------------------------------------------------------------
SELECT
    r.repairer_id,
    r.full_name                                                AS repairer_name,
    COUNT(so.order_id)                                         AS total_orders_2025,
    SUM(CASE WHEN so.status = 'Cancelled' THEN 1 ELSE 0 END)   AS cancelled_orders_2025,
    ROUND(100.0 * SUM(CASE WHEN so.status = 'Cancelled' THEN 1 ELSE 0 END)
                / NULLIF(COUNT(so.order_id), 0), 2)            AS cancellation_rate_pct
FROM repairers r
LEFT JOIN service_orders so
       ON so.repairer_id = r.repairer_id
      AND so.received_at >= '2025-01-01'
      AND so.received_at <  '2026-01-01'
GROUP BY r.repairer_id, r.full_name
ORDER BY r.repairer_id;

-- -----------------------------------------------------------------------------
-- Query 10. 
-- -----------------------------------------------------------------------------
SELECT
    c.customer_id,
    c.full_name          AS customer_name,
    COUNT(so.order_id)   AS completed_orders_2025
FROM customers c
JOIN service_orders so ON so.customer_id = c.customer_id
WHERE so.status = 'Completed'
  AND so.received_at >= '2025-01-01'
  AND so.received_at <  '2026-01-01'
GROUP BY c.customer_id, c.full_name
HAVING COUNT(so.order_id) > 3
ORDER BY completed_orders_2025 DESC, c.customer_id ASC;
