-- ========================================================================
-- CRITICAL FIX: Missing Table Constraints for tabeya_system Database
-- ========================================================================
-- The exported SQL file is incomplete. It's missing PRIMARY KEY and 
-- AUTO_INCREMENT constraints for core tables: orders, order_items, 
-- reservations, reservation_items, products, customers, and employee.
-- 
-- This script adds the missing constraints.
-- ========================================================================

USE tabeya_system;

-- ========================================================================
-- 1. ORDERS TABLE
-- ========================================================================

-- Add PRIMARY KEY
ALTER TABLE `orders`
  ADD PRIMARY KEY (`OrderID`);

-- Add AUTO_INCREMENT
ALTER TABLE `orders`
  MODIFY `OrderID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1001;

-- ========================================================================
-- 2. ORDER_ITEMS TABLE
-- ========================================================================

-- Add PRIMARY KEY
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`OrderItemID`);

-- Add AUTO_INCREMENT
ALTER TABLE `order_items`
  MODIFY `OrderItemID` int(10) NOT NULL AUTO_INCREMENT;

-- Add foreign key constraint
ALTER TABLE `order_items`
  ADD CONSTRAINT `fk_order_items_order` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE;

-- ========================================================================
-- 3. RESERVATIONS TABLE
-- ========================================================================

-- Add PRIMARY KEY
ALTER TABLE `reservations`
  ADD PRIMARY KEY (`ReservationID`);

-- Add AUTO_INCREMENT
ALTER TABLE `reservations`
  MODIFY `ReservationID` int(10) NOT NULL AUTO_INCREMENT;

-- ========================================================================
-- 4. RESERVATION_ITEMS TABLE
-- ========================================================================

-- Add PRIMARY KEY
ALTER TABLE `reservation_items`
  ADD PRIMARY KEY (`ReservationItemID`);

-- Add AUTO_INCREMENT
ALTER TABLE `reservation_items`
  MODIFY `ReservationItemID` int(10) NOT NULL AUTO_INCREMENT;

-- Add foreign key constraint
ALTER TABLE `reservation_items`
  ADD CONSTRAINT `fk_reservation_items_reservation` FOREIGN KEY (`ReservationID`) REFERENCES `reservations` (`ReservationID`) ON DELETE CASCADE;

-- ========================================================================
-- 5. PRODUCTS TABLE (if not already constrained)
-- ========================================================================

-- Add PRIMARY KEY if missing
ALTER TABLE `products`
  ADD PRIMARY KEY (`ProductID`);

-- Add AUTO_INCREMENT if missing
ALTER TABLE `products`
  MODIFY `ProductID` int(10) NOT NULL AUTO_INCREMENT;

-- ========================================================================
-- 6. CUSTOMERS TABLE (if not already constrained)
-- ========================================================================

-- Add PRIMARY KEY if missing
ALTER TABLE `customers`
  ADD PRIMARY KEY (`CustomerID`);

-- Add AUTO_INCREMENT if missing
ALTER TABLE `customers`
  MODIFY `CustomerID` int(10) NOT NULL AUTO_INCREMENT;

-- ========================================================================
-- 7. EMPLOYEE TABLE (if not already constrained)
-- ========================================================================

-- Add PRIMARY KEY if missing
ALTER TABLE `employee`
  ADD PRIMARY KEY (`EmployeeID`);

-- Add AUTO_INCREMENT if missing
ALTER TABLE `employee`
  MODIFY `EmployeeID` int(10) NOT NULL AUTO_INCREMENT;

-- ========================================================================
-- VERIFICATION QUERIES
-- ========================================================================
-- Run these to verify constraints were added successfully:

-- Check orders table
SHOW CREATE TABLE orders;

-- Check order_items table
SHOW CREATE TABLE order_items;

-- Check reservations table
SHOW CREATE TABLE reservations;

-- Check reservation_items table
SHOW CREATE TABLE reservation_items;

-- ========================================================================
-- END OF FIX SCRIPT
-- ========================================================================
