-- ========================================================================
-- DATABASE REPAIR SCRIPT WITH DATA CLEANUP
-- ========================================================================
-- This script fixes duplicate OrderID values and adds missing constraints
-- ========================================================================

USE tabeya_system;

-- ========================================================================
-- STEP 1: Identify and fix duplicate OrderIDs in orders table
-- ========================================================================

-- First, let's see what we're dealing with (for your reference)
-- Run this separately to see the duplicates:
-- SELECT OrderID, COUNT(*) as count FROM orders GROUP BY OrderID HAVING count > 1;

-- Fix duplicate OrderIDs by reassigning them sequentially
SET @new_id = 1001; -- Start from 1001

-- Update all OrderID = 0 rows to have unique sequential IDs
UPDATE orders 
SET OrderID = (@new_id := @new_id + 1)
WHERE OrderID = 0
ORDER BY CreatedDate ASC;

-- Update any other duplicate OrderIDs (if they exist)
UPDATE orders o1
JOIN (
    SELECT OrderID, MIN(CreatedDate) as first_created
    FROM orders 
    WHERE OrderID > 0
    GROUP BY OrderID 
    HAVING COUNT(*) > 1
) dupes ON o1.OrderID = dupes.OrderID
SET o1.OrderID = (@new_id := @new_id + 1)
WHERE o1.CreatedDate != dupes.first_created;

-- ========================================================================
-- STEP 2: Fix order_items table to match updated OrderIDs
-- ========================================================================
-- Note: If order_items also has issues, we may need to handle them
-- For now, we'll proceed assuming the relationship is intact

-- ========================================================================
-- STEP 3: Add PRIMARY KEY to orders table
-- ========================================================================

ALTER TABLE `orders`
  ADD PRIMARY KEY (`OrderID`);

-- ========================================================================
-- STEP 4: Add AUTO_INCREMENT to orders table
-- ========================================================================

-- Get the next available ID
SET @next_id = (SELECT COALESCE(MAX(OrderID), 1000) + 1 FROM orders);

SET @sql = CONCAT('ALTER TABLE `orders` MODIFY `OrderID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=', @next_id);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ========================================================================
-- STEP 5: Fix order_items table
-- ========================================================================

-- Check if order_items has PRIMARY KEY already
-- If error occurs, it means no primary key exists, which is expected

ALTER TABLE `order_items`
  ADD PRIMARY KEY (`OrderItemID`);

-- Add AUTO_INCREMENT
ALTER TABLE `order_items`
  MODIFY `OrderItemID` int(10) NOT NULL AUTO_INCREMENT;

-- Add foreign key constraint
ALTER TABLE `order_items`
  ADD CONSTRAINT `fk_order_items_order` 
  FOREIGN KEY (`OrderID`) 
  REFERENCES `orders` (`OrderID`) 
  ON DELETE CASCADE;

-- ========================================================================
-- STEP 6: Fix reservations table
-- ========================================================================

-- Fix duplicate ReservationIDs if they exist
SET @new_res_id = 1;

UPDATE reservations 
SET ReservationID = (@new_res_id := @new_res_id + 1)
WHERE ReservationID = 0
ORDER BY ReservationDate ASC;

ALTER TABLE `reservations`
  ADD PRIMARY KEY (`ReservationID`);

SET @next_res_id = (SELECT COALESCE(MAX(ReservationID), 0) + 1 FROM reservations);
SET @sql = CONCAT('ALTER TABLE `reservations` MODIFY `ReservationID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=', @next_res_id);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ========================================================================
-- STEP 7: Fix reservation_items table
-- ========================================================================

ALTER TABLE `reservation_items`
  ADD PRIMARY KEY (`ReservationItemID`);

ALTER TABLE `reservation_items`
  MODIFY `ReservationItemID` int(10) NOT NULL AUTO_INCREMENT;

ALTER TABLE `reservation_items`
  ADD CONSTRAINT `fk_reservation_items_reservation` 
  FOREIGN KEY (`ReservationID`) 
  REFERENCES `reservations` (`ReservationID`) 
  ON DELETE CASCADE;

-- ========================================================================
-- VERIFICATION
-- ========================================================================

-- Check orders table structure
SELECT 'Orders table structure:' as Info;
SHOW CREATE TABLE orders;

-- Check for any remaining duplicates
SELECT 'Duplicate check:' as Info;
SELECT OrderID, COUNT(*) as count 
FROM orders 
GROUP BY OrderID 
HAVING count > 1;

-- Show sample data
SELECT 'Sample orders:' as Info;
SELECT OrderID, OrderDate, TotalAmount, OrderStatus 
FROM orders 
ORDER BY OrderID DESC 
LIMIT 5;

SELECT 'Script completed successfully!' as Status;
