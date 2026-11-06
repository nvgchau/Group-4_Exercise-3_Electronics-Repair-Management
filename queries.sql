-- =============================================================================
-- Exercise 03 - Electronic Device Repair Management
-- File 3/4 : queries.sql
-- Purpose  : The 10 independent queries of Part C.
-- Conventions:
--   * received_at is DATETIME, so date ranges use half-open intervals
--     [start, end), e.g. Q1 2025 = received_at >= '2025-01-01'
--                                 AND received_at <  '2025-04-01'.
--   * Every result includes the ID and the name so that people with the same
--     name can be told apart.
-- Run order: schema.sql -> seed.sql -> queries.sql -> views.sql
-- =============================================================================

SET NAMES utf8mb4;
USE electronics_mini;

-- -----------------------------------------------------------------------------
-- Query 1. Completed orders received in January 2025, with customer,
--          repairer and received_at.
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
-- Query 2. Number of orders per specialty in Q1 2025 (all statuses),
--          including specialties with 0 orders.
--          The date filter is in the ON clause so the LEFT JOIN keeps them.
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
-- Query 3. Customers with at least one non-Cancelled order that has no
--          handover report yet. Each customer appears once (EXISTS).
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
-- Query 4. Average repair cost per Completed order for each specialty
--          (all time). Only specialties that have incurred a cost.
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
-- Query 5. Top 3 repairers by number of Completed orders in 2025.
--          Ties are broken by repairer_id ascending; only repairers with
--          at least one such order (INNER JOIN).
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
-- Query 6. Total amount paid by each customer in 2025 (by payment_date),
--          including customers who paid nothing (shown as 0).
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
-- Query 7. Customers with no payment record at all (all time),
--          including customers who have never placed an order.
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
-- Query 8. All customers ranked by total confirmed repair cost (descending),
--          regardless of payment; ties ordered by customer_id ascending.
--          Payments are not joined here, so costs are never double-counted.
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
-- Query 9. Cancellation rate of each repairer in 2025:
--          Cancelled orders / total orders of the year * 100,
--          rounded to 2 decimals; NULL when the repairer has no order in 2025.
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
-- Query 10. Customers with more than 3 Completed orders in 2025, with the
--           count; sorted by count descending.
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
