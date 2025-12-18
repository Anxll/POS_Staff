-- ============================================
-- DIAGNOSTIC QUERIES FOR INVENTORY DEDUCTION
-- ============================================

-- 1. Check if products have ingredients defined
SELECT 
    p.ProductID,
    p.ProductName,
    COUNT(pi.IngredientID) AS IngredientCount
FROM products p
LEFT JOIN product_ingredients pi ON p.ProductID = pi.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY IngredientCount DESC, p.ProductName;

-- 2. Check specific product ingredients
SELECT 
    p.ProductName,
    i.IngredientName,
    pi.QuantityUsed,
    pi.UnitType
FROM products p
JOIN product_ingredients pi ON p.ProductID = pi.ProductID
JOIN ingredients i ON pi.IngredientID = i.IngredientID
WHERE p.ProductName = 'Burger'  -- Replace with actual product name
ORDER BY i.IngredientName;

-- 3. Check if inventory batches exist
SELECT 
    i.IngredientName,
    ib.BatchNumber,
    ib.StockQuantity,
    ib.BatchStatus,
    ib.PurchaseDate
FROM ingredients i
LEFT JOIN inventory_batches ib ON i.IngredientID = ib.IngredientID
WHERE ib.BatchStatus = 'Active' AND ib.StockQuantity > 0
ORDER BY i.IngredientName, ib.PurchaseDate;

-- 4. Check recent orders
SELECT 
    o.OrderID,
    o.OrderDate,
    o.OrderTime,
    o.OrderStatus,
    oi.ProductName,
    oi.Quantity
FROM orders o
JOIN order_items oi ON o.OrderID = oi.OrderID
WHERE o.OrderDate >= CURDATE()
ORDER BY o.OrderID DESC
LIMIT 10;

-- 5. Check if order_ingredient_usage has ANY records
SELECT COUNT(*) AS TotalRecords
FROM order_ingredient_usage;

-- 6. Check order_ingredient_usage for recent orders
-- MariaDB compatible version
SELECT 
    oiu.OrderID,
    oi.ProductName,
    i.IngredientName,
    ib.BatchNumber,
    oiu.QuantityUsed,
    oiu.UnitType
FROM order_ingredient_usage oiu
JOIN order_items oi ON oiu.OrderItemID = oi.OrderItemID
JOIN ingredients i ON oiu.IngredientID = i.IngredientID
JOIN inventory_batches ib ON oiu.BatchID = ib.BatchID
JOIN orders o ON oiu.OrderID = o.OrderID
WHERE o.OrderDate >= CURDATE()
ORDER BY oiu.OrderID DESC, i.IngredientName
LIMIT 20;

-- 7. Test stored procedure manually
-- First, get a recent OrderID
SELECT OrderID FROM orders ORDER BY OrderID DESC LIMIT 1;
-- Then replace XXX with the actual OrderID and run:
-- CALL DeductIngredientsForPOSOrder(XXX);

-- 8. Check for errors in stored procedure
SHOW WARNINGS;
SHOW ERRORS;
