# Exercise 03 – Electronic Device Repair Management (MySQL)

The `electronics_mini` database manages repair specialties, repairers, customers, service orders, handover reports and payments.

## Deliverables

| File | Contents |
|---|---|
| `schema.sql` | Creates the database, 6 tables, PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, ENUM and indexes |
| `seed.sql` | Table reset, sample data (6 / 8 / 12 / 22 / 16 / 18 rows), validation queries 3.1–3.4, violation examples V1–V12 (commented out) |
| `queries.sql` | The 10 queries of Part C, numbered Query 1–10 |
| `views.sql` | 3 views: `v_detail`, `v_group_summary`, `v_debt` |

## How to run

Requires MySQL 8.0.16 or later (CHECK constraints are enforced from this version). Run in this order:

```bash
mysql -u root -p --default-character-set=utf8mb4 < schema.sql
mysql -u root -p --default-character-set=utf8mb4 --table < seed.sql
mysql -u root -p --default-character-set=utf8mb4 --table < queries.sql
mysql -u root -p --default-character-set=utf8mb4 --table < views.sql
```

In MySQL Workbench: open each file and run it with **Execute (⚡)**, in the same order.

- `schema.sql` starts with `DROP DATABASE IF EXISTS`, so it can be re-run at any time.
- `seed.sql` truncates all tables before inserting, so it can also be re-run on its own without `Duplicate entry` errors.

## Conventions

- `received_at` is DATETIME, so date filters use half-open intervals `[start, end)`. Example: Q1 2025 is `>= '2025-01-01' AND < '2025-04-01'`.
- Rules that need more than one table (only Completed orders have a report, payment only after a confirmed cost, total paid ≤ cost) cannot be written as CHECK constraints. They are verified by validation query 3.3 in `seed.sql`.
- When costs and payments are combined, each side is aggregated per customer first and joined afterwards, so a cost is never counted twice for an order with several payments.
- Text values in the sample data (names, addresses, diagnoses…) are fictional and kept in Vietnamese.

## Test scenario coverage (Part B)

| Requirement | Records |
|---|---|
| Orders in January 2025 | orders 1–5 (order 5 at 31 Jan 23:30) |
| Rest of Q1 2025 | orders 6–8 (February), 9–11 (March; order 11 at 31 Mar 23:59:59) |
| 2025 outside Q1 | orders 12–18 (order 12 at 01 Apr 00:00; order 18 at 31 Dec 23:59:59) |
| Outside 2025 | orders 19, 20 (2024); 21, 22 (2026) |
| All 3 statuses | Pending 10, 17, 22; Cancelled 4, 15, 18; all others Completed |
| Customer with > 3 Completed orders in 2025 | customer 1 (5 orders: 1, 3, 6, 13, 14); customer 2 has exactly 3, so does not qualify |
| Has orders but never paid | customers 4, 5, 6, 11 |
| Order paid in several instalments | order 2 (3 payments), 13 (2), 16 (2, the second one in 2026) |
| Order with outstanding debt | orders 6, 8, 21 (partially paid); order 7 (not paid) |
| Specialty with no order in Q1 2025 | specialty 5 (has a repairer), specialty 6 (no repairer) |
| Repairer with no order in 2025 | repairer 8 (orders only in 2024 and 2026) |
| Customer with no order at all | customer 10 |
| Duplicate names | customers 1 and 3 "Nguyễn Thị Hương"; repairers 2 and 5 "Trần Thị Mai" |
| Zero cost | order 12 (warranty repair) |

## Expected results

**seed.sql:** every row of validation queries 3.1–3.4 shows `result = PASS` (29 rows in total).

**V1–V12** (uncomment one and run it inside `START TRANSACTION; … ROLLBACK;`):

| | V1 | V2 | V3 | V4 | V5–V7 | V8 | V9 | V10 | V11 | V12 |
|---|---|---|---|---|---|---|---|---|---|---|
| Result | ERROR 1452 | ERROR 1265 | ERROR 1048 | ERROR 1062 | ERROR 3819 | ERROR 1265 | ERROR 1062 | ERROR 1451 | 3.3 "Payment for an order without confirmed cost" = FAIL | 3.3 "Total paid exceeds confirmed cost" = FAIL |

**queries.sql:**

| Query | Result |
|---|---|
| 1 | orders 1, 2, 3, 5 |
| 2 | specialty 1 = 4, 2 = 4, 3 = 2, 4 = 1, 5 = 0, 6 = 0 |
| 3 | customers 4, 5, 9 |
| 4 | specialty 1 = 2,216,666.67; 2 = 1,850,000.00; 3 = 1,400,000.00; 4 = 1,533,333.33; 5 = 550,000.00 (specialty 6 not listed) |
| 5 | repairer 2 (3), repairer 3 (3), repairer 1 (2); repairers 1 and 4 tie at 2, repairer 1 wins by lower ID |
| 6 | customer 1 = 10,400,000; 2 = 2,400,000; 3 = 2,000,000; 7 = 2,600,000; 8 = 2,750,000; 12 = 1,200,000; all others = 0 |
| 7 | customers 4, 5, 6, 10, 11 |
| 8 | 1 (10,800,000), 2 (5,150,000), 3 (4,500,000), 8, 7, 9, 12, 4, then 5, 6, 10, 11 (all = 0) |
| 9 | repairer 1 = 33.33; 4 = 33.33; 6 = 50.00; 2, 3, 5, 7 = 0.00; 8 = NULL |
| 10 | customer 1 only (5 orders) |

**views.sql:** `v_debt` shows non-zero debt for customers 1 (400,000), 3 (2,500,000), 4 (900,000) and 9 (700,000).

