-- ========================================================================
-- DATABASE VERIFICATION QUERIES
-- ========================================================================
-- Run these to confirm your database is fully repaired
-- ========================================================================

USE tabeya_system;

-- ========================================================================
-- 1. VERIFY TABLE STRUCTURES
-- ========================================================================

SELECT '=== ORDERS TABLE STRUCTURE ===' as Section;
SHOW CREATE TABLE orders;

SELECT '=== ORDER_ITEMS TABLE STRUCTURE ===' as Section;
SHOW CREATE TABLE order_items;

SELECT '=== RESERVATIONS TABLE STRUCTURE ===' as Section;
SHOW CREATE TABLE reservations;

SELECT '=== RESERVATION_ITEMS TABLE STRUCTURE ===' as Section;
SHOW CREATE TABLE reservation_items;

-- ========================================================================
-- 2. CHECK FOR DUPLICATES
-- ========================================================================

SELECT '=== DUPLICATE CHECK ===' as Section;

SELECT 'orders' as table_name, OrderID, COUNT(*) as duplicate_count 
FROM orders 
GROUP BY OrderID 
HAVING COUNT(*) > 1

UNION ALL

SELECT 'order_items', OrderItemID, COUNT(*) 
FROM order_items 
GROUP BY OrderItemID 
HAVING COUNT(*) > 1

UNION ALL

SELECT 'reservations', ReservationID, COUNT(*) 
FROM reservations 
GROUP BY ReservationID 
HAVING COUNT(*) > 1

UNION ALL

SELECT 'reservation_items', ReservationItemID, COUNT(*) 
FROM reservation_items 
GROUP BY ReservationItemID 
HAVING COUNT(*) > 1;

-- If this returns empty, you're good! ✅

-- ========================================================================
-- 3. VERIFY AUTO_INCREMENT VALUES
-- ========================================================================

SELECT '=== AUTO_INCREMENT STATUS ===' as Section;

SELECT 
    TABLE_NAME,
    AUTO_INCREMENT,
    CASE 
        WHEN AUTO_INCREMENT IS NULL THEN '❌ NOT SET'
        ELSE '✅ CONFIGURED'
    END as status
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'tabeya_system'
AND TABLE_NAME IN ('orders', 'order_items', 'reservations', 'reservation_items')
ORDER BY TABLE_NAME;

-- ========================================================================
-- 4. VERIFY FOREIGN KEYS
-- ========================================================================

SELECT '=== FOREIGN KEY CONSTRAINTS ===' as Section;

SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    '✅ Present' as status
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'tabeya_system'
AND REFERENCED_TABLE_NAME IS NOT NULL
AND TABLE_NAME IN ('order_items', 'reservation_items')
ORDER BY TABLE_NAME;

-- ========================================================================
-- 5. CHECK SAMPLE DATA
-- ========================================================================

SELECT '=== RECENT ORDERS ===' as Section;
SELECT OrderID, OrderDate, TotalAmount, OrderStatus, CreatedDate
FROM orders
ORDER BY OrderID DESC
LIMIT 5;

SELECT '=== ORDER ITEMS COUNT ===' as Section;
SELECT COUNT(*) as total_order_items FROM order_items;

SELECT '=== RESERVATIONS COUNT ===' as Section;
SELECT COUNT(*) as total_reservations FROM reservations;

-- ========================================================================
-- 6. VERIFY STORED PROCEDURES EXIST
-- ========================================================================

SELECT '=== CRITICAL STORED PROCEDURES ===' as Section;

SELECT 
    ROUTINE_NAME,
    '✅ Present' as status
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'tabeya_system'
AND ROUTINE_TYPE = 'PROCEDURE'
AND ROUTINE_NAME IN (
    'DeductIngredientsForPOSOrder',
    'DeductIngredientsForReservation',
    'AddInventoryBatch',
    'DiscardBatch',
    'LogBatchEdit',
    'LogInventoryMovement',
    'InsertInventoryMovement'
)
ORDER BY ROUTINE_NAME;

-- ========================================================================
-- 7. VERIFY TRIGGERS
-- ========================================================================

SELECT '=== DATABASE TRIGGERS ===' as Section;

SELECT 
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    EVENT_OBJECT_TABLE,
    ACTION_TIMING,
    '✅ Active' as status
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'tabeya_system'
AND TRIGGER_NAME IN ('tr_order_completed', 'tr_reservation_confirmed')
ORDER BY TRIGGER_NAME;

-- ========================================================================
-- FINAL STATUS
-- ========================================================================

SELECT '=== DATABASE STATUS ===' as Section;

SELECT 
    CASE 
        WHEN (
            SELECT COUNT(*) FROM information_schema.TABLES 
            WHERE TABLE_SCHEMA = 'tabeya_system' 
            AND TABLE_NAME IN ('orders', 'order_items', 'reservations', 'reservation_items')
            AND AUTO_INCREMENT IS NOT NULL
        ) = 4 THEN '✅ FULLY CONFIGURED'
        ELSE '⚠️ INCOMPLETE'
    END as database_status;

SELECT '✅ VERIFICATION COMPLETE!' as Result;
