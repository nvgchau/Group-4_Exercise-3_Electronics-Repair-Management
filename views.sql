-- =============================================================================
-- Exercise 03 - Electronic Device Repair Management
-- File 4/4 : views.sql
-- Purpose  : Create the 3 views of Part D. All views cover the whole time
--            range (not limited to 2025).
-- Run order: schema.sql -> seed.sql -> queries.sql -> views.sql
-- =============================================================================

SET NAMES utf8mb4;
USE electronics_mini;

-- -----------------------------------------------------------------------------
-- v_detail: one row per service order, with date, status, customer,
--           repairer, specialty and repair cost.
--           LEFT JOIN on service_reports keeps orders without a report
--           (repair_cost = NULL).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_detail AS
SELECT
    so.order_id,
    so.received_at,
    so.status,
    so.device_name,
    so.serial_number,
    c.customer_id,
    c.full_name    AS customer_name,
    r.repairer_id,
    r.full_name    AS repairer_name,
    s.specialty_id,
    s.name         AS specialty_name,
    sr.cost        AS repair_cost
FROM service_orders so
JOIN customers   c ON c.customer_id  = so.customer_id
JOIN repairers   r ON r.repairer_id  = so.repairer_id
JOIN specialties s ON s.specialty_id = r.specialty_id
LEFT JOIN service_reports sr ON sr.order_id = so.order_id;

-- -----------------------------------------------------------------------------
-- v_group_summary: one row per specialty with total orders, Completed count,
--                  Cancelled count and total repair cost.
--                  Specialties without orders are kept (counts and cost = 0).
--                  Each order has at most one report, so costs are not
--                  duplicated by the joins.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_group_summary AS
SELECT
    s.specialty_id,
    s.name                                                       AS specialty_name,
    COUNT(so.order_id)                                           AS total_orders,
    SUM(CASE WHEN so.status = 'Completed' THEN 1 ELSE 0 END)     AS completed_orders,
    SUM(CASE WHEN so.status = 'Cancelled' THEN 1 ELSE 0 END)     AS cancelled_orders,
    COALESCE(SUM(sr.cost), 0.00)                                 AS total_repair_cost
FROM specialties s
LEFT JOIN repairers r        ON r.specialty_id = s.specialty_id
LEFT JOIN service_orders so  ON so.repairer_id = r.repairer_id
LEFT JOIN service_reports sr ON sr.order_id    = so.order_id
GROUP BY s.specialty_id, s.name;

-- -----------------------------------------------------------------------------
-- v_debt: one row per customer with total confirmed cost, total paid and
--         outstanding debt (= cost - paid).
--         Costs and payments are aggregated per customer in separate
--         subqueries BEFORE joining, so an order with several payments does
--         not multiply its cost. Customers with no cost or payment show 0.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_debt AS
SELECT
    c.customer_id,
    c.full_name                                   AS customer_name,
    COALESCE(cost_sum.total_cost, 0.00)           AS total_confirmed_cost,
    COALESCE(paid_sum.total_paid, 0.00)           AS total_paid,
    COALESCE(cost_sum.total_cost, 0.00)
      - COALESCE(paid_sum.total_paid, 0.00)       AS outstanding_debt
FROM customers c
LEFT JOIN (
    SELECT so.customer_id, SUM(sr.cost) AS total_cost
    FROM service_orders so
    JOIN service_reports sr ON sr.order_id = so.order_id
    GROUP BY so.customer_id
) cost_sum ON cost_sum.customer_id = c.customer_id
LEFT JOIN (
    SELECT so.customer_id, SUM(p.amount) AS total_paid
    FROM service_orders so
    JOIN payments p ON p.order_id = so.order_id
    GROUP BY so.customer_id
) paid_sum ON paid_sum.customer_id = c.customer_id;

-- -----------------------------------------------------------------------------
-- Preview the views
-- -----------------------------------------------------------------------------
SELECT * FROM v_detail        ORDER BY order_id;
SELECT * FROM v_group_summary ORDER BY specialty_id;
SELECT * FROM v_debt          ORDER BY customer_id;
