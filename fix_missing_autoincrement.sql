-- Database Repair Script for Missing AUTO_INCREMENT and Duplicate IDs
-- Created by Antigravity

-- 1. Fix Customers Table
-- Check if there are any customers with ID 0 and give them a new valid ID
SET @max_customer_id = (SELECT COALESCE(MAX(CustomerID), 0) FROM customers);
UPDATE customers SET CustomerID = (@max_customer_id := @max_customer_id + 1) WHERE CustomerID = 0;

-- Now safe to add Primary Key and Auto Increment if missing
SET @exist := (SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_name = 'customers' AND constraint_type = 'PRIMARY KEY' AND table_schema = DATABASE());
SET @sql := IF(@exist = 0, 'ALTER TABLE customers ADD PRIMARY KEY (CustomerID)', 'SELECT "Primary Key already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

ALTER TABLE customers MODIFY CustomerID int(10) NOT NULL AUTO_INCREMENT;


-- 2. Fix Reservations Table
-- Assign unique IDs to all reservations that currently have ID 0
SET @max_reservation_id = (SELECT COALESCE(MAX(ReservationID), 0) FROM reservations);
UPDATE reservations SET ReservationID = (@max_reservation_id := @max_reservation_id + 1) WHERE ReservationID = 0;

-- Now safe to add Primary Key and Auto Increment if missing
SET @exist := (SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_name = 'reservations' AND constraint_type = 'PRIMARY KEY' AND table_schema = DATABASE());
SET @sql := IF(@exist = 0, 'ALTER TABLE reservations ADD PRIMARY KEY (ReservationID)', 'SELECT "Primary Key already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

ALTER TABLE reservations MODIFY ReservationID int(10) NOT NULL AUTO_INCREMENT;


-- 3. Verify Reservation Items (just in case)
-- The provided SQL file showed it was correct, but we enforce it to be sure
SET @exist := (SELECT COUNT(*) FROM information_schema.table_constraints WHERE table_name = 'reservation_items' AND constraint_type = 'PRIMARY KEY' AND table_schema = DATABASE());
SET @sql := IF(@exist = 0, 'ALTER TABLE reservation_items ADD PRIMARY KEY (ReservationItemID)', 'SELECT "Primary Key already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

ALTER TABLE reservation_items MODIFY ReservationItemID int(10) NOT NULL AUTO_INCREMENT;

SELECT 'Database repair completed successfully.' AS Status;
