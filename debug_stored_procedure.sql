-- ============================================
-- DEBUG STORED PROCEDURE EXECUTION
-- ============================================

-- Step 1: Get the most recent order
SELECT OrderID, OrderDate, OrderTime, OrderStatus, OrderSource
FROM orders
ORDER BY OrderID DESC
LIMIT 1;

-- Step 2: Check order items for that order
-- Replace XXX with the OrderID from Step 1
SELECT oi.OrderItemID, oi.ProductName, oi.Quantity, oi.UnitPrice
FROM order_items oi
WHERE oi.OrderID = XXX;  -- Replace XXX

-- Step 3: Check if those products have ingredients
-- Replace 'Product Name' with actual product name from Step 2
SELECT 
    p.ProductID,
    p.ProductName,
    pi.IngredientID,
    i.IngredientName,
    pi.QuantityUsed,
    pi.UnitType
FROM products p
JOIN product_ingredients pi ON p.ProductID = pi.ProductID
JOIN ingredients i ON pi.IngredientID = i.IngredientID
WHERE p.ProductName = 'Product Name';  -- Replace with actual name

-- Step 4: Check if those ingredients have active batches
-- Replace YYY with IngredientID from Step 3
SELECT 
    BatchID,
    BatchNumber,
    StockQuantity,
    BatchStatus,
    PurchaseDate
FROM inventory_batches
WHERE IngredientID = YYY  -- Replace YYY
  AND BatchStatus = 'Active'
  AND StockQuantity > 0
ORDER BY PurchaseDate ASC;

-- Step 5: Manually test the stored procedure
-- Replace XXX with actual OrderID
SET @test_order_id = XXX;  -- Replace XXX
CALL DeductIngredientsForPOSOrder(@test_order_id);

-- Step 6: Check if it inserted anything
SELECT * FROM order_ingredient_usage
WHERE OrderID = XXX  -- Replace XXX
ORDER BY OrderItemID;

-- Step 7: Check for SQL errors
SHOW WARNINGS;
SHOW ERRORS;

-- ============================================
-- ALTERNATIVE: Test with a simple INSERT
-- ============================================
-- This bypasses the SP to test if the table itself works

-- First, get some IDs
SELECT 
    (SELECT OrderID FROM orders ORDER BY OrderID DESC LIMIT 1) AS TestOrderID,
    (SELECT OrderItemID FROM order_items ORDER BY OrderItemID DESC LIMIT 1) AS TestOrderItemID,
    (SELECT BatchID FROM inventory_batches WHERE BatchStatus = 'Active' LIMIT 1) AS TestBatchID,
    (SELECT IngredientID FROM ingredients LIMIT 1) AS TestIngredientID;

-- Then try a direct INSERT (use IDs from above)
-- INSERT INTO order_ingredient_usage 
-- (OrderID, OrderItemID, BatchID, IngredientID, QuantityUsed, UnitType)
-- VALUES (XXX, YYY, ZZZ, AAA, 10.00, 'g');

-- If this works, the table is fine and the issue is in the SP logic
