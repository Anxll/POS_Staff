-- ============================================
-- VERIFY AND FIX PRODUCT INGREDIENTS
-- ============================================

-- Step 1: Check if product_ingredients table is empty
SELECT COUNT(*) AS TotalProductIngredients FROM product_ingredients;

-- Step 2: Check if ingredients table has data
SELECT COUNT(*) AS TotalIngredients FROM ingredients;

-- Step 3: Check if products table has data
SELECT COUNT(*) AS TotalProducts FROM products;

-- Step 4: See what products exist
SELECT ProductID, ProductName, Category, Price 
FROM products 
ORDER BY ProductName 
LIMIT 20;

-- Step 5: See what ingredients exist
SELECT IngredientID, IngredientName, StockQuantity, UnitType
FROM ingredients
ORDER BY IngredientName
LIMIT 20;

-- ============================================
-- IF product_ingredients IS EMPTY, RUN THIS:
-- ============================================
-- This creates sample ingredient relationships
-- CUSTOMIZE THIS based on your actual products and ingredients!

-- Example: Burger ingredients
-- INSERT INTO product_ingredients (ProductID, IngredientID, QuantityUsed, UnitType)
-- SELECT 
--     (SELECT ProductID FROM products WHERE ProductName = 'Burger' LIMIT 1),
--     (SELECT IngredientID FROM ingredients WHERE IngredientName = 'Beef Patty' LIMIT 1),
--     150,  -- 150 grams per burger
--     'g'
-- WHERE EXISTS (SELECT 1 FROM products WHERE ProductName = 'Burger')
--   AND EXISTS (SELECT 1 FROM ingredients WHERE IngredientName = 'Beef Patty');

-- ============================================
-- QUICK FIX: Link ALL products to ONE ingredient for testing
-- ============================================
-- This will make inventory deduction work immediately
-- Replace 'Test Ingredient' with an actual ingredient name from your database

/*
INSERT INTO product_ingredients (ProductID, IngredientID, QuantityUsed, UnitType)
SELECT 
    p.ProductID,
    (SELECT IngredientID FROM ingredients LIMIT 1) AS IngredientID,
    100,  -- 100 units per product
    'g'   -- grams
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM product_ingredients pi 
    WHERE pi.ProductID = p.ProductID
);
*/

-- After inserting, verify:
SELECT 
    p.ProductName,
    i.IngredientName,
    pi.QuantityUsed,
    pi.UnitType
FROM product_ingredients pi
JOIN products p ON pi.ProductID = p.ProductID
JOIN ingredients i ON pi.IngredientID = i.IngredientID
ORDER BY p.ProductName, i.IngredientName;
