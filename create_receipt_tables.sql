-- ========================================================
-- SALES RECEIPT TABLES FOR TABEYA SYSTEM
-- Compatible with tabeya_system-28.sql Schema
-- ========================================================

--
-- Table structure for table `sales_receipts`
--

CREATE TABLE `sales_receipts` (
  `ReceiptID` int(10) NOT NULL AUTO_INCREMENT COMMENT 'Unique receipt identifier',
  `OrderNumber` varchar(50) NOT NULL COMMENT 'Unique order/receipt number (e.g., VT-2025-001238)',
  `ReceiptDate` date NOT NULL COMMENT 'Date of transaction',
  `ReceiptTime` time NOT NULL COMMENT 'Time of transaction',
  
  -- Staff/Cashier Information
  `EmployeeID` int(10) DEFAULT NULL COMMENT 'Reference to employee table',
  `CashierName` varchar(100) DEFAULT NULL COMMENT 'Name of cashier/employee',
  
  -- Customer Information
  `CustomerID` int(10) DEFAULT NULL COMMENT 'Reference to customers table',
  `CustomerName` varchar(200) DEFAULT 'Walk-in Customer' COMMENT 'Customer name',
  `CustomerType` enum('Walk-in','Online','Reservation') DEFAULT 'Walk-in' COMMENT 'Type of customer',
  
  -- Financial Details
  `Subtotal` decimal(10,2) NOT NULL COMMENT 'Subtotal before tax/discount',
  `TaxAmount` decimal(10,2) DEFAULT 0.00 COMMENT 'Tax amount applied',
  `DiscountAmount` decimal(10,2) DEFAULT 0.00 COMMENT 'Discount amount applied',
  `TotalAmount` decimal(10,2) NOT NULL COMMENT 'Final total amount',
  
  -- Payment Details
  `PaymentMethod` enum('CASH','CARD','GCASH','PAYMAYA','BANK_TRANSFER') NOT NULL COMMENT 'Method of payment',
  `AmountGiven` decimal(10,2) DEFAULT NULL COMMENT 'Amount given by customer',
  `ChangeAmount` decimal(10,2) DEFAULT NULL COMMENT 'Change returned to customer',
  
  -- Transaction Details
  `TransactionStatus` enum('Completed','Cancelled','Refunded') DEFAULT 'Completed' COMMENT 'Status of transaction',
  `OrderSource` enum('POS','WEBSITE','RESERVATION') DEFAULT 'POS' COMMENT 'Source of order',
  
  -- Metadata
  `CreatedDate` datetime DEFAULT current_timestamp() COMMENT 'Record creation timestamp',
  `UpdatedDate` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last update timestamp',
  `Notes` text DEFAULT NULL COMMENT 'Additional notes about transaction',
  
  PRIMARY KEY (`ReceiptID`),
  UNIQUE KEY `UQ_OrderNumber` (`OrderNumber`),
  KEY `IDX_ReceiptDate` (`ReceiptDate`),
  KEY `IDX_EmployeeID` (`EmployeeID`),
  KEY `IDX_CustomerID` (`CustomerID`),
  KEY `IDX_TransactionStatus` (`TransactionStatus`)
  
  -- Foreign key constraints removed to allow independent table creation
  -- Add these manually later if needed:
  -- CONSTRAINT `FK_SalesReceipts_Employee` FOREIGN KEY (`EmployeeID`) 
  --   REFERENCES `employee` (`EmployeeID`) ON DELETE SET NULL ON UPDATE CASCADE,
  -- CONSTRAINT `FK_SalesReceipts_Customer` FOREIGN KEY (`CustomerID`) 
  --   REFERENCES `customers` (`CustomerID`) ON DELETE SET NULL ON UPDATE CASCADE
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Main sales receipt/invoice records';

-- --------------------------------------------------------

--
-- Table structure for table `receipt_items`
--

CREATE TABLE `receipt_items` (
  `ReceiptItemID` int(10) NOT NULL AUTO_INCREMENT COMMENT 'Unique receipt item identifier',
  `ReceiptID` int(10) NOT NULL COMMENT 'Reference to sales_receipts table',
  
  -- Item Details
  `ItemName` varchar(200) NOT NULL COMMENT 'Name of the product/item',
  `ProductID` int(10) DEFAULT NULL COMMENT 'Reference to products table if exists',
  `Quantity` int(10) NOT NULL COMMENT 'Quantity ordered',
  `UnitPrice` decimal(10,2) NOT NULL COMMENT 'Price per unit',
  `LineTotal` decimal(10,2) NOT NULL COMMENT 'Total for this line (Quantity × UnitPrice)',
  
  -- Inventory Tracking
  `BatchNumber` varchar(50) DEFAULT NULL COMMENT 'Batch number deducted from inventory',
  `QtyDeducted` int(10) NOT NULL COMMENT 'Quantity deducted from inventory',
  
  -- Item Categorization
  `ItemCategory` varchar(100) DEFAULT NULL COMMENT 'Category of item (e.g., Food, Beverage, Combo)',
  `ItemType` enum('Single','Combo','Add-on') DEFAULT 'Single' COMMENT 'Type of item',
  
  -- Metadata
  `CreatedDate` datetime DEFAULT current_timestamp() COMMENT 'Record creation timestamp',
  `Notes` text DEFAULT NULL COMMENT 'Additional notes about this item',
  
  PRIMARY KEY (`ReceiptItemID`),
  KEY `IDX_ReceiptID` (`ReceiptID`),
  KEY `IDX_ProductID` (`ProductID`),
  KEY `IDX_BatchNumber` (`BatchNumber`)
  
  -- Foreign key constraint removed to allow independent table creation
  -- Add this manually later if needed:
  -- CONSTRAINT `FK_ReceiptItems_Receipt` FOREIGN KEY (`ReceiptID`) 
  --   REFERENCES `sales_receipts` (`ReceiptID`) ON DELETE CASCADE ON UPDATE CASCADE
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Line items for each sales receipt';

-- ========================================================
-- SAMPLE DATA BASED ON PROVIDED RECEIPT
-- Order No.: VT-2025-001238
-- ========================================================

-- Insert main receipt record
INSERT INTO `sales_receipts` (
  `OrderNumber`, `ReceiptDate`, `ReceiptTime`, `CashierName`, 
  `CustomerName`, `CustomerType`, `Subtotal`, `TaxAmount`, 
  `TotalAmount`, `PaymentMethod`, `AmountGiven`, `ChangeAmount`, 
  `OrderSource`, `CreatedDate`
) VALUES (
  'VT-2025-001238',
  '2025-11-27',
  '11:32:00',
  'Staff 01',
  'Walk-in Customer',
  'Walk-in',
  225.00,
  27.00,  -- Calculated as 252.00 - 225.00
  252.00,
  'CASH',
  300.00,
  48.00,
  'POS',
  '2025-11-27 11:32:00'
);

-- Get the receipt ID for inserting line items
SET @receipt_id = LAST_INSERT_ID();

-- Insert receipt line items
INSERT INTO `receipt_items` (
  `ReceiptID`, `ItemName`, `Quantity`, `UnitPrice`, `LineTotal`, 
  `BatchNumber`, `QtyDeducted`, `ItemCategory`, `CreatedDate`
) VALUES 
  (@receipt_id, 'Coca-Cola (1.5L)', 1, 45.00, 45.00, 
   'BATCH-CC01', 1, 'Beverage', '2025-11-27 11:32:00'),
   
  (@receipt_id, 'Nissin Cup Noodles', 2, 15.00, 30.00, 
   'BATCH-NISSIN03', 2, 'Food', '2025-11-27 11:32:00'),
   
  (@receipt_id, 'Tender Juicy Hotdog (Pack)', 1, 120.00, 120.00, 
   'BATCH-TJ02', 1, 'Food', '2025-11-27 11:32:00');

-- ========================================================
-- HELPFUL VIEWS FOR REPORTING
-- ========================================================

--
-- View: Daily Sales Summary
--
CREATE OR REPLACE VIEW `v_daily_sales_summary` AS
SELECT 
  `ReceiptDate` AS `SalesDate`,
  COUNT(*) AS `TotalReceipts`,
  SUM(`Subtotal`) AS `TotalSubtotal`,
  SUM(`TaxAmount`) AS `TotalTax`,
  SUM(`DiscountAmount`) AS `TotalDiscounts`,
  SUM(`TotalAmount`) AS `TotalSales`,
  AVG(`TotalAmount`) AS `AverageSale`,
  COUNT(DISTINCT `EmployeeID`) AS `ActiveCashiers`,
  SUM(CASE WHEN `PaymentMethod` = 'CASH' THEN 1 ELSE 0 END) AS `CashTransactions`,
  SUM(CASE WHEN `PaymentMethod` = 'CARD' THEN 1 ELSE 0 END) AS `CardTransactions`,
  SUM(CASE WHEN `PaymentMethod` = 'GCASH' THEN 1 ELSE 0 END) AS `GCashTransactions`
FROM `sales_receipts`
WHERE `TransactionStatus` = 'Completed'
GROUP BY `ReceiptDate`
ORDER BY `ReceiptDate` DESC;

--
-- View: Cashier Performance
--
CREATE OR REPLACE VIEW `v_cashier_performance` AS
SELECT 
  `EmployeeID`,
  `CashierName`,
  `ReceiptDate`,
  COUNT(*) AS `TransactionCount`,
  SUM(`TotalAmount`) AS `TotalSales`,
  AVG(`TotalAmount`) AS `AverageTransaction`,
  MIN(`TotalAmount`) AS `MinTransaction`,
  MAX(`TotalAmount`) AS `MaxTransaction`
FROM `sales_receipts`
WHERE `TransactionStatus` = 'Completed'
GROUP BY `EmployeeID`, `CashierName`, `ReceiptDate`
ORDER BY `ReceiptDate` DESC, `TotalSales` DESC;

--
-- View: Receipt Details (Full Receipt with Items)
--
CREATE OR REPLACE VIEW `v_receipt_details` AS
SELECT 
  sr.`ReceiptID`,
  sr.`OrderNumber`,
  sr.`ReceiptDate`,
  sr.`ReceiptTime`,
  sr.`CashierName`,
  sr.`CustomerName`,
  sr.`CustomerType`,
  ri.`ItemName`,
  ri.`Quantity`,
  ri.`UnitPrice`,
  ri.`LineTotal`,
  ri.`BatchNumber`,
  ri.`QtyDeducted`,
  sr.`Subtotal`,
  sr.`TaxAmount`,
  sr.`DiscountAmount`,
  sr.`TotalAmount`,
  sr.`PaymentMethod`,
  sr.`AmountGiven`,
  sr.`ChangeAmount`,
  sr.`TransactionStatus`
FROM `sales_receipts` sr
LEFT JOIN `receipt_items` ri ON sr.`ReceiptID` = ri.`ReceiptID`
ORDER BY sr.`ReceiptDate` DESC, sr.`ReceiptTime` DESC;

-- ========================================================
-- USEFUL QUERIES (COMMENTED OUT - UNCOMMENT TO USE)
-- ========================================================

/*
-- Query 1: Get full receipt details by order number
SELECT * FROM `v_receipt_details`
WHERE `OrderNumber` = 'VT-2025-001238';

-- Query 2: Today's sales summary
SELECT * FROM `v_daily_sales_summary`
WHERE `SalesDate` = CURDATE();

-- Query 3: Cashier performance for today
SELECT * FROM `v_cashier_performance`
WHERE `ReceiptDate` = CURDATE();

-- Query 4: Top selling items (by quantity)
SELECT 
  `ItemName`,
  SUM(`Quantity`) AS `TotalSold`,
  SUM(`LineTotal`) AS `TotalRevenue`,
  COUNT(DISTINCT `ReceiptID`) AS `TimesOrdered`
FROM `receipt_items`
GROUP BY `ItemName`
ORDER BY `TotalSold` DESC
LIMIT 20;

-- Query 5: Payment method distribution for a date range
SELECT 
  `PaymentMethod`,
  COUNT(*) AS `TransactionCount`,
  SUM(`TotalAmount`) AS `TotalAmount`,
  ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM `sales_receipts` WHERE `ReceiptDate` BETWEEN '2025-11-01' AND '2025-11-30')), 2) AS `Percentage`
FROM `sales_receipts`
WHERE `ReceiptDate` BETWEEN '2025-11-01' AND '2025-11-30'
  AND `TransactionStatus` = 'Completed'
GROUP BY `PaymentMethod`
ORDER BY `TransactionCount` DESC;

-- Query 6: Hourly sales pattern
SELECT 
  HOUR(`ReceiptTime`) AS `Hour`,
  COUNT(*) AS `Transactions`,
  SUM(`TotalAmount`) AS `Sales`
FROM `sales_receipts`
WHERE `ReceiptDate` = CURDATE()
  AND `TransactionStatus` = 'Completed'
GROUP BY HOUR(`ReceiptTime`)
ORDER BY `Hour`;

-- Query 7: Find receipts with specific items
SELECT DISTINCT
  sr.`OrderNumber`,
  sr.`ReceiptDate`,
  sr.`CashierName`,
  sr.`TotalAmount`
FROM `sales_receipts` sr
INNER JOIN `receipt_items` ri ON sr.`ReceiptID` = ri.`ReceiptID`
WHERE ri.`ItemName` LIKE '%Coca-Cola%';

-- Query 8: Average basket size (items per receipt)
SELECT 
  `ReceiptDate`,
  COUNT(DISTINCT ri.`ReceiptID`) AS `TotalReceipts`,
  COUNT(*) AS `TotalItems`,
  ROUND(COUNT(*) / COUNT(DISTINCT ri.`ReceiptID`), 2) AS `AvgItemsPerReceipt`
FROM `sales_receipts` sr
INNER JOIN `receipt_items` ri ON sr.`ReceiptID` = ri.`ReceiptID`
WHERE sr.`TransactionStatus` = 'Completed'
GROUP BY `ReceiptDate`
ORDER BY `ReceiptDate` DESC;

-- Query 9: Inventory deduction tracking
SELECT 
  ri.`BatchNumber`,
  ri.`ItemName`,
  SUM(ri.`QtyDeducted`) AS `TotalDeducted`,
  COUNT(DISTINCT sr.`ReceiptID`) AS `TimesUsed`,
  MIN(sr.`ReceiptDate`) AS `FirstUsed`,
  MAX(sr.`ReceiptDate`) AS `LastUsed`
FROM `receipt_items` ri
INNER JOIN `sales_receipts` sr ON ri.`ReceiptID` = sr.`ReceiptID`
WHERE sr.`TransactionStatus` = 'Completed'
  AND ri.`BatchNumber` IS NOT NULL
GROUP BY ri.`BatchNumber`, ri.`ItemName`
ORDER BY `TotalDeducted` DESC;

-- Query 10: Revenue by customer type
SELECT 
  `CustomerType`,
  COUNT(*) AS `TransactionCount`,
  SUM(`TotalAmount`) AS `TotalRevenue`,
  AVG(`TotalAmount`) AS `AvgTransactionValue`
FROM `sales_receipts`
WHERE `TransactionStatus` = 'Completed'
  AND `ReceiptDate` BETWEEN '2025-11-01' AND '2025-11-30'
GROUP BY `CustomerType`
ORDER BY `TotalRevenue` DESC;
*/

-- ========================================================
-- END OF RECEIPT TABLES SCRIPT
-- ========================================================
