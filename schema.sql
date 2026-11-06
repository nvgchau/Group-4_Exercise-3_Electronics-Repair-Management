-- =============================================================================
-- Exercise 03 - Electronic Device Repair Management
-- File 1/4 : schema.sql
-- Purpose  : Create the electronics_mini database, its 6 tables and all
--            constraints (PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, ENUM).
-- Requires : MySQL 8.0.16+ (CHECK constraints are enforced from 8.0.16).
-- Run order: schema.sql -> seed.sql -> queries.sql -> views.sql
-- =============================================================================

SET NAMES utf8mb4;

-- Re-runnable: drop and recreate the database from scratch.
DROP DATABASE IF EXISTS electronics_mini;
CREATE DATABASE electronics_mini
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE electronics_mini;

-- -----------------------------------------------------------------------------
-- 1. specialties: repair specialty groups
-- -----------------------------------------------------------------------------
CREATE TABLE specialties (
    specialty_id  INT           NOT NULL,
    name          VARCHAR(100)  NOT NULL,
    CONSTRAINT pk_specialties       PRIMARY KEY (specialty_id),
    CONSTRAINT uq_specialties_name  UNIQUE (name)
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 2. repairers: each repairer belongs to exactly one specialty (N:1)
-- -----------------------------------------------------------------------------
CREATE TABLE repairers (
    repairer_id   INT           NOT NULL,
    full_name     VARCHAR(100)  NOT NULL,
    email         VARCHAR(150)  NOT NULL,
    skill         VARCHAR(200)  NOT NULL,
    specialty_id  INT           NOT NULL,
    CONSTRAINT pk_repairers        PRIMARY KEY (repairer_id),
    CONSTRAINT uq_repairers_email  UNIQUE (email),
    CONSTRAINT chk_repairers_email CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT fk_repairers_specialty
        FOREIGN KEY (specialty_id) REFERENCES specialties (specialty_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 3. customers: phone and address are optional
-- -----------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id   INT           NOT NULL,
    full_name     VARCHAR(100)  NOT NULL,
    phone         VARCHAR(15)   NULL,
    address       VARCHAR(255)  NULL,
    CONSTRAINT pk_customers        PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_phone  UNIQUE (phone),
    CONSTRAINT chk_customers_phone CHECK (phone IS NULL OR phone REGEXP '^0[0-9]{9}$')
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 4. service_orders: one order = one device, one customer, one repairer
-- -----------------------------------------------------------------------------
CREATE TABLE service_orders (
    order_id       INT           NOT NULL,
    customer_id    INT           NOT NULL,
    repairer_id    INT           NOT NULL,
    received_at    DATETIME      NOT NULL,
    status         ENUM('Pending', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Pending',
    device_name    VARCHAR(150)  NOT NULL,
    serial_number  VARCHAR(100)  NOT NULL,
    CONSTRAINT pk_service_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_orders_repairer
        FOREIGN KEY (repairer_id) REFERENCES repairers (repairer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 5. service_reports: at most one handover report per order (UNIQUE order_id)
--    The report holds the confirmed repair cost.
-- -----------------------------------------------------------------------------
CREATE TABLE service_reports (
    report_id      INT            NOT NULL,
    order_id       INT            NOT NULL,
    diagnosis      VARCHAR(500)   NOT NULL,
    solution       VARCHAR(500)   NOT NULL,
    warranty_days  INT            NOT NULL DEFAULT 0,
    cost           DECIMAL(12, 2) NOT NULL,
    CONSTRAINT pk_service_reports     PRIMARY KEY (report_id),
    CONSTRAINT uq_reports_order       UNIQUE (order_id),
    CONSTRAINT chk_reports_warranty   CHECK (warranty_days >= 0),
    CONSTRAINT chk_reports_cost       CHECK (cost >= 0),
    CONSTRAINT fk_reports_order
        FOREIGN KEY (order_id) REFERENCES service_orders (order_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- 6. payments: each row is one actual payment; an order may be paid in
--    several instalments.
-- -----------------------------------------------------------------------------
CREATE TABLE payments (
    payment_id    INT            NOT NULL,
    order_id      INT            NOT NULL,
    amount        DECIMAL(12, 2) NOT NULL,
    payment_date  DATE           NOT NULL,
    method        ENUM('Cash', 'BankTransfer', 'Card') NOT NULL,
    CONSTRAINT pk_payments         PRIMARY KEY (payment_id),
    CONSTRAINT chk_payments_amount CHECK (amount > 0),
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) REFERENCES service_orders (order_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB;

-- -----------------------------------------------------------------------------
-- Indexes for the date and status filters used in queries.sql
-- -----------------------------------------------------------------------------
CREATE INDEX idx_orders_received_at ON service_orders (received_at);
CREATE INDEX idx_orders_status      ON service_orders (status);
CREATE INDEX idx_payments_date      ON payments (payment_date);

-- Cross-table rules (only Completed orders have a report, payment only after a
-- confirmed cost, total paid <= cost) cannot be written as CHECK constraints.
-- They are verified by the validation queries at the end of seed.sql.
