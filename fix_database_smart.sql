-- ========================================================================
-- SMART DATABASE REPAIR SCRIPT
-- ========================================================================
-- This script safely repairs the database regardless of current state
-- ========================================================================

USE tabeya_system;

-- ========================================================================
-- STEP 1: DROP EXISTING PRIMARY KEYS (if they exist)
-- ========================================================================

-- Drop orders PRIMARY KEY if exists
SET @drop_pk = (
    SELECT COUNT(*) 
    FROM information_schema.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = 'tabeya_system' 
    AND TABLE_NAME = 'orders' 
    AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);

SET @sql = IF(@drop_pk > 0, 
    'ALTER TABLE `orders` DROP PRIMARY KEY', 
    'SELECT "No PRIMARY KEY to drop on orders" as Status'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ========================================================================
-- STEP 2: FIX DUPLICATE OrderIDs
-- ========================================================================

-- Find and fix all duplicate/zero OrderIDs
SET @new_id = 1001;

-- Fix OrderID = 0 rows
UPDATE orders 
SET OrderID = (@new_id := @new_id + 1)
WHERE OrderID = 0
ORDER BY CreatedDate ASC;

-- Fix other duplicates (keep earliest, renumber rest)
CREATE TEMPORARY TABLE IF NOT EXISTS temp_order_fixes AS
SELECT o1.OrderID as old_id, 
       o1.CreatedDate,
       (@new_id := @new_id + 1) as new_id
FROM orders o1
WHERE EXISTS (
    SELECT 1 FROM orders o2 
    WHERE o2.OrderID = o1.OrderID 
    AND o2.CreatedDate < o1.CreatedDate
);

UPDATE orders o
JOIN temp_order_fixes t ON o.OrderID = t.old_id AND o.CreatedDate = t.CreatedDate
SET o.OrderID = t.new_id;

DROP TEMPORARY TABLE IF EXISTS temp_order_fixes;

-- ========================================================================
-- STEP 3: ADD PRIMARY KEY AND AUTO_INCREMENT to orders
-- ========================================================================

ALTER TABLE `orders`
  ADD PRIMARY KEY (`OrderID`);

-- Set AUTO_INCREMENT to next available ID
SET @next_id = (SELECT COALESCE(MAX(OrderID), 1000) + 1 FROM orders);
SET @sql = CONCAT('ALTER TABLE `orders` MODIFY `OrderID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=', @next_id);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ========================================================================
-- STEP 4: FIX order_items table
-- ========================================================================

-- Drop PRIMARY KEY if exists
SET @drop_oi_pk = (
    SELECT COUNT(*) 
    FROM information_schema.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = 'tabeya_system' 
    AND TABLE_NAME = 'order_items' 
    AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);

SET @sql = IF(@drop_oi_pk > 0, 
    'ALTER TABLE `order_items` DROP PRIMARY KEY', 
    'SELECT "No PRIMARY KEY to drop on order_items" as Status'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Fix duplicate OrderItemIDs
SET @new_oi_id = 1;
UPDATE order_items 
SET OrderItemID = (@new_oi_id := @new_oi_id + 1)
WHERE OrderItemID = 0
ORDER BY OrderID ASC;

-- Add PRIMARY KEY
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`OrderItemID`);

-- Add AUTO_INCREMENT
ALTER TABLE `order_items`
  MODIFY `OrderItemID` int(10) NOT NULL AUTO_INCREMENT;

-- Add foreign key (drop first if exists)
SET @fk_exists = (
    SELECT COUNT(*) 
    FROM information_schema.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = 'tabeya_system' 
    AND TABLE_NAME = 'order_items' 
    AND CONSTRAINT_NAME = 'fk_order_items_order'
);

SET @sql = IF(@fk_exists > 0, 
    'ALTER TABLE `order_items` DROP FOREIGN KEY `fk_order_items_order`', 
    'SELECT "No FK to drop" as Status'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

ALTER TABLE `order_items`
  ADD CONSTRAINT `fk_order_items_order` 
  FOREIGN KEY (`OrderID`) 
  REFERENCES `orders` (`OrderID`) 
  ON DELETE CASCADE;

-- ========================================================================
-- STEP 5: FIX reservations table
-- ========================================================================

-- Drop PRIMARY KEY if exists
SET @drop_res_pk = (
    SELECT COUNT(*) 
    FROM information_schema.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = 'tabeya_system' 
    AND TABLE_NAME = 'reservations' 
    AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);

SET @sql = IF(@drop_res_pk > 0, 
    'ALTER TABLE `reservations` DROP PRIMARY KEY', 
    'SELECT "No PRIMARY KEY to drop on reservations" as Status'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Fix duplicate ReservationIDs
SET @new_res_id = 1;
UPDATE reservations 
SET ReservationID = (@new_res_id := @new_res_id + 1)
WHERE ReservationID = 0
ORDER BY ReservationDate ASC;

-- Add PRIMARY KEY
ALTER TABLE `reservations`
  ADD PRIMARY KEY (`ReservationID`);

-- Add AUTO_INCREMENT
SET @next_res_id = (SELECT COALESCE(MAX(ReservationID), 0) + 1 FROM reservations);
SET @sql = CONCAT('ALTER TABLE `reservations` MODIFY `ReservationID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=', @next_res_id);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ========================================================================
-- STEP 6: FIX reservation_items table
-- ========================================================================

-- Drop PRIMARY KEY if exists
SET @drop_ri_pk = (
    SELECT COUNT(*) 
    FROM information_schema.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = 'tabeya_system' 
    AND TABLE_NAME = 'reservation_items' 
    AND CONSTRAINT_TYPE = 'PRIMARY KEY'
);

SET @sql = IF(@drop_ri_pk > 0, 
    'ALTER TABLE `reservation_items` DROP PRIMARY KEY', 
    'SELECT "No PRIMARY KEY to drop on reservation_items" as Status'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Fix duplicates if needed
SET @new_ri_id = 1;
UPDATE reservation_items 
SET ReservationItemID = (@new_ri_id := @new_ri_id + 1)
WHERE ReservationItemID = 0 OR ReservationItemID IS NULL
ORDER BY ReservationID ASC;

-- Add PRIMARY KEY
ALTER TABLE `reservation_items`
  ADD PRIMARY KEY (`ReservationItemID`);

-- Add AUTO_INCREMENT
ALTER TABLE `reservation_items`
  MODIFY `ReservationItemID` int(10) NOT NULL AUTO_INCREMENT;

-- Add foreign key
SET @fk_ri_exists = (
    SELECT COUNT(*) 
    FROM information_schema.TABLE_CONSTRAINTS 
    WHERE TABLE_SCHEMA = 'tabeya_system' 
    AND TABLE_NAME = 'reservation_items' 
    AND CONSTRAINT_NAME = 'fk_reservation_items_reservation'
);

SET @sql = IF(@fk_ri_exists > 0, 
    'ALTER TABLE `reservation_items` DROP FOREIGN KEY `fk_reservation_items_reservation`', 
    'SELECT "No FK to drop" as Status'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

ALTER TABLE `reservation_items`
  ADD CONSTRAINT `fk_reservation_items_reservation` 
  FOREIGN KEY (`ReservationID`) 
  REFERENCES `reservations` (`ReservationID`) 
  ON DELETE CASCADE;

-- ========================================================================
-- VERIFICATION
-- ========================================================================

SELECT '=== ORDERS TABLE ===' as Info;
SHOW CREATE TABLE orders\G

SELECT '=== DUPLICATE CHECK ===' as Info;
SELECT 'orders' as table_name, OrderID, COUNT(*) as count 
FROM orders 
GROUP BY OrderID 
HAVING count > 1
UNION ALL
SELECT 'order_items', OrderItemID, COUNT(*) 
FROM order_items 
GROUP BY OrderItemID 
HAVING COUNT(*) > 1;

SELECT '=== SAMPLE DATA ===' as Info;
SELECT OrderID, OrderDate, TotalAmount, OrderStatus 
FROM orders 
ORDER BY OrderID DESC 
LIMIT 5;

SELECT '✅ DATABASE REPAIR COMPLETE!' as Status;
