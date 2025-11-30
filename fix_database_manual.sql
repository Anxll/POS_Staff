-- ========================================================================
-- MANUAL DATABASE REPAIR SCRIPT (Run Step-by-Step)
-- ========================================================================
-- Run each section separately in phpMyAdmin to see progress
-- ========================================================================

USE tabeya_system;

-- ========================================================================
-- SECTION 1: CHECK CURRENT STATE
-- ========================================================================
-- Run this first to see what we're dealing with

SELECT 'Current Orders Table Structure:' as Info;
SHOW CREATE TABLE orders;

SELECT 'Duplicate OrderIDs:' as Info;
SELECT OrderID, COUNT(*) as count 
FROM orders 
GROUP BY OrderID 
HAVING count > 1;

-- ========================================================================
-- SECTION 2: REMOVE AUTO_INCREMENT FROM orders (if exists)
-- ========================================================================
-- Run this section if OrderID has AUTO_INCREMENT in Section 1 results

ALTER TABLE `orders` 
MODIFY `OrderID` int(10) NOT NULL;

-- ========================================================================
-- SECTION 3: DROP PRIMARY KEY FROM orders (if exists)
-- ========================================================================
-- Run this if PRIMARY KEY exists (check Section 1 results)

ALTER TABLE `orders` DROP PRIMARY KEY;

-- ========================================================================
-- SECTION 4: FIX DUPLICATE OrderIDs
-- ========================================================================
-- This assigns unique IDs to all rows

SET @new_id = 1000;

UPDATE orders 
SET OrderID = (@new_id := @new_id + 1)
ORDER BY COALESCE(CreatedDate, NOW()) ASC;

-- Verify no duplicates
SELECT 'After Fix - Duplicate Check:' as Info;
SELECT OrderID, COUNT(*) as count 
FROM orders 
GROUP BY OrderID 
HAVING count > 1;

-- ========================================================================
-- SECTION 5: ADD PRIMARY KEY AND AUTO_INCREMENT
-- ========================================================================
-- Now add constraints

ALTER TABLE `orders`
  ADD PRIMARY KEY (`OrderID`),
  MODIFY `OrderID` int(10) NOT NULL AUTO_INCREMENT;

-- Verify
SELECT 'Final Orders Table Structure:' as Info;
SHOW CREATE TABLE orders;

-- ========================================================================
-- SECTION 6: FIX order_items
-- ========================================================================

-- Remove AUTO_INCREMENT if exists
ALTER TABLE `order_items` 
MODIFY `OrderItemID` int(10) NOT NULL;

-- Drop PRIMARY KEY if exists
ALTER TABLE `order_items` DROP PRIMARY KEY;

-- Fix duplicates
SET @new_oi = 0;
UPDATE order_items 
SET OrderItemID = (@new_oi := @new_oi + 1)
ORDER BY OrderID ASC;

-- Add constraints
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`OrderItemID`),
  MODIFY `OrderItemID` int(10) NOT NULL AUTO_INCREMENT;

-- ========================================================================
-- SECTION 7: FIX reservations
-- ========================================================================

ALTER TABLE `reservations` 
MODIFY `ReservationID` int(10) NOT NULL;

ALTER TABLE `reservations` DROP PRIMARY KEY;

SET @new_res = 0;
UPDATE reservations 
SET ReservationID = (@new_res := @new_res + 1)
ORDER BY COALESCE(ReservationDate, NOW()) ASC;

ALTER TABLE `reservations`
  ADD PRIMARY KEY (`ReservationID`),
  MODIFY `ReservationID` int(10) NOT NULL AUTO_INCREMENT;

-- ========================================================================
-- SECTION 8: FIX reservation_items
-- ========================================================================

ALTER TABLE `reservation_items` 
MODIFY `ReservationItemID` int(10) NOT NULL;

ALTER TABLE `reservation_items` DROP PRIMARY KEY;

SET @new_ri = 0;
UPDATE reservation_items 
SET ReservationItemID = (@new_ri := @new_ri + 1)
ORDER BY ReservationID ASC;

ALTER TABLE `reservation_items`
  ADD PRIMARY KEY (`ReservationItemID`),
  MODIFY `ReservationItemID` int(10) NOT NULL AUTO_INCREMENT;

-- ========================================================================
-- SECTION 9: VERIFY EVERYTHING
-- ========================================================================

SELECT '=== VERIFICATION ===' as Status;

SELECT 'orders table' as Table_Name;
SHOW CREATE TABLE orders;

SELECT 'order_items table' as Table_Name;
SHOW CREATE TABLE order_items;

SELECT '✅ ALL DONE!' as Status;
