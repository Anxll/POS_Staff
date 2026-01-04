-- ============================================
-- CRITICAL CHECK: Product Name Mismatch
-- ============================================
-- The SP joins order_items to products by ProductName
-- If names don't match EXACTLY, the JOIN fails!

-- Step 1: Check order_items product names
SELECT DISTINCT oi.ProductName
FROM order_items oi
JOIN orders o ON oi.OrderID = o.OrderID
WHERE o.OrderDate >= CURDATE() - INTERVAL 7 DAY
ORDER BY oi.ProductName;

-- Step 2: Check products table product names  
SELECT DISTINCT ProductName
FROM products
ORDER BY ProductName;

-- Step 3: Find mismatches (names in order_items but not in products)
SELECT DISTINCT oi.ProductName AS OrderItemName
FROM order_items oi
WHERE NOT EXISTS (
    SELECT 1 FROM products p 
    WHERE p.ProductName = oi.ProductName
)
ORDER BY oi.ProductName;

-- Step 4: Check if ProductID exists in order_items
DESCRIBE order_items;

-- ============================================
-- ROOT CAUSE FOUND!
-- ============================================
-- The stored procedure does this:
-- 1. Gets ProductName from order_items
-- 2. Looks up ProductID from products table using ProductName
-- 3. Gets ingredients using ProductID
--
-- IF ProductName in order_items doesn't EXACTLY match 
-- ProductName in products table, the lookup fails!
--
-- Common issues:
-- - Extra spaces: "Burger " vs "Burger"
-- - Case sensitivity: "burger" vs "Burger"  
-- - Different names: "Cheeseburger" vs "Burger"
-- ============================================

-- Step 5: Test the exact SP logic
-- Replace with actual values from your recent order
SET @test_product_name = 'Burger';  -- From order_items

-- This is what the SP does:
SELECT ProductID INTO @v_product_id
FROM products
WHERE ProductName = @test_product_name
LIMIT 1;

SELECT @v_product_id AS FoundProductID;

-- If this returns NULL, the names don't match!

-- Step 6: If ProductID is found, check ingredients
SELECT 
    pi.IngredientID,
    i.IngredientName,
    pi.QuantityUsed,
    pi.UnitType
FROM product_ingredients pi
JOIN ingredients i ON pi.IngredientID = i.IngredientID
WHERE pi.ProductID = @v_product_id;

-- If this returns 0 rows, the product has no ingredients!
