

SET NAMES utf8mb4;
USE electronics_mini;

-- =============================================================================
-- PART 1. RESET TABLES
-- Without this step, running seed.sql a second time fails on every INSERT
-- with ERROR 1062 (duplicate primary key).
-- =============================================================================
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE payments;
TRUNCATE TABLE service_reports;
TRUNCATE TABLE service_orders;
TRUNCATE TABLE customers;
TRUNCATE TABLE repairers;
TRUNCATE TABLE specialties;
SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- PART 2. SAMPLE DATA
-- Row counts: specialties 6, repairers 8, customers 12,
--             service_orders 22, service_reports 16, payments 18
-- =============================================================================
START TRANSACTION;

-- Specialty 6 has no repairer, so it never has any order.
INSERT INTO specialties (specialty_id, name) VALUES
(1, 'Máy tính & Laptop'),
(2, 'Điện thoại di động'),
(3, 'Máy tính bảng & Thiết bị đeo'),
(4, 'Âm thanh & Điện tử gia dụng'),
(5, 'Thiết bị mạng & Camera'),
(6, 'Máy chơi game');

-- Repairers 2 and 5 share the same name (tests ID-based distinction).
-- Repairer 8 only has orders in 2024 and 2026 (no order in 2025).
INSERT INTO repairers (repairer_id, full_name, email, skill, specialty_id) VALUES
(1, 'Nguyễn Hoàng Long', 'long.nh@suachua.vn',  'Phần cứng laptop, thay ổ cứng, cài đặt hệ điều hành', 1),
(2, 'Trần Thị Mai',      'mai.tt@suachua.vn',   'Sửa bo mạch chủ, card đồ họa',                        1),
(3, 'Lê Văn Đức',        'duc.lv@suachua.vn',   'Thay màn hình, chân sạc điện thoại',                  2),
(4, 'Phạm Quốc Tuấn',    'tuan.pq@suachua.vn',  'Sửa camera, phần mềm điện thoại Android',             2),
(5, 'Trần Thị Mai',      'mai.tt2@suachua.vn',  'Thay pin, màn hình máy tính bảng và đồng hồ',         3),
(6, 'Vũ Đình Khánh',     'khanh.vd@suachua.vn', 'Mạch khuếch đại, loa, tivi',                          4),
(7, 'Đặng Minh Quân',    'quan.dm@suachua.vn',  'Router, camera IP, firmware',                         5),
(8, 'Bùi Thanh Sơn',     'son.bt@suachua.vn',   'Thiết bị âm thanh hi-end',                            4);

-- Customers 1 and 3 share the same name.
-- Customer 10 has no order at all (phone and address left NULL).
INSERT INTO customers (customer_id, full_name, phone, address) VALUES
(1,  'Nguyễn Thị Hương', '0912345601', 'Cầu Giấy, Hà Nội'),
(2,  'Lê Minh Tuấn',     '0912345602', 'Đống Đa, Hà Nội'),
(3,  'Nguyễn Thị Hương', '0912345603', 'Hai Bà Trưng, Hà Nội'),
(4,  'Hoàng Văn Nam',    '0912345604', 'Thanh Xuân, Hà Nội'),
(5,  'Đỗ Thu Trang',     '0912345605', 'Long Biên, Hà Nội'),
(6,  'Phan Anh Khoa',    '0912345606', 'Hoàng Mai, Hà Nội'),
(7,  'Vũ Thị Lan',       '0912345607', 'Ba Đình, Hà Nội'),
(8,  'Trịnh Quốc Bảo',   '0912345608', 'Tây Hồ, Hà Nội'),
(9,  'Mai Thanh Hà',     '0912345609', 'Hà Đông, Hà Nội'),
(10, 'Lý Gia Huy',       NULL,         NULL),
(11, 'Cao Thị Ngọc',     '0912345611', 'Nam Từ Liêm, Hà Nội'),
(12, 'Đinh Văn Phúc',    '0912345612', 'Bắc Từ Liêm, Hà Nội');

-- Time coverage:
--   Orders 1-5    January 2025       (order 5 at 31 Jan 23:30)
--   Orders 6-11   Feb - Mar 2025     (order 11 at 31 Mar 23:59:59, last second of Q1)
--   Orders 12-18  Apr - Dec 2025     (order 12 at 01 Apr 00:00, first second after Q1)
--   Orders 19-22  Outside 2025       (19, 20 in 2024; 21, 22 in 2026)
-- Status: Pending = 10, 17, 22; Cancelled = 4, 15, 18; all others Completed.
-- Customer 1 has 5 Completed orders in 2025 (1, 3, 6, 13, 14).
INSERT INTO service_orders
    (order_id, customer_id, repairer_id, received_at, status, device_name, serial_number) VALUES
(1,  1,  1, '2025-01-03 08:30:00', 'Completed', 'Laptop Dell Inspiron 15',  'DL-INS15-7781'),
(2,  7,  3, '2025-01-08 10:15:00', 'Completed', 'iPhone 13 Pro',            'AP-IP13P-2210'),
(3,  1,  2, '2025-01-15 14:00:00', 'Completed', 'PC Asus ROG Strix',        'AS-ROG-5531'),
(4,  6,  1, '2025-01-22 16:45:00', 'Cancelled', 'Laptop HP Envy x360',      'HP-ENV-0912'),
(5,  2,  3, '2025-01-31 23:30:00', 'Completed', 'Samsung Galaxy A54',       'SS-A54-6618'),
(6,  1,  5, '2025-02-05 09:00:00', 'Completed', 'iPad Gen 9',               'AP-IPD9-4402'),
(7,  4,  4, '2025-02-14 11:20:00', 'Completed', 'Xiaomi Redmi Note 12',     'XM-RN12-3307'),
(8,  3,  2, '2025-02-27 15:10:00', 'Completed', 'MacBook Pro 14 M3',        'AP-MBP14-8820'),
(9,  2,  6, '2025-03-10 13:00:00', 'Completed', 'Loa JBL Charge 5',         'JBL-CH5-1145'),
(10, 5,  5, '2025-03-18 10:30:00', 'Pending',   'Apple Watch Series 8',     'AP-AW8-7719'),
(11, 12, 4, '2025-03-31 23:59:59', 'Completed', 'OPPO Reno 10',             'OP-RN10-5520'),
(12, 11, 1, '2025-04-01 00:00:00', 'Completed', 'Laptop Lenovo IdeaPad 5',  'LN-IDP5-2290'),
(13, 1,  3, '2025-05-12 09:45:00', 'Completed', 'iPhone 15',                'AP-IP15-9031'),
(14, 1,  7, '2025-06-20 14:20:00', 'Completed', 'Camera Imou Ranger 2',     'IM-RG2-6604'),
(15, 7,  6, '2025-08-08 10:00:00', 'Cancelled', 'Tivi Sony Bravia 43',      'SN-BRV43-3381'),
(16, 2,  2, '2025-09-25 08:15:00', 'Completed', 'Laptop Acer Aspire 7',     'AC-ASP7-4417'),
(17, 4,  7, '2025-11-11 16:00:00', 'Pending',   'Router TP-Link Archer C6', 'TP-AC6-8852'),
(18, 3,  4, '2025-12-31 23:59:59', 'Cancelled', 'Vivo Y36',                 'VV-Y36-1203'),
(19, 8,  8, '2024-11-20 10:30:00', 'Completed', 'Ampli Denon PMA-600NE',    'DN-PMA6-0071'),
(20, 2,  1, '2024-12-28 15:00:00', 'Completed', 'Laptop MSI Modern 14',     'MS-MD14-3326'),
(21, 9,  8, '2026-01-01 00:00:00', 'Completed', 'Loa Marshall Emberton II', 'MR-EMB2-9914'),
(22, 9,  3, '2026-02-10 11:00:00', 'Pending',   'Samsung Galaxy Z Flip5',   'SS-ZF5-2268');

-- Exactly one report for each of the 16 Completed orders; none for others.
-- Report 10 (order 12) is a free warranty repair: cost = 0.
INSERT INTO service_reports
    (report_id, order_id, diagnosis, solution, warranty_days, cost) VALUES
(1,  1,  'Ổ cứng HDD có bad sector, máy khởi động chậm',   'Thay SSD 512GB, chuyển dữ liệu, cài lại Windows',  90,  1850000.00),
(2,  2,  'Màn hình OLED vỡ, cảm ứng chết một vùng',         'Thay cụm màn hình chính hãng',                     180, 2600000.00),
(3,  3,  'Card đồ họa quá nhiệt, keo tản nhiệt khô',        'Vệ sinh, thay keo tản nhiệt và quạt GPU',           90,  3200000.00),
(4,  5,  'Chân sạc USB-C lỏng, sạc chập chờn',              'Thay cụm chân sạc',                                 30,  750000.00),
(5,  6,  'Pin chai còn 61%',                                'Thay pin mới',                                      60,  1400000.00),
(6,  7,  'Lỗi phần mềm, máy treo logo',                     'Nạp lại ROM, cập nhật firmware',                    30,  900000.00),
(7,  8,  'Bo mạch chập nguồn do vào nước',                  'Sửa bo mạch, thay IC nguồn',                        180, 4500000.00),
(8,  9,  'Mạch khuếch đại hỏng, loa rè',                    'Thay IC khuếch đại công suất',                      30,  650000.00),
(9,  11, 'Camera sau mờ, không lấy nét',                    'Thay module camera sau',                            60,  1200000.00),
(10, 12, 'Bàn phím liệt hàng phím, còn bảo hành',           'Thay bàn phím theo chế độ bảo hành, không thu phí', 0,   0.00),
(11, 13, 'Màn hình sọc xanh',                               'Thay màn hình OLED',                                180, 3800000.00),
(12, 14, 'Camera mất kết nối Wi-Fi, adapter hỏng',          'Reset firmware, thay adapter nguồn',                30,  550000.00),
(13, 16, 'Bản lề màn hình gãy',                             'Thay bản lề và vỏ mặt A',                           90,  2100000.00),
(14, 19, 'Ampli mất kênh trái, rơ-le hỏng',                 'Thay rơ-le bảo vệ loa, cân chỉnh lại',              90,  2750000.00),
(15, 20, 'Quạt tản nhiệt kêu to, máy nóng',                 'Thay quạt, vệ sinh tổng thể',                       60,  1650000.00),
(16, 21, 'Loa không nhận sạc',                              'Thay mạch sạc',                                     60,  1200000.00);

-- Payments only for orders that have a report; total per order <= cost.
--   Multiple instalments : order 2 (3x), order 13 (2x), order 16 (2x, 2nd in 2026)
--   Partially paid       : order 6, 8, 21
--   Not paid at all      : order 7, 12 (cost 0)
--   Customers with orders but no payment: 4, 5, 6, 11
INSERT INTO payments (payment_id, order_id, amount, payment_date, method) VALUES
(1,  1,  1850000.00, '2025-01-05', 'Cash'),
(2,  2,  1000000.00, '2025-01-10', 'BankTransfer'),
(3,  2,  1000000.00, '2025-01-25', 'BankTransfer'),
(4,  2,   600000.00, '2025-02-05', 'Card'),
(5,  3,  3200000.00, '2025-01-18', 'Card'),
(6,  5,   750000.00, '2025-02-01', 'Cash'),
(7,  6,  1000000.00, '2025-02-08', 'Cash'),
(8,  8,  2000000.00, '2025-03-02', 'BankTransfer'),
(9,  9,   650000.00, '2025-03-12', 'Cash'),
(10, 11, 1200000.00, '2025-04-02', 'Card'),
(11, 13, 2000000.00, '2025-05-15', 'Card'),
(12, 13, 1800000.00, '2025-06-01', 'BankTransfer'),
(13, 14,  550000.00, '2025-06-21', 'Cash'),
(14, 16, 1000000.00, '2025-09-28', 'Cash'),
(15, 16, 1100000.00, '2026-01-05', 'BankTransfer'),
(16, 19, 2750000.00, '2025-01-06', 'BankTransfer'),
(17, 20, 1650000.00, '2024-12-30', 'Card'),
(18, 21,  500000.00, '2026-01-03', 'Cash');

COMMIT;

-- =============================================================================
-- PART 3. VALIDATION QUERIES
-- Each result set has a "result" column. All rows must show PASS.
-- =============================================================================

-- 3.1 Minimum row count per table
SELECT table_name, row_count, min_required,
       IF(row_count >= min_required, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'specialties' AS table_name, COUNT(*) AS row_count, 5 AS min_required FROM specialties
    UNION ALL SELECT 'repairers',       COUNT(*), 6  FROM repairers
    UNION ALL SELECT 'customers',       COUNT(*), 10 FROM customers
    UNION ALL SELECT 'service_orders',  COUNT(*), 12 FROM service_orders
    UNION ALL SELECT 'service_reports', COUNT(*), 10 FROM service_reports
    UNION ALL SELECT 'payments',        COUNT(*), 10 FROM payments
) t;

-- 3.2 Foreign key integrity: number of orphan rows (expected 0)
SELECT fk_name, orphan_rows,
       IF(orphan_rows = 0, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'repairers.specialty_id -> specialties' AS fk_name, COUNT(*) AS orphan_rows
    FROM repairers r LEFT JOIN specialties s ON s.specialty_id = r.specialty_id
    WHERE s.specialty_id IS NULL
    UNION ALL
    SELECT 'service_orders.customer_id -> customers', COUNT(*)
    FROM service_orders o LEFT JOIN customers c ON c.customer_id = o.customer_id
    WHERE c.customer_id IS NULL
    UNION ALL
    SELECT 'service_orders.repairer_id -> repairers', COUNT(*)
    FROM service_orders o LEFT JOIN repairers r ON r.repairer_id = o.repairer_id
    WHERE r.repairer_id IS NULL
    UNION ALL
    SELECT 'service_reports.order_id -> service_orders', COUNT(*)
    FROM service_reports sr LEFT JOIN service_orders o ON o.order_id = sr.order_id
    WHERE o.order_id IS NULL
    UNION ALL
    SELECT 'payments.order_id -> service_orders', COUNT(*)
    FROM payments p LEFT JOIN service_orders o ON o.order_id = p.order_id
    WHERE o.order_id IS NULL
) t;

-- 3.3 Cross-table business rules: number of violating rows (expected 0)
SELECT rule_name, violations,
       IF(violations = 0, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'Non-Completed order has a report' AS rule_name, COUNT(*) AS violations
    FROM service_orders o
    JOIN service_reports sr ON sr.order_id = o.order_id
    WHERE o.status <> 'Completed'
    UNION ALL
    SELECT 'Completed order without exactly one report', COUNT(*)
    FROM (
        SELECT o.order_id
        FROM service_orders o
        LEFT JOIN service_reports sr ON sr.order_id = o.order_id
        WHERE o.status = 'Completed'
        GROUP BY o.order_id
        HAVING COUNT(sr.report_id) <> 1
    ) x
    UNION ALL
    SELECT 'Payment for an order without confirmed cost', COUNT(*)
    FROM payments p
    LEFT JOIN service_reports sr ON sr.order_id = p.order_id
    WHERE sr.report_id IS NULL
    UNION ALL
    SELECT 'Total paid exceeds confirmed cost', COUNT(*)
    FROM service_reports sr
    JOIN (SELECT order_id, SUM(amount) AS total_paid
          FROM payments
          GROUP BY order_id) pay ON pay.order_id = sr.order_id
    WHERE pay.total_paid > sr.cost
    UNION ALL
    SELECT 'Payment dated before the order was received', COUNT(*)
    FROM payments p
    JOIN service_orders o ON o.order_id = p.order_id
    WHERE p.payment_date < DATE(o.received_at)
) t;

-- 3.4 Required test scenarios (Part B): each must match at least 1 row
SELECT scenario, matching_rows,
       IF(matching_rows >= 1, 'PASS', 'FAIL') AS result
FROM (
    SELECT 'Orders in January 2025' AS scenario, COUNT(*) AS matching_rows
    FROM service_orders
    WHERE received_at >= '2025-01-01' AND received_at < '2025-02-01'
    UNION ALL
    SELECT 'Orders in Feb - Mar 2025 (rest of Q1)', COUNT(*)
    FROM service_orders
    WHERE received_at >= '2025-02-01' AND received_at < '2025-04-01'
    UNION ALL
    SELECT 'Orders in 2025 outside Q1', COUNT(*)
    FROM service_orders
    WHERE received_at >= '2025-04-01' AND received_at < '2026-01-01'
    UNION ALL
    SELECT 'Orders outside 2025', COUNT(*)
    FROM service_orders
    WHERE received_at < '2025-01-01' OR received_at >= '2026-01-01'
    UNION ALL
    SELECT 'Orders with status Pending',   COUNT(*) FROM service_orders WHERE status = 'Pending'
    UNION ALL
    SELECT 'Orders with status Completed', COUNT(*) FROM service_orders WHERE status = 'Completed'
    UNION ALL
    SELECT 'Orders with status Cancelled', COUNT(*) FROM service_orders WHERE status = 'Cancelled'
    UNION ALL
    SELECT 'Customers with > 3 Completed orders in 2025', COUNT(*)
    FROM (
        SELECT customer_id
        FROM service_orders
        WHERE status = 'Completed'
          AND received_at >= '2025-01-01' AND received_at < '2026-01-01'
        GROUP BY customer_id
        HAVING COUNT(*) > 3
    ) x
    UNION ALL
    SELECT 'Customers with orders but no payment', COUNT(*)
    FROM customers c
    WHERE EXISTS (SELECT 1 FROM service_orders o WHERE o.customer_id = c.customer_id)
      AND NOT EXISTS (SELECT 1
                      FROM service_orders o
                      JOIN payments p ON p.order_id = o.order_id
                      WHERE o.customer_id = c.customer_id)
    UNION ALL
    SELECT 'Orders paid in multiple instalments', COUNT(*)
    FROM (SELECT order_id FROM payments GROUP BY order_id HAVING COUNT(*) > 1) x
    UNION ALL
    SELECT 'Orders with outstanding debt', COUNT(*)
    FROM service_reports sr
    LEFT JOIN (SELECT order_id, SUM(amount) AS paid
               FROM payments
               GROUP BY order_id) p ON p.order_id = sr.order_id
    WHERE sr.cost - COALESCE(p.paid, 0) > 0
    UNION ALL
    SELECT 'Specialties with no order in Q1 2025', COUNT(*)
    FROM specialties s
    WHERE NOT EXISTS (SELECT 1
                      FROM repairers r
                      JOIN service_orders o ON o.repairer_id = r.repairer_id
                      WHERE r.specialty_id = s.specialty_id
                        AND o.received_at >= '2025-01-01' AND o.received_at < '2025-04-01')
    UNION ALL
    SELECT 'Repairers with no order in 2025', COUNT(*)
    FROM repairers r
    WHERE NOT EXISTS (SELECT 1
                      FROM service_orders o
                      WHERE o.repairer_id = r.repairer_id
                        AND o.received_at >= '2025-01-01' AND o.received_at < '2026-01-01')
) t;

-- =============================================================================
-- PART 4. CONSTRAINT-VIOLATION EXAMPLES (intentionally commented out)
-- These statements are SUPPOSED to fail; they are kept as comments so that the
-- whole file still runs cleanly. To try one, run it inside a transaction:
--     START TRANSACTION;  <statement>;  ROLLBACK;
-- =============================================================================

-- V1. Foreign key: customer 999 does not exist
--     Expected: ERROR 1452 (Cannot add or update a child row)
-- INSERT INTO service_orders VALUES (99, 999, 1, '2025-05-01 09:00:00', 'Pending', 'Laptop test', 'TEST-01');

-- V2. ENUM: invalid status value
--     Expected: ERROR 1265 (Data truncated for column 'status')
-- INSERT INTO service_orders VALUES (99, 1, 1, '2025-05-01 09:00:00', 'Done', 'Laptop test', 'TEST-02');

-- V3. NOT NULL: missing received_at
--     Expected: ERROR 1048 (Column 'received_at' cannot be null)
-- INSERT INTO service_orders VALUES (99, 1, 1, NULL, 'Pending', 'Laptop test', 'TEST-03');

-- V4. UNIQUE: second report for the same order
--     Expected: ERROR 1062 (Duplicate entry for key 'uq_reports_order')
-- INSERT INTO service_reports VALUES (99, 1, 'Test diagnosis', 'Test solution', 30, 500000.00);

-- V5. CHECK: negative cost
--     Expected: ERROR 3819 (Check constraint 'chk_reports_cost' is violated)
-- INSERT INTO service_reports VALUES (99, 10, 'Test', 'Test', 30, -100000.00);

-- V6. CHECK: negative warranty_days
--     Expected: ERROR 3819 (Check constraint 'chk_reports_warranty' is violated)
-- INSERT INTO service_reports VALUES (99, 10, 'Test', 'Test', -5, 100000.00);

-- V7. CHECK: payment amount must be > 0
--     Expected: ERROR 3819 (Check constraint 'chk_payments_amount' is violated)
-- INSERT INTO payments VALUES (99, 1, 0.00, '2025-05-01', 'Cash');

-- V8. ENUM: invalid payment method
--     Expected: ERROR 1265 (Data truncated for column 'method')
-- INSERT INTO payments VALUES (99, 1, 100000.00, '2025-05-01', 'Momo');

-- V9. UNIQUE: duplicate repairer email
--     Expected: ERROR 1062 (Duplicate entry for key 'uq_repairers_email')
-- INSERT INTO repairers VALUES (99, 'Test Repairer', 'long.nh@suachua.vn', 'Test', 1);

-- V10. Foreign key ON DELETE RESTRICT: delete a customer who has orders
--      Expected: ERROR 1451 (Cannot delete or update a parent row)
-- DELETE FROM customers WHERE customer_id = 1;

-- V11. Business rule: payment for an order without confirmed cost (order 10 is Pending)
--      Not blocked by the schema; detected by check 3.3 "Payment for an order without confirmed cost" -> FAIL
-- INSERT INTO payments VALUES (99, 10, 100000.00, '2025-03-20', 'Cash');

-- V12. Business rule: total paid exceeds cost (order 1 is already fully paid)
--      Not blocked by the schema; detected by check 3.3 "Total paid exceeds confirmed cost" -> FAIL
-- INSERT INTO payments VALUES (98, 1, 50000.00, '2025-02-01', 'Cash');
