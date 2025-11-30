-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 27, 2025 at 07:37 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `tabeya_system`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `AddInventoryBatch` (IN `p_ingredient_id` INT, IN `p_quantity` DECIMAL(10,2), IN `p_unit_type` VARCHAR(50), IN `p_cost_per_unit` DECIMAL(10,2), IN `p_expiration_date` DATE, IN `p_storage_location` VARCHAR(100), IN `p_notes` TEXT, OUT `p_batch_id` INT, OUT `p_batch_number` VARCHAR(50))   BEGIN
    DECLARE v_ingredient_code VARCHAR(10);
    DECLARE v_batch_count INT;
    DECLARE v_date_code VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_batch_id = -1;
        SET p_batch_number = 'ERROR';
    END;

    START TRANSACTION;

    -- Generate ingredient code
    SELECT UPPER(LEFT(REPLACE(IngredientName, ' ', ''), 3))
    INTO v_ingredient_code
    FROM ingredients
    WHERE IngredientID = p_ingredient_id;

    -- Batch sequence
    SELECT COUNT(*) + 1
    INTO v_batch_count
    FROM inventory_batches
    WHERE IngredientID = p_ingredient_id;

    SET v_date_code = DATE_FORMAT(NOW(), '%Y%m%d');
    SET p_batch_number = CONCAT(v_ingredient_code, '-', v_date_code, '-', LPAD(v_batch_count, 3, '0'));

    -- Insert batch (removed ReorderLevel)
    INSERT INTO inventory_batches (
        IngredientID, BatchNumber, StockQuantity, OriginalQuantity,
        UnitType, CostPerUnit, PurchaseDate, ExpirationDate,
        StorageLocation, BatchStatus, Notes
    ) VALUES (
        p_ingredient_id,
        p_batch_number,
        p_quantity,
        p_quantity,
        p_unit_type,
        p_cost_per_unit,
        NOW(),
        p_expiration_date,
        COALESCE(NULLIF(p_storage_location, ''), 'Pantry-Dry-Goods'),
        'Active',
        p_notes
    );

    SET p_batch_id = LAST_INSERT_ID();

    INSERT INTO batch_transactions (
        BatchID, TransactionType, QuantityChanged, StockBefore,
        StockAfter, Notes, TransactionDate
    ) VALUES (
        p_batch_id,
        'Purchase',
        p_quantity,
        0,
        p_quantity,
        CONCAT('Initial stock purchase on ', DATE_FORMAT(NOW(), '%Y-%m-%d'), '. ', COALESCE(p_notes, '')),
        NOW()
    );

    UPDATE ingredients
    SET StockQuantity = StockQuantity + p_quantity,
        LastRestockedDate = NOW()
    WHERE IngredientID = p_ingredient_id;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetBatchDetails` (IN `p_batch_id` INT)   BEGIN
    SELECT 
        ib.BatchID,
        ib.BatchNumber,
        ib.IngredientID,
        i.IngredientName,
        ic.CategoryName,
        ib.StockQuantity,
        ib.OriginalQuantity,
        ib.UnitType,
        ib.CostPerUnit,
        (ib.OriginalQuantity * ib.CostPerUnit) AS TotalCost,
        ib.PurchaseDate,
        ib.ExpirationDate,
        DATEDIFF(ib.ExpirationDate, CURDATE()) AS DaysUntilExpiration,
        ib.StorageLocation,
        ib.BatchStatus,
        ROUND((ib.StockQuantity / ib.OriginalQuantity) * 100, 2) AS RemainingPercent,
        ib.Notes,
        CASE 
            WHEN ib.BatchStatus = 'Expired' THEN 'EXPIRED - Remove'
            WHEN ib.BatchStatus = 'Depleted' THEN 'Depleted'
            WHEN ib.ExpirationDate IS NULL THEN 'No Expiry'
            WHEN ib.ExpirationDate <= CURDATE() THEN 'EXPIRED - Remove Now'
            WHEN DATEDIFF(ib.ExpirationDate, CURDATE()) <= 3 THEN 'CRITICAL - 3 Days'
            WHEN DATEDIFF(ib.ExpirationDate, CURDATE()) <= 7 THEN 'WARNING - 7 Days'
            WHEN DATEDIFF(ib.ExpirationDate, CURDATE()) <= 14 THEN 'Monitor - 14 Days'
            ELSE 'Fresh'
        END AS ExpirationAlert
    FROM inventory_batches ib
    JOIN ingredients i ON ib.IngredientID = i.IngredientID
    LEFT JOIN ingredient_categories ic ON i.CategoryID = ic.CategoryID
    WHERE ib.BatchID = p_batch_id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateBatchStock` (IN `p_batch_id` INT, IN `p_quantity_change` DECIMAL(10,2), IN `p_transaction_type` ENUM('Purchase','Usage','Adjustment','Discard','Transfer'), IN `p_reference_id` VARCHAR(50), IN `p_performed_by` VARCHAR(100), IN `p_reason` VARCHAR(255), IN `p_notes` TEXT)   BEGIN
    DECLARE v_ingredient_id INT;
    DECLARE v_stock_before DECIMAL(10,2);
    DECLARE v_stock_after DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- Get current stock and ingredient ID
    SELECT IngredientID, StockQuantity
    INTO v_ingredient_id, v_stock_before
    FROM inventory_batches
    WHERE BatchID = p_batch_id;
    
    -- Calculate new stock
    SET v_stock_after = v_stock_before + p_quantity_change;
    
    -- Prevent negative stock
    IF v_stock_after < 0 THEN
        SET v_stock_after = 0;
    END IF;
    
    -- Update batch stock
    UPDATE inventory_batches
    SET StockQuantity = v_stock_after,
        BatchStatus = CASE 
            WHEN v_stock_after = 0 THEN 'Depleted'
            WHEN ExpirationDate IS NOT NULL AND ExpirationDate <= CURDATE() THEN 'Expired'
            ELSE 'Active'
        END
    WHERE BatchID = p_batch_id;
    
    -- Log transaction
    INSERT INTO batch_transactions (
        BatchID,
        TransactionType,
        QuantityChanged,
        StockBefore,
        StockAfter,
        ReferenceID,
        PerformedBy,
        Reason,
        Notes,
        TransactionDate
    ) VALUES (
        p_batch_id,
        p_transaction_type,
        p_quantity_change,
        v_stock_before,
        v_stock_after,
        p_reference_id,
        p_performed_by,
        p_reason,
        p_notes,
        NOW()
    );
    
    -- Update ingredient total stock
    UPDATE ingredients
    SET StockQuantity = (
        SELECT COALESCE(SUM(StockQuantity), 0)
        FROM inventory_batches
        WHERE IngredientID = v_ingredient_id
          AND BatchStatus = 'Active'
    )
    WHERE IngredientID = v_ingredient_id;
    
    COMMIT;
    
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `active_online_customers`
-- (See below for the actual view)
--
CREATE TABLE `active_online_customers` (
`CustomerID` int(10)
,`FirstName` varchar(50)
,`LastName` varchar(50)
,`Email` varchar(100)
,`ContactNumber` varchar(20)
,`TotalOrdersCount` int(10)
,`ReservationCount` int(10)
,`LastLoginDate` datetime
,`SatisfactionRating` decimal(3,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `approved_customer_reviews`
-- (See below for the actual view)
--
CREATE TABLE `approved_customer_reviews` (
`ReviewID` int(10)
,`CustomerID` int(10)
,`DisplayName` varchar(53)
,`FirstName` varchar(50)
,`OverallRating` decimal(2,1)
,`FoodTasteRating` int(1)
,`PortionSizeRating` int(1)
,`CustomerServiceRating` int(1)
,`AmbienceRating` int(1)
,`CleanlinessRating` int(1)
,`FoodTasteComment` text
,`PortionSizeComment` text
,`CustomerServiceComment` text
,`AmbienceComment` text
,`CleanlinessComment` text
,`GeneralComment` text
,`CreatedDate` datetime
,`ApprovedDate` datetime
);

-- --------------------------------------------------------

--
-- Table structure for table `batch_transactions`
--

CREATE TABLE `batch_transactions` (
  `TransactionID` int(10) NOT NULL,
  `BatchID` int(10) NOT NULL,
  `TransactionType` enum('Purchase','Usage','Adjustment','Discard','Transfer') NOT NULL,
  `QuantityChanged` decimal(10,2) NOT NULL COMMENT 'Positive for add, negative for deduct',
  `StockBefore` decimal(10,2) NOT NULL,
  `StockAfter` decimal(10,2) NOT NULL,
  `ReferenceID` varchar(50) DEFAULT NULL COMMENT 'OrderID, AdjustmentID, etc.',
  `PerformedBy` varchar(100) DEFAULT NULL COMMENT 'Who made the transaction',
  `Reason` varchar(255) DEFAULT NULL COMMENT 'Reason for adjustment/discard',
  `Notes` text DEFAULT NULL,
  `TransactionDate` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `batch_transactions`
--

INSERT INTO `batch_transactions` (`TransactionID`, `BatchID`, `TransactionType`, `QuantityChanged`, `StockBefore`, `StockAfter`, `ReferenceID`, `PerformedBy`, `Reason`, `Notes`, `TransactionDate`) VALUES
(1, 1, 'Purchase', 25.00, 0.00, 25.00, NULL, NULL, NULL, 'Initial stock purchase from Quiapo Market on 2025-11-24', '2025-11-24 01:04:10'),
(2, 2, 'Purchase', 20.00, 0.00, 20.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-24', '2025-11-24 01:04:10'),
(3, 3, 'Purchase', 30.00, 0.00, 30.00, NULL, NULL, NULL, 'Initial stock purchase from Crown Poultry on 2025-11-23', '2025-11-24 01:04:10'),
(4, 4, 'Purchase', 15.00, 0.00, 15.00, NULL, NULL, NULL, 'Initial stock purchase from Crown Poultry on 2025-11-24', '2025-11-24 01:04:10'),
(5, 5, 'Purchase', 18.00, 0.00, 18.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-24', '2025-11-24 01:04:10'),
(6, 6, 'Purchase', 12.00, 0.00, 12.00, NULL, NULL, NULL, 'Initial stock purchase from Quiapo Market on 2025-11-23', '2025-11-24 01:04:10'),
(7, 7, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase from Navotas Fish Port on 2025-11-24', '2025-11-24 01:04:10'),
(8, 8, 'Purchase', 8.00, 0.00, 8.00, NULL, NULL, NULL, 'Initial stock purchase from Laguna Fish Farm on 2025-11-24', '2025-11-24 01:04:10'),
(9, 9, 'Purchase', 5.00, 0.00, 5.00, NULL, NULL, NULL, 'Initial stock purchase from Navotas Fish Port on 2025-11-24', '2025-11-24 01:04:10'),
(10, 10, 'Purchase', 6.00, 0.00, 6.00, NULL, NULL, NULL, 'Initial stock purchase from Navotas Fish Port on 2025-11-24', '2025-11-24 01:04:10'),
(11, 11, 'Purchase', 15.00, 0.00, 15.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-24', '2025-11-24 01:04:10'),
(12, 12, 'Purchase', 12.00, 0.00, 12.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-23', '2025-11-24 01:04:10'),
(13, 13, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase from Quiapo Market on 2025-11-24', '2025-11-24 01:04:10'),
(14, 14, 'Purchase', 8.00, 0.00, 8.00, NULL, NULL, NULL, 'Initial stock purchase from Quiapo Market on 2025-11-24', '2025-11-24 01:04:10'),
(15, 15, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-22', '2025-11-24 01:04:10'),
(16, 16, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-22', '2025-11-24 01:04:10'),
(17, 17, 'Purchase', 8.00, 0.00, 8.00, NULL, NULL, NULL, 'Initial stock purchase from Local Supplier on 2025-11-21', '2025-11-24 01:04:10'),
(18, 18, 'Purchase', 20.00, 0.00, 20.00, NULL, NULL, NULL, 'Initial stock purchase from Sari-Sari Store on 2025-11-20', '2025-11-24 01:04:10'),
(19, 19, 'Purchase', 5.00, 0.00, 5.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-20', '2025-11-24 01:04:10'),
(20, 20, 'Purchase', 24.00, 0.00, 24.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-11-17', '2025-11-24 01:04:10'),
(21, 21, 'Purchase', 20.00, 0.00, 20.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-11-17', '2025-11-24 01:04:10'),
(22, 22, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase from Local Farm on 2025-11-24', '2025-11-24 01:04:10'),
(23, 23, 'Purchase', 8.00, 0.00, 8.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-11-14', '2025-11-24 01:04:10'),
(24, 24, 'Purchase', 8.00, 0.00, 8.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-11-14', '2025-11-24 01:04:10'),
(25, 25, 'Purchase', 5.00, 0.00, 5.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-11-14', '2025-11-24 01:04:10'),
(26, 26, 'Purchase', 6.00, 0.00, 6.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-11-14', '2025-11-24 01:04:10'),
(27, 27, 'Purchase', 15.00, 0.00, 15.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-24', '2025-11-24 01:04:10'),
(28, 28, 'Purchase', 8.00, 0.00, 8.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-24', '2025-11-24 01:04:10'),
(29, 29, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-24', '2025-11-24 01:04:10'),
(30, 30, 'Purchase', 5.00, 0.00, 5.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-24', '2025-11-24 01:04:10'),
(31, 31, 'Purchase', 8.00, 0.00, 8.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-24', '2025-11-24 01:04:10'),
(32, 32, 'Purchase', 6.00, 0.00, 6.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-24', '2025-11-24 01:04:10'),
(33, 33, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase from Pasig Public Market on 2025-11-24', '2025-11-24 01:04:10'),
(34, 34, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-11-17', '2025-11-24 01:04:10'),
(35, 35, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-11-17', '2025-11-24 01:04:10'),
(36, 36, 'Purchase', 8.00, 0.00, 8.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-11-17', '2025-11-24 01:04:10'),
(37, 37, 'Purchase', 12.00, 0.00, 12.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-11-17', '2025-11-24 01:04:10'),
(38, 38, 'Purchase', 15.00, 0.00, 15.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-11-17', '2025-11-24 01:04:10'),
(39, 39, 'Purchase', 20.00, 0.00, 20.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-11-17', '2025-11-24 01:04:10'),
(40, 40, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase from Distributor on 2025-11-20', '2025-11-24 01:04:10'),
(41, 41, 'Purchase', 15.00, 0.00, 15.00, NULL, NULL, NULL, 'Initial stock purchase from Distributor on 2025-11-20', '2025-11-24 01:04:10'),
(42, 42, 'Purchase', 8.00, 0.00, 8.00, NULL, NULL, NULL, 'Initial stock purchase from Local Vendor on 2025-11-24', '2025-11-24 01:04:10'),
(43, 43, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-10-25', '2025-11-24 01:04:10'),
(44, 44, 'Purchase', 15.00, 0.00, 15.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-10-25', '2025-11-24 01:04:10'),
(45, 45, 'Purchase', 2.00, 0.00, 2.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-10-25', '2025-11-24 01:04:10'),
(46, 46, 'Purchase', 3.00, 0.00, 3.00, NULL, NULL, NULL, 'Initial stock purchase from Supermarket on 2025-10-25', '2025-11-24 01:04:10'),
(47, 102, 'Purchase', 23.00, 0.00, 23.00, NULL, NULL, NULL, 'Initial stock purchase from Direct Purchase on 2025-11-25', '2025-11-25 16:36:37'),
(48, 102, 'Discard', -23.00, 23.00, 0.00, NULL, 'System User', 'Manual Discard', 'Batch AMP-20251125-001 discarded on 11/25/2025 4:37:45 PM', '2025-11-25 16:37:45'),
(53, 105, 'Purchase', 45.00, 0.00, 45.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-26. Initial batch added on 2025-11-26', '2025-11-26 18:07:54'),
(79, 113, 'Purchase', 45.00, 0.00, 45.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. 54345', '2025-11-27 11:03:09'),
(80, 114, 'Purchase', 56.00, 0.00, 56.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. 676', '2025-11-27 11:49:39'),
(81, 115, 'Purchase', 577.00, 0.00, 577.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. 5645', '2025-11-27 11:58:46'),
(82, 119, 'Purchase', 66.00, 0.00, 66.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. 56547', '2025-11-27 12:00:18'),
(83, 122, 'Purchase', 35.00, 0.00, 35.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. 56565', '2025-11-27 12:17:03'),
(84, 123, 'Purchase', 43.00, 0.00, 43.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. Initial batch added on 11/27/2025', '2025-11-27 12:17:38'),
(85, 124, 'Purchase', 54.00, 0.00, 54.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. 45454', '2025-11-27 12:18:00'),
(86, 127, 'Purchase', 34.00, 0.00, 34.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. 56565', '2025-11-27 12:18:37'),
(87, 128, 'Purchase', 34.00, 0.00, 34.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. 5656', '2025-11-27 12:19:05'),
(88, 135, 'Purchase', 45.00, 0.00, 45.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. 56565', '2025-11-27 12:51:39'),
(89, 137, 'Purchase', 56.00, 0.00, 56.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. 56565', '2025-11-27 12:59:48'),
(90, 138, 'Purchase', 56.00, 0.00, 56.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. 676', '2025-11-27 12:59:59'),
(91, 137, 'Adjustment', -46.00, 56.00, 10.00, NULL, NULL, 'Manual Edit', 'Batch edited by user', '2025-11-27 13:00:13'),
(92, 139, 'Purchase', 34.00, 0.00, 34.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. 45345', '2025-11-27 13:15:15'),
(93, 140, 'Purchase', 34.00, 0.00, 34.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-27. 34343', '2025-11-27 13:16:13'),
(94, 139, 'Adjustment', -20.00, 34.00, 14.00, NULL, NULL, 'Manual Edit', 'Batch edited by user', '2025-11-27 13:16:28');

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE `customers` (
  `CustomerID` int(10) NOT NULL COMMENT 'Unique identifier for each customer',
  `FirstName` varchar(50) NOT NULL COMMENT 'Customer first name',
  `LastName` varchar(50) NOT NULL COMMENT 'Customer last name',
  `Email` varchar(100) DEFAULT NULL COMMENT 'Email used for account login (website only)',
  `PasswordHash` varchar(255) DEFAULT NULL COMMENT 'Encrypted password for website login (NULL for POS customers)',
  `ContactNumber` varchar(20) DEFAULT NULL COMMENT 'Customer phone number',
  `CustomerType` enum('Walk-in','Online','Reservation') NOT NULL DEFAULT 'Walk-in',
  `FeedbackCount` int(10) DEFAULT 0 COMMENT 'Number of feedbacks/reviews submitted',
  `TotalOrdersCount` int(10) DEFAULT 0 COMMENT 'Total number of orders made',
  `ReservationCount` int(10) DEFAULT 0 COMMENT 'Total number of reservations made',
  `LastTransactionDate` datetime DEFAULT NULL COMMENT 'Most recent order/reservation date',
  `LastLoginDate` datetime DEFAULT NULL COMMENT 'Last login to the online account',
  `CreatedDate` datetime DEFAULT current_timestamp() COMMENT 'Date and time when record was created',
  `AccountStatus` enum('Active','Suspended','Inactive') DEFAULT 'Active' COMMENT 'Current status of customer account',
  `SatisfactionRating` decimal(3,2) DEFAULT 0.00 COMMENT 'Average customer satisfaction rating (1–5)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `customers`
--

INSERT INTO `customers` (`CustomerID`, `FirstName`, `LastName`, `Email`, `PasswordHash`, `ContactNumber`, `CustomerType`, `FeedbackCount`, `TotalOrdersCount`, `ReservationCount`, `LastTransactionDate`, `LastLoginDate`, `CreatedDate`, `AccountStatus`, `SatisfactionRating`) VALUES
(2, 'Ronald', 'Sevillaaaaee', 'sevillaronald32@gmail.com', '$2y$12$YUalmxXNTAnYHqE4YuE9f.OvHg/.rAfqFFE38JQa4idQeP7mvdWvO', '09511299476', 'Online', 0, 0, 0, '2025-11-25 00:06:51', '2025-11-25 00:06:51', '2025-11-06 23:34:05', 'Active', 0.00),
(5, 'Test', 'User', 'test_1762492324@example.com', '$2y$10$oICfw2SwBITYnSkGtyduZubnjRCktRLv0Uraut8a3YxiRO.JpO8kG', '09123456789', 'Online', 0, 0, 0, NULL, NULL, '2025-11-07 13:12:04', 'Active', 0.00),
(6, 'TestJS', 'UserJS', 'testjs@example.com', '$2y$10$7vpPF.mup7IeLZ1Rv6XYHOfR1bov3BR5jKsERDKgyQ7mKrWVluDpy', '09123456789', 'Online', 0, 0, 0, NULL, NULL, '2025-11-07 13:35:28', 'Active', 0.00),
(7, 'Ronald', 'Sevilla', 'sevillaronald@gmail.com', '$2y$12$de0QIvl638SHw4FryePZeOJfkkJK0uhpo6/ynmbn1MjSrKQf6HM9C', '09512994765', 'Online', 3, 0, 3, '2025-11-22 15:53:14', '2025-11-07 14:51:08', '2025-11-07 13:40:13', 'Active', 0.00),
(8, 'Ronal', 'Sevill', 'sevillaronald9@gmail.com', '$2y$12$NvAqawV6IsJSEXIGObqOR.h1p2FJcozHohRB1Xk5RAUFt2id6WRL.', '09511299476', 'Online', 2, 1, 3, '2025-11-23 12:46:04', NULL, '2025-11-22 17:18:23', 'Active', 0.00);

-- --------------------------------------------------------

--
-- Table structure for table `customers_archive`
--

CREATE TABLE `customers_archive` (
  `CustomerID` int(10) NOT NULL COMMENT 'Unique identifier for each customer',
  `FirstName` varchar(50) NOT NULL COMMENT 'Customer first name',
  `LastName` varchar(50) NOT NULL COMMENT 'Customer last name',
  `Email` varchar(100) DEFAULT NULL COMMENT 'Email used for account login (website only)',
  `PasswordHash` varchar(255) DEFAULT NULL COMMENT 'Encrypted password for website login (NULL for POS customers)',
  `ContactNumber` varchar(20) DEFAULT NULL COMMENT 'Customer phone number',
  `CustomerType` enum('Walk-in','Online','Reservation','Corporate/Event') DEFAULT 'Walk-in' COMMENT 'Type of customer',
  `FeedbackCount` int(10) DEFAULT 0 COMMENT 'Number of feedbacks/reviews submitted',
  `TotalOrdersCount` int(10) DEFAULT 0 COMMENT 'Total number of orders made',
  `ReservationCount` int(10) DEFAULT 0 COMMENT 'Total number of reservations made',
  `LastTransactionDate` datetime DEFAULT NULL COMMENT 'Most recent order/reservation date',
  `LastLoginDate` datetime DEFAULT NULL COMMENT 'Last login to the online account',
  `CreatedDate` datetime DEFAULT current_timestamp() COMMENT 'Date and time when record was created',
  `AccountStatus` enum('Active','Suspended','Inactive') DEFAULT 'Active' COMMENT 'Current status of customer account',
  `SatisfactionRating` decimal(3,2) DEFAULT 0.00 COMMENT 'Average customer satisfaction rating (1–5)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `customers_archive`
--

INSERT INTO `customers_archive` (`CustomerID`, `FirstName`, `LastName`, `Email`, `PasswordHash`, `ContactNumber`, `CustomerType`, `FeedbackCount`, `TotalOrdersCount`, `ReservationCount`, `LastTransactionDate`, `LastLoginDate`, `CreatedDate`, `AccountStatus`, `SatisfactionRating`) VALUES
(3, 'Ronald', 'Sevilla', 'sevillaronald2@gmail.com', '$2y$12$EyzFB9nBUBOtuZ/e5RIS3Om6CfJLO8y5/j/MXoz/XNqLAUNZ3szIi', '09511299476', 'Online', 0, 0, 0, NULL, NULL, '2025-11-06 23:41:15', 'Suspended', 0.00),
(4, 'Test', 'User', 'test_1762492321@example.com', '$2y$10$DbTTy8MJU.EDisDHy9szI.hWfg6CfVZby.7MX48xtfz.IynrH5gZe', '09123456789', 'Online', 0, 0, 0, NULL, NULL, '2025-11-07 13:12:01', 'Active', 0.00);

-- --------------------------------------------------------

--
-- Table structure for table `customer_logs`
--

CREATE TABLE `customer_logs` (
  `LogID` int(10) NOT NULL COMMENT 'Unique log identifier',
  `CustomerID` int(10) NOT NULL COMMENT 'Reference to customer',
  `TransactionType` varchar(50) NOT NULL COMMENT 'Type of transaction (LOGIN, LOGOUT, REGISTRATION, ORDER, etc.)',
  `Details` text DEFAULT NULL COMMENT 'Additional details about the transaction',
  `LogDate` datetime DEFAULT current_timestamp() COMMENT 'Date and time of the log'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `customer_logs`
--

INSERT INTO `customer_logs` (`LogID`, `CustomerID`, `TransactionType`, `Details`, `LogDate`) VALUES
(1, 2, 'REGISTRATION', 'Customer account created', '2025-11-06 23:34:05');

-- --------------------------------------------------------

--
-- Table structure for table `customer_reviews`
--

CREATE TABLE `customer_reviews` (
  `ReviewID` int(10) NOT NULL COMMENT 'Unique review identifier',
  `CustomerID` int(10) NOT NULL COMMENT 'Reference to customer who submitted review',
  `OverallRating` decimal(2,1) NOT NULL COMMENT 'Overall rating (1-5)',
  `FoodTasteRating` int(1) DEFAULT NULL COMMENT 'Food taste & quality rating (1-5)',
  `PortionSizeRating` int(1) DEFAULT NULL COMMENT 'Portion size rating (1-5)',
  `CustomerServiceRating` int(1) DEFAULT NULL COMMENT 'Customer service rating (1-5)',
  `AmbienceRating` int(1) DEFAULT NULL COMMENT 'Ambience rating (1-5)',
  `CleanlinessRating` int(1) DEFAULT NULL COMMENT 'Cleanliness rating (1-5)',
  `FoodTasteComment` text DEFAULT NULL COMMENT 'Comment about food taste & quality',
  `PortionSizeComment` text DEFAULT NULL COMMENT 'Comment about portion size',
  `CustomerServiceComment` text DEFAULT NULL COMMENT 'Comment about customer service',
  `AmbienceComment` text DEFAULT NULL COMMENT 'Comment about ambience',
  `CleanlinessComment` text DEFAULT NULL COMMENT 'Comment about cleanliness',
  `GeneralComment` text DEFAULT NULL COMMENT 'General review comment',
  `Status` enum('Pending','Approved','Rejected') DEFAULT 'Pending' COMMENT 'Review approval status',
  `CreatedDate` datetime DEFAULT current_timestamp() COMMENT 'Review submission date',
  `ApprovedDate` datetime DEFAULT NULL COMMENT 'Date when review was approved',
  `UpdatedDate` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last update timestamp'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `customer_reviews`
--

INSERT INTO `customer_reviews` (`ReviewID`, `CustomerID`, `OverallRating`, `FoodTasteRating`, `PortionSizeRating`, `CustomerServiceRating`, `AmbienceRating`, `CleanlinessRating`, `FoodTasteComment`, `PortionSizeComment`, `CustomerServiceComment`, `AmbienceComment`, `CleanlinessComment`, `GeneralComment`, `Status`, `CreatedDate`, `ApprovedDate`, `UpdatedDate`) VALUES
(1, 7, 4.5, 5, 4, 5, 4, 5, 'Delicious food!', 'Good portion size', 'Excellent service', 'Nice atmosphere', 'Very clean', 'Highly recommend!', 'Approved', '2025-11-22 18:03:01', '2025-11-22 18:27:12', '2025-11-22 18:27:12'),
(2, 7, 4.5, 5, 4, 5, 4, 5, 'Delicious food!', 'Good portion size', 'Excellent service', 'Nice atmosphere', 'Very clean', 'Highly recommend!', 'Approved', '2025-11-22 18:10:39', '2025-11-22 18:27:12', '2025-11-22 18:27:12'),
(3, 7, 4.5, 5, 4, 5, 4, 5, 'Delicious food!', 'Good portion size', 'Excellent service', 'Nice atmosphere', 'Very clean', 'Highly recommend!', 'Approved', '2025-11-22 18:10:41', '2025-11-22 18:27:12', '2025-11-22 18:27:12'),
(4, 8, 4.0, 4, 5, 4, 4, 4, 'sdasdasdasda', 'asdafwgsdgsxgd', 'afafwafafdsfadfdafd', 'sfagecvhtehr', 'dawhdutrhsghwt', 'ddadkjsiurhaubfdsgfe', 'Approved', '2025-11-22 18:14:42', '2025-11-25 22:12:21', '2025-11-25 22:12:21');

--
-- Triggers `customer_reviews`
--
DELIMITER $$
CREATE TRIGGER `after_review_approved` AFTER UPDATE ON `customer_reviews` FOR EACH ROW BEGIN
    IF NEW.Status = 'Approved' AND OLD.Status != 'Approved' THEN
        UPDATE `customers` 
        SET `FeedbackCount` = `FeedbackCount` + 1
        WHERE `CustomerID` = NEW.CustomerID;
    ELSEIF OLD.Status = 'Approved' AND NEW.Status != 'Approved' THEN
        UPDATE `customers` 
        SET `FeedbackCount` = GREATEST(`FeedbackCount` - 1, 0)
        WHERE `CustomerID` = NEW.CustomerID;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `customer_statistics`
-- (See below for the actual view)
--
CREATE TABLE `customer_statistics` (
`total_customers` bigint(21)
,`active_customers` bigint(21)
,`suspended_customers` bigint(21)
,`online_customers` bigint(21)
,`average_satisfaction` decimal(7,6)
,`total_orders` decimal(32,0)
,`total_reservations` decimal(32,0)
);

-- --------------------------------------------------------

--
-- Table structure for table `employee`
--

CREATE TABLE `employee` (
  `EmployeeID` int(10) NOT NULL,
  `FirstName` varchar(50) NOT NULL,
  `LastName` varchar(50) NOT NULL,
  `Gender` enum('Male','Female','Other') DEFAULT NULL,
  `DateOfBirth` date DEFAULT NULL,
  `ContactNumber` varchar(20) DEFAULT NULL,
  `Email` varchar(100) DEFAULT NULL,
  `Address` varchar(255) DEFAULT NULL,
  `HireDate` date NOT NULL,
  `Position` varchar(50) NOT NULL,
  `MaritalStatus` enum('Single','Married','Separated','Divorced','Widowed') DEFAULT 'Single',
  `EmploymentStatus` enum('Active','On Leave','Resigned') DEFAULT 'Active',
  `EmploymentType` enum('Full-time','Part-time','Contract') DEFAULT 'Full-time',
  `EmergencyContact` varchar(100) DEFAULT NULL,
  `WorkShift` enum('Morning','Evening','Split') DEFAULT NULL,
  `Salary` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `employee`
--

INSERT INTO `employee` (`EmployeeID`, `FirstName`, `LastName`, `Gender`, `DateOfBirth`, `ContactNumber`, `Email`, `Address`, `HireDate`, `Position`, `MaritalStatus`, `EmploymentStatus`, `EmploymentType`, `EmergencyContact`, `WorkShift`, `Salary`) VALUES
(1, 'Maria', 'Santos', 'Female', '1992-08-20', '09987654321', 'maria.santos@example.com', '456 Mabini St., Cebu City', '2023-03-15', 'Supervisor', 'Married', 'Active', 'Full-time', 'Pedro Santos - 09999888777', 'Morning', 25000.00),
(2, 'Robert', 'Lim', 'Male', '1988-02-14', '09175553344', 'robert.lim@example.com', '789 Rizal Ave., Makati', '2022-07-01', 'Chef', 'Single', 'Active', 'Contract', 'Ana Lim - 09176667788', 'Evening', 32000.00),
(3, 'Angela', 'Reyes', 'Female', '1999-11-05', '09223334455', 'angela.reyes@example.com', 'Lot 12 Phase 2, Caloocan City', '2024-01-10', 'Service Crew', 'Single', 'Active', 'Part-time', 'Ramon Reyes - 09225556677', 'Split', 12000.00);

-- --------------------------------------------------------

--
-- Stand-in structure for view `expiring_ingredients`
-- (See below for the actual view)
--
CREATE TABLE `expiring_ingredients` (
`InventoryID` int(10)
,`IngredientName` varchar(100)
,`StockQuantity` decimal(10,2)
,`UnitType` varchar(50)
,`ExpirationDate` date
,`DaysUntilExpiration` int(7)
,`Alert_Level` varchar(28)
,`Remarks` varchar(255)
);

-- --------------------------------------------------------

--
-- Table structure for table `gcash_receipts`
--

CREATE TABLE `gcash_receipts` (
  `ReceiptID` int(10) NOT NULL COMMENT 'Unique receipt record ID',
  `ReservationPaymentID` int(10) NOT NULL COMMENT 'Reference to payment record',
  `ReceiptFileName` varchar(255) NOT NULL COMMENT 'Original filename of uploaded receipt',
  `ReceiptFilePath` varchar(255) NOT NULL COMMENT 'File path to stored receipt',
  `FileSize` int(11) DEFAULT NULL COMMENT 'File size in bytes',
  `MimeType` varchar(50) DEFAULT NULL COMMENT 'File MIME type (image/jpeg, etc.)',
  `UploadedDate` datetime DEFAULT current_timestamp() COMMENT 'When receipt was uploaded',
  `VerificationStatus` enum('Pending','Verified','Rejected') DEFAULT 'Pending' COMMENT 'Admin verification status',
  `VerificationNotes` text DEFAULT NULL COMMENT 'Admin notes on verification'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ingredients`
--

CREATE TABLE `ingredients` (
  `IngredientID` int(10) NOT NULL COMMENT 'Unique identifier for each ingredient',
  `IngredientName` varchar(100) NOT NULL COMMENT 'Name of ingredient',
  `CategoryID` int(10) DEFAULT NULL,
  `UnitType` varchar(50) DEFAULT NULL COMMENT 'Measurement unit (kg, pack, liter)',
  `StockQuantity` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Current available quantity',
  `LastRestockedDate` datetime DEFAULT NULL COMMENT 'Date/time of last restock',
  `ExpirationDate` date DEFAULT NULL COMMENT 'Expiry date if perishable',
  `Remarks` varchar(255) DEFAULT NULL COMMENT 'Notes about ingredient',
  `MinStockLevel` decimal(10,2) DEFAULT 5.00 COMMENT 'Minimum stock threshold',
  `MaxStockLevel` decimal(10,2) DEFAULT 100.00 COMMENT 'Maximum stock capacity',
  `IsActive` tinyint(1) DEFAULT 1 COMMENT '1=Active, 0=Discontinued',
  `IsPerishable` tinyint(1) DEFAULT 1 COMMENT '1=Perishable, 0=Non-perishable',
  `DefaultShelfLife` int(10) DEFAULT NULL COMMENT 'Default shelf life in days'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `ingredients`
--

INSERT INTO `ingredients` (`IngredientID`, `IngredientName`, `CategoryID`, `UnitType`, `StockQuantity`, `LastRestockedDate`, `ExpirationDate`, `Remarks`, `MinStockLevel`, `MaxStockLevel`, `IsActive`, `IsPerishable`, `DefaultShelfLife`) VALUES
(1, 'Pork Belly', 1, 'kg', 25.00, '2025-11-20 08:00:00', '2025-11-27', 'Fresh delivery twice weekly', 5.00, 100.00, 1, 1, NULL),
(2, 'Pork Liempo', 1, 'kg', 20.00, '2025-11-20 08:00:00', '2025-11-27', 'Main grilling meat', 5.00, 100.00, 1, 1, NULL),
(3, 'Chicken Whole', 1, 'kg', 30.00, '2025-11-20 08:00:00', '2025-11-27', 'For inasal and fried chicken', 5.00, 100.00, 1, 1, NULL),
(4, 'Chicken Wings', 1, 'kg', 15.00, '2025-11-20 08:00:00', '2025-11-27', 'Buffalo wings stock', 5.00, 100.00, 1, 1, NULL),
(5, 'Chicken Breast', 1, 'kg', 18.00, '2025-11-20 08:00:00', '2025-11-27', 'For sisig and salads', 5.00, 100.00, 1, 1, NULL),
(6, 'Pork Sisig Meat', 1, 'kg', 12.00, '2025-11-20 08:00:00', '2025-11-26', 'Pre-chopped pig face and ears', 5.00, 100.00, 1, 1, NULL),
(7, 'Bangus (Milkfish)', 8, 'kg', 10.00, '2025-11-21 06:00:00', '2025-11-24', 'Fresh catch', 5.00, 100.00, 1, 1, NULL),
(8, 'Tilapia', 8, 'kg', 8.00, '2025-11-21 06:00:00', '2025-11-24', 'Farm raised', 5.00, 100.00, 1, 1, NULL),
(9, 'Shrimp', 8, 'kg', 5.00, '2025-11-21 06:00:00', '2025-11-24', 'Medium size', 5.00, 100.00, 1, 1, NULL),
(10, 'Squid', 8, 'kg', 6.00, '2025-11-21 06:00:00', '2025-11-24', 'Cleaned', 5.00, 100.00, 1, 1, NULL),
(11, 'Ground Pork', 1, 'kg', 15.00, '2025-11-20 08:00:00', '2025-11-26', 'For longganisa and lumpia', 5.00, 100.00, 1, 1, NULL),
(12, 'Beef', 1, 'kg', 12.00, '2025-11-20 08:00:00', '2025-11-27', 'For bulalo and kare-kare', 5.00, 100.00, 1, 1, NULL),
(13, 'Pork Knuckle (Pata)', 1, 'kg', 10.00, '2025-11-20 08:00:00', '2025-11-27', 'For crispy pata', 5.00, 100.00, 1, 1, NULL),
(14, 'Pork Ribs', 1, 'kg', 8.00, '2025-11-20 08:00:00', '2025-11-27', 'Baby back ribs', 5.00, 100.00, 1, 1, NULL),
(15, 'Tocino Meat', 1, 'kg', 10.00, '2025-11-19 08:00:00', '2025-11-30', 'Pre-marinated', 5.00, 100.00, 1, 1, NULL),
(16, 'Tapa Meat', 1, 'kg', 10.00, '2025-11-19 08:00:00', '2025-11-30', 'Pre-marinated beef', 5.00, 100.00, 1, 1, NULL),
(17, 'Longganisa', 1, 'kg', 8.00, '2025-11-19 08:00:00', '2025-12-05', 'House recipe', 5.00, 100.00, 1, 1, NULL),
(18, 'Hotdog', 1, 'pack', 20.00, '2025-11-18 08:00:00', '2025-12-18', 'Jumbo size', 5.00, 100.00, 1, 1, NULL),
(19, 'Bacon', 1, 'kg', 5.00, '2025-11-18 08:00:00', '2025-12-10', 'Smoked', 5.00, 100.00, 1, 1, NULL),
(20, 'Corned Beef', 1, 'can', 24.00, '2025-11-15 08:00:00', '2026-11-15', 'Canned goods', 5.00, 100.00, 1, 1, NULL),
(21, 'Spam', 1, 'can', 20.00, '2025-11-15 08:00:00', '2026-11-15', 'Canned meat', 5.00, 100.00, 1, 1, NULL),
(22, 'Eggs', 3, 'tray', 10.00, '2025-11-20 08:00:00', '2025-12-05', '30 pcs per tray', 5.00, 100.00, 1, 1, NULL),
(23, 'Dried Fish (Tuyo)', NULL, 'kg', 3.00, '2025-11-18 08:00:00', '2025-12-18', 'Salted dried herring', 5.00, 100.00, 1, 1, NULL),
(24, 'Danggit', NULL, 'kg', 2.50, '2025-11-18 08:00:00', '2025-12-18', 'Dried rabbitfish', 5.00, 100.00, 1, 1, NULL),
(25, 'Rice', 4, 'kg', 100.00, '2025-11-19 08:00:00', '2026-05-19', 'Sinandomeng variety', 5.00, 100.00, 1, 1, NULL),
(26, 'Garlic Rice Mix', 4, 'kg', 10.00, '2025-11-19 08:00:00', '2026-02-19', 'Pre-mixed seasoning', 5.00, 100.00, 1, 1, NULL),
(27, 'Pancit Canton Noodles', 4, 'kg', 8.00, '2025-11-15 08:00:00', '2026-02-15', 'Dried egg noodles', 5.00, 100.00, 1, 1, NULL),
(28, 'Pancit Bihon Noodles', 4, 'kg', 8.00, '2025-11-15 08:00:00', '2026-02-15', 'Rice vermicelli', 5.00, 100.00, 1, 1, NULL),
(29, 'Sotanghon Noodles', 4, 'kg', 5.00, '2025-11-15 08:00:00', '2026-02-15', 'Glass noodles', 5.00, 100.00, 1, 1, NULL),
(30, 'Spaghetti Noodles', 4, 'kg', 6.00, '2025-11-15 08:00:00', '2026-02-15', 'Italian pasta', 5.00, 100.00, 1, 1, NULL),
(31, 'Onion', 2, 'kg', 15.00, '2025-11-20 08:00:00', '2025-12-05', 'Red onion preferred', 5.00, 100.00, 1, 1, NULL),
(32, 'Garlic', 2, 'kg', 8.00, '2025-11-20 08:00:00', '2025-12-15', 'Native garlic', 5.00, 100.00, 1, 1, NULL),
(33, 'Tomato', 2, 'kg', 10.00, '2025-11-21 06:00:00', '2025-11-28', 'Fresh ripe', 5.00, 100.00, 1, 1, NULL),
(34, 'Ginger', 2, 'kg', 5.00, '2025-11-20 08:00:00', '2025-12-10', 'For soups and marinades', 5.00, 100.00, 1, 1, NULL),
(35, 'Cabbage', 2, 'kg', 8.00, '2025-11-21 06:00:00', '2025-11-28', 'For pancit and lumpia', 5.00, 100.00, 1, 1, NULL),
(36, 'Carrots', 2, 'kg', 6.00, '2025-11-21 06:00:00', '2025-12-01', 'For pancit and menudo', 5.00, 100.00, 1, 1, NULL),
(37, 'Sayote (Chayote)', 2, 'kg', 5.00, '2025-11-21 06:00:00', '2025-11-30', 'For tinola', 5.00, 100.00, 1, 1, NULL),
(38, 'Kangkong', 2, 'bundle', 15.00, '2025-11-21 06:00:00', '2025-11-24', 'Water spinach', 5.00, 100.00, 1, 1, NULL),
(39, 'Pechay', 2, 'bundle', 12.00, '2025-11-21 06:00:00', '2025-11-24', 'Bok choy', 5.00, 100.00, 1, 1, NULL),
(40, 'Green Beans (Sitaw)', 2, 'kg', 4.00, '2025-11-21 06:00:00', '2025-11-26', 'String beans', 5.00, 100.00, 1, 1, NULL),
(41, 'Eggplant', 2, 'kg', 6.00, '2025-11-21 06:00:00', '2025-11-27', 'For tortang talong', 5.00, 100.00, 1, 1, NULL),
(42, 'Ampalaya (Bitter Gourd)', 2, 'pieces', 326.00, '2025-11-27 12:51:39', '2025-11-27', 'For ginisang ampalaya', 1.00, 100.00, 1, 1, NULL),
(43, 'Malunggay Leaves', 2, 'bundle', 10.00, '2025-11-21 06:00:00', '2025-11-24', 'Moringa leaves', 5.00, 100.00, 1, 1, NULL),
(44, 'Green Papaya', 2, 'kg', 5.00, '2025-11-21 06:00:00', '2025-11-28', 'For tinola', 5.00, 100.00, 1, 1, NULL),
(45, 'Banana Blossom', 2, 'pc', 8.00, '2025-11-21 06:00:00', '2025-11-25', 'For kare-kare', 5.00, 100.00, 1, 1, NULL),
(46, 'Talong (Eggplant)', 2, 'kg', 5.00, '2025-11-21 06:00:00', '2025-11-27', 'Long variety', 5.00, 100.00, 1, 1, NULL),
(47, 'Bell Pepper', 2, 'kg', 3.00, '2025-11-21 06:00:00', '2025-11-28', 'Mixed colors', 5.00, 100.00, 1, 1, NULL),
(48, 'Chili Peppers', 2, 'kg', 2.00, '2025-11-20 08:00:00', '2025-12-01', 'Siling labuyo', 5.00, 100.00, 1, 1, NULL),
(49, 'Calamansi', 2, 'kg', 5.00, '2025-11-21 06:00:00', '2025-11-28', 'Philippine lime', 5.00, 100.00, 1, 1, NULL),
(50, 'Lemon', 2, 'kg', 3.00, '2025-11-21 06:00:00', '2025-11-30', 'For drinks', 5.00, 100.00, 1, 1, NULL),
(51, 'Lettuce', 2, 'kg', 4.00, '2025-11-21 06:00:00', '2025-11-25', 'Iceberg variety', 5.00, 100.00, 1, 1, NULL),
(52, 'Cucumber', 2, 'kg', 4.00, '2025-11-21 06:00:00', '2025-11-27', 'For salads', 5.00, 100.00, 1, 1, NULL),
(53, 'Potato', 2, 'kg', 10.00, '2025-11-20 08:00:00', '2025-12-10', 'For fries and menudo', 5.00, 100.00, 1, 1, NULL),
(54, 'Corn', 2, 'kg', 5.00, '2025-11-21 06:00:00', '2025-11-26', 'Sweet corn', 5.00, 100.00, 1, 1, NULL),
(55, 'Soy Sauce', 5, 'liter', 10.00, '2025-11-15 08:00:00', '2026-05-15', 'Silver Swan brand', 5.00, 100.00, 1, 1, NULL),
(56, 'Vinegar', 5, 'liter', 10.00, '2025-11-15 08:00:00', '2026-05-15', 'Cane vinegar', 5.00, 100.00, 1, 1, NULL),
(57, 'Fish Sauce (Patis)', 5, 'liter', 8.00, '2025-11-15 08:00:00', '2026-05-15', 'Rufina brand', 5.00, 100.00, 1, 1, NULL),
(58, 'Oyster Sauce', 5, 'bottle', 12.00, '2025-11-15 08:00:00', '2026-03-15', 'Lee Kum Kee', 5.00, 100.00, 1, 1, NULL),
(59, 'Banana Ketchup', 5, 'bottle', 15.00, '2025-11-15 08:00:00', '2026-03-15', 'Jufran brand', 5.00, 100.00, 1, 1, NULL),
(60, 'Tomato Sauce', 5, 'can', 20.00, '2025-11-15 08:00:00', '2026-05-15', 'Del Monte', 5.00, 100.00, 1, 1, NULL),
(61, 'Mayonnaise', 5, 'jar', 10.00, '2025-11-15 08:00:00', '2026-02-15', 'Best Foods', 5.00, 100.00, 1, 1, NULL),
(62, 'Chili Garlic Sauce', 5, 'bottle', 8.00, '2025-11-15 08:00:00', '2026-03-15', 'For sisig', 5.00, 100.00, 1, 1, NULL),
(63, 'Bagoong (Shrimp Paste)', 5, 'jar', 6.00, '2025-11-15 08:00:00', '2026-06-15', 'Sauteed', 5.00, 100.00, 1, 1, NULL),
(64, 'Peanut Butter', 5, 'jar', 8.00, '2025-11-15 08:00:00', '2026-04-15', 'For kare-kare', 5.00, 100.00, 1, 1, NULL),
(65, 'Liver Spread', 5, 'can', 12.00, '2025-11-15 08:00:00', '2026-04-15', 'For Filipino spaghetti', 5.00, 100.00, 1, 1, NULL),
(66, 'Achuete (Annatto) Oil', 5, 'boxes', 251.00, '2025-11-27 13:16:13', '2026-06-15', 'For inasal color', 5.00, 100.00, 1, 1, NULL),
(67, 'Worcestershire Sauce', 5, 'bottle', 4.00, '2025-11-15 08:00:00', '2026-06-15', 'Lea & Perrins', 5.00, 100.00, 1, 1, NULL),
(68, 'Hot Sauce', 5, 'bottle', 6.00, '2025-11-15 08:00:00', '2026-06-15', 'Tabasco', 5.00, 100.00, 1, 1, NULL),
(69, 'BBQ Sauce', 5, 'bottle', 6.00, '2025-11-15 08:00:00', '2026-03-15', 'For grilled items', 5.00, 100.00, 1, 1, NULL),
(70, 'Gravy Mix', 5, 'pack', 15.00, '2025-11-15 08:00:00', '2026-06-15', 'Brown gravy', 5.00, 100.00, 1, 1, NULL),
(71, 'Evaporated Milk', 3, 'can', 24.00, '2025-11-15 08:00:00', '2026-06-15', 'For desserts', 5.00, 100.00, 1, 1, NULL),
(72, 'Condensed Milk', 3, 'can', 24.00, '2025-11-15 08:00:00', '2026-06-15', 'For halo-halo', 5.00, 100.00, 1, 1, NULL),
(73, 'Coconut Milk', 3, 'liter', 10.00, '2025-11-18 08:00:00', '2025-12-18', 'For laing and ginataang', 5.00, 100.00, 1, 1, NULL),
(74, 'Coconut Cream', 3, 'can', 12.00, '2025-11-15 08:00:00', '2026-03-15', 'Thick coconut milk', 5.00, 100.00, 1, 1, NULL),
(75, 'Butter', 3, 'kg', 3.00, '2025-11-18 08:00:00', '2026-01-18', 'Salted', 5.00, 100.00, 1, 1, NULL),
(76, 'Cheese', 3, 'kg', 4.00, '2025-11-18 08:00:00', '2025-12-18', 'Quick melt', 5.00, 100.00, 1, 1, NULL),
(77, 'Fresh Milk', 3, 'liter', 8.00, '2025-11-21 06:00:00', '2025-11-28', 'For shakes', 5.00, 100.00, 1, 1, NULL),
(78, 'Coffee', 7, 'kg', 3.00, '2025-11-15 08:00:00', '2026-05-15', 'Ground coffee', 5.00, 100.00, 1, 1, NULL),
(79, 'Tea Bags', 7, 'box', 10.00, '2025-11-15 08:00:00', '2026-08-15', 'Assorted flavors', 5.00, 100.00, 1, 1, NULL),
(80, 'Iced Tea Powder', 7, 'kg', 5.00, '2025-11-15 08:00:00', '2026-06-15', 'Lemon flavor', 5.00, 100.00, 1, 1, NULL),
(81, 'Mango Shake Mix', 7, 'kg', 3.00, '2025-11-15 08:00:00', '2026-06-15', 'Powdered', 5.00, 100.00, 1, 1, NULL),
(82, 'Chocolate Powder', 7, 'kg', 3.00, '2025-11-15 08:00:00', '2026-06-15', 'For drinks', 5.00, 100.00, 1, 1, NULL),
(83, 'Soft Drinks', 7, 'case', 10.00, '2025-11-18 08:00:00', '2026-03-18', 'Assorted 1.5L', 5.00, 100.00, 1, 1, NULL),
(84, 'Mineral Water', 7, 'case', 15.00, '2025-11-18 08:00:00', '2026-06-18', '500ml bottles', 5.00, 100.00, 1, 1, NULL),
(85, 'Buko Juice', 7, 'liter', 8.00, '2025-11-21 06:00:00', '2025-11-25', 'Fresh coconut water', 5.00, 100.00, 1, 1, NULL),
(86, 'Cooking Oil', 5, 'liter', 20.00, '2025-11-15 08:00:00', '2026-06-15', 'Vegetable oil', 5.00, 100.00, 1, 1, NULL),
(87, 'Salt', 6, 'kg', 10.00, '2025-11-15 08:00:00', '2027-11-15', 'Iodized', 5.00, 100.00, 1, 1, NULL),
(88, 'Sugar', 6, 'kg', 15.00, '2025-11-15 08:00:00', '2026-11-15', 'White refined', 5.00, 100.00, 1, 1, NULL),
(89, 'Brown Sugar', 6, 'kg', 8.00, '2025-11-15 08:00:00', '2026-11-15', 'Muscovado', 5.00, 100.00, 1, 1, NULL),
(90, 'Pepper', 6, 'kg', 2.00, '2025-11-15 08:00:00', '2026-11-15', 'Ground black pepper', 5.00, 100.00, 1, 1, NULL),
(91, 'MSG', 6, 'kg', 3.00, '2025-11-15 08:00:00', '2026-11-15', 'Ajinomoto', 5.00, 100.00, 1, 1, NULL),
(92, 'Flour', 4, 'kg', 10.00, '2025-11-15 08:00:00', '2026-05-15', 'All-purpose', 5.00, 100.00, 1, 1, NULL),
(93, 'Cornstarch', 4, 'kg', 5.00, '2025-11-15 08:00:00', '2026-11-15', 'For breading', 5.00, 100.00, 1, 1, NULL),
(94, 'Bread Crumbs', 4, 'kg', 4.00, '2025-11-15 08:00:00', '2026-03-15', 'Japanese panko', 5.00, 100.00, 1, 1, NULL),
(95, 'Lumpia Wrapper', 10, 'pack', 20.00, '2025-11-18 08:00:00', '2025-12-18', '25 sheets per pack', 5.00, 100.00, 1, 1, NULL),
(96, 'Spring Roll Wrapper', 10, 'pack', 15.00, '2025-11-18 08:00:00', '2025-12-18', 'Small size', 5.00, 100.00, 1, 1, NULL),
(97, 'Leche Flan Mix', 10, 'pack', 10.00, '2025-11-15 08:00:00', '2026-06-15', 'Instant mix', 5.00, 100.00, 1, 1, NULL),
(98, 'Gulaman (Agar)', 10, 'pack', 15.00, '2025-11-15 08:00:00', '2026-09-15', 'For halo-halo', 5.00, 100.00, 1, 1, NULL),
(99, 'Sago Pearls', 10, 'kg', 5.00, '2025-11-15 08:00:00', '2026-09-15', 'Tapioca pearls', 5.00, 100.00, 1, 1, NULL),
(100, 'Kaong (Palm Fruit)', 10, 'jar', 10.00, '2025-11-15 08:00:00', '2026-06-15', 'For halo-halo', 5.00, 100.00, 1, 1, NULL),
(101, 'Nata de Coco', 10, 'jar', 10.00, '2025-11-15 08:00:00', '2026-06-15', 'Coconut gel', 5.00, 100.00, 1, 1, NULL),
(102, 'Ube Halaya', 10, 'kg', 4.00, '2025-11-18 08:00:00', '2025-12-18', 'Purple yam jam', 5.00, 100.00, 1, 1, NULL),
(103, 'Langka (Jackfruit)', 10, 'kg', 3.00, '2025-11-18 08:00:00', '2025-12-01', 'Sweetened', 5.00, 100.00, 1, 1, NULL),
(104, 'Macapuno', 10, 'jar', 6.00, '2025-11-15 08:00:00', '2026-06-15', 'Coconut sport', 5.00, 100.00, 1, 1, NULL),
(105, 'Ice Cream', 10, 'liter', 10.00, '2025-11-18 08:00:00', '2026-02-18', 'Assorted flavors', 5.00, 100.00, 1, 1, NULL),
(106, 'Shaved Ice', 10, 'kg', 50.00, '2025-11-21 06:00:00', '2025-11-22', 'Made fresh daily', 5.00, 100.00, 1, 1, NULL),
(107, 'Banana', 10, 'kg', 10.00, '2025-11-21 06:00:00', '2025-11-26', 'Saba variety', 5.00, 100.00, 1, 1, NULL),
(108, 'Turon Wrapper', 10, 'pack', 10.00, '2025-11-18 08:00:00', '2025-12-18', 'Lumpia wrapper for turon', 5.00, 100.00, 1, 1, NULL),
(109, 'Chicken Broth', 10, 'liter', 8.00, '2025-11-18 08:00:00', '2025-12-18', 'Homemade stock', 5.00, 100.00, 1, 1, NULL),
(110, 'Pork Broth', 10, 'liter', 6.00, '2025-11-18 08:00:00', '2025-12-18', 'For sinigang', 5.00, 100.00, 1, 1, NULL),
(111, 'Beef Broth', 10, 'liter', 5.00, '2025-11-18 08:00:00', '2025-12-18', 'For bulalo', 5.00, 100.00, 1, 1, NULL),
(112, 'Tamarind Mix (Sinigang)', 10, 'pack', 20.00, '2025-11-15 08:00:00', '2026-06-15', 'Instant sinigang mix', 5.00, 100.00, 1, 1, NULL),
(113, 'Miso Paste', 10, 'kg', 2.00, '2025-11-15 08:00:00', '2026-03-15', 'For miso soup', 5.00, 100.00, 1, 1, NULL),
(114, 'Lemongrass', 6, 'bundle', 8.00, '2025-11-21 06:00:00', '2025-11-28', 'For inasal marinade', 5.00, 100.00, 1, 1, NULL),
(115, 'Bay Leaves', 6, 'pack', 5.00, '2025-11-15 08:00:00', '2026-11-15', 'Dried', 5.00, 100.00, 1, 1, NULL),
(116, 'Paprika', 6, 'kg', 1.00, '2025-11-15 08:00:00', '2026-11-15', 'Smoked', 5.00, 100.00, 1, 1, NULL),
(117, 'Cumin', 6, 'kg', 0.50, '2025-11-15 08:00:00', '2026-11-15', 'Ground', 5.00, 100.00, 1, 1, NULL),
(118, 'Oregano', 6, 'pack', 3.00, '2025-11-15 08:00:00', '2026-11-15', 'Dried', 5.00, 100.00, 1, 1, NULL),
(119, 'Annatto Seeds', 6, 'kg', 1.00, '2025-11-15 08:00:00', '2026-11-15', 'For atsuete oil', 5.00, 100.00, 1, 1, NULL),
(120, 'Pandan Leaves', 6, 'bundle', 5.00, '2025-11-21 06:00:00', '2025-11-26', 'For rice and desserts', 5.00, 100.00, 1, 1, NULL),
(123, 'ampalaay adad', 1, 'pieces', 0.00, '2025-11-25 16:36:37', NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(133, 'a william', 10, 'kg', 45.00, '2025-11-26 18:07:54', NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(134, 'aaahatdog4564', 1, 'kg', 668.00, '2025-11-27 12:17:03', NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(135, 'aaaa343454', 1, 'kg', 0.00, '2025-11-27 11:59:01', NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(136, 'aaa21121', 1, 'boxes', 0.00, NULL, NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(137, 'a23232', 1, 'liters', 165.00, '2025-11-27 12:19:05', NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(138, 'aaaqa43', 1, 'liters', 0.00, NULL, NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(139, 'aaa4343', 1, 'pieces', 0.00, NULL, NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(141, 'aaaaa344', 1, 'kg', 0.00, '2025-11-27 12:50:49', NULL, NULL, 5.00, 100.00, 0, 1, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `ingredients_backup`
--

CREATE TABLE `ingredients_backup` (
  `IngredientID` int(10) NOT NULL DEFAULT 0 COMMENT 'Unique identifier for each ingredient',
  `IngredientName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Name of ingredient',
  `CategoryID` int(10) DEFAULT NULL,
  `UnitType` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Measurement unit (kg, pack, liter)',
  `StockQuantity` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Current available quantity',
  `LastRestockedDate` datetime DEFAULT NULL COMMENT 'Date/time of last restock',
  `ExpirationDate` date DEFAULT NULL COMMENT 'Expiry date if perishable',
  `Remarks` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Notes about ingredient',
  `MinStockLevel` decimal(10,2) DEFAULT 5.00 COMMENT 'Minimum stock threshold',
  `MaxStockLevel` decimal(10,2) DEFAULT 100.00 COMMENT 'Maximum stock capacity',
  `IsActive` tinyint(1) DEFAULT 1 COMMENT '1=Active, 0=Discontinued'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `ingredients_backup`
--

INSERT INTO `ingredients_backup` (`IngredientID`, `IngredientName`, `CategoryID`, `UnitType`, `StockQuantity`, `LastRestockedDate`, `ExpirationDate`, `Remarks`, `MinStockLevel`, `MaxStockLevel`, `IsActive`) VALUES
(1, 'Pork Belly', 1, 'kg', 25.00, '2025-11-20 08:00:00', '2025-11-27', 'Fresh delivery twice weekly', 5.00, 100.00, 1),
(2, 'Pork Liempo', 1, 'kg', 20.00, '2025-11-20 08:00:00', '2025-11-27', 'Main grilling meat', 5.00, 100.00, 1),
(3, 'Chicken Whole', 1, 'kg', 30.00, '2025-11-20 08:00:00', '2025-11-27', 'For inasal and fried chicken', 5.00, 100.00, 1),
(4, 'Chicken Wings', 1, 'kg', 15.00, '2025-11-20 08:00:00', '2025-11-27', 'Buffalo wings stock', 5.00, 100.00, 1),
(5, 'Chicken Breast', 1, 'kg', 18.00, '2025-11-20 08:00:00', '2025-11-27', 'For sisig and salads', 5.00, 100.00, 1),
(6, 'Pork Sisig Meat', 1, 'kg', 12.00, '2025-11-20 08:00:00', '2025-11-26', 'Pre-chopped pig face and ears', 5.00, 100.00, 1),
(7, 'Bangus (Milkfish)', 8, 'kg', 10.00, '2025-11-21 06:00:00', '2025-11-24', 'Fresh catch', 5.00, 100.00, 1),
(8, 'Tilapia', 8, 'kg', 8.00, '2025-11-21 06:00:00', '2025-11-24', 'Farm raised', 5.00, 100.00, 1),
(9, 'Shrimp', 8, 'kg', 5.00, '2025-11-21 06:00:00', '2025-11-24', 'Medium size', 5.00, 100.00, 1),
(10, 'Squid', 8, 'kg', 6.00, '2025-11-21 06:00:00', '2025-11-24', 'Cleaned', 5.00, 100.00, 1),
(11, 'Ground Pork', 1, 'kg', 15.00, '2025-11-20 08:00:00', '2025-11-26', 'For longganisa and lumpia', 5.00, 100.00, 1),
(12, 'Beef', 1, 'kg', 12.00, '2025-11-20 08:00:00', '2025-11-27', 'For bulalo and kare-kare', 5.00, 100.00, 1),
(13, 'Pork Knuckle (Pata)', 1, 'kg', 10.00, '2025-11-20 08:00:00', '2025-11-27', 'For crispy pata', 5.00, 100.00, 1),
(14, 'Pork Ribs', 1, 'kg', 8.00, '2025-11-20 08:00:00', '2025-11-27', 'Baby back ribs', 5.00, 100.00, 1),
(15, 'Tocino Meat', 1, 'kg', 10.00, '2025-11-19 08:00:00', '2025-11-30', 'Pre-marinated', 5.00, 100.00, 1),
(16, 'Tapa Meat', 1, 'kg', 10.00, '2025-11-19 08:00:00', '2025-11-30', 'Pre-marinated beef', 5.00, 100.00, 1),
(17, 'Longganisa', 1, 'kg', 8.00, '2025-11-19 08:00:00', '2025-12-05', 'House recipe', 5.00, 100.00, 1),
(18, 'Hotdog', 1, 'pack', 20.00, '2025-11-18 08:00:00', '2025-12-18', 'Jumbo size', 5.00, 100.00, 1),
(19, 'Bacon', 1, 'kg', 5.00, '2025-11-18 08:00:00', '2025-12-10', 'Smoked', 5.00, 100.00, 1),
(20, 'Corned Beef', 1, 'can', 24.00, '2025-11-15 08:00:00', '2026-11-15', 'Canned goods', 5.00, 100.00, 1),
(21, 'Spam', 1, 'can', 20.00, '2025-11-15 08:00:00', '2026-11-15', 'Canned meat', 5.00, 100.00, 1),
(22, 'Eggs', 3, 'tray', 10.00, '2025-11-20 08:00:00', '2025-12-05', '30 pcs per tray', 5.00, 100.00, 1),
(23, 'Dried Fish (Tuyo)', NULL, 'kg', 3.00, '2025-11-18 08:00:00', '2025-12-18', 'Salted dried herring', 5.00, 100.00, 1),
(24, 'Danggit', NULL, 'kg', 2.50, '2025-11-18 08:00:00', '2025-12-18', 'Dried rabbitfish', 5.00, 100.00, 1),
(25, 'Rice', 4, 'kg', 100.00, '2025-11-19 08:00:00', '2026-05-19', 'Sinandomeng variety', 5.00, 100.00, 1),
(26, 'Garlic Rice Mix', 4, 'kg', 10.00, '2025-11-19 08:00:00', '2026-02-19', 'Pre-mixed seasoning', 5.00, 100.00, 1),
(27, 'Pancit Canton Noodles', 4, 'kg', 8.00, '2025-11-15 08:00:00', '2026-02-15', 'Dried egg noodles', 5.00, 100.00, 1),
(28, 'Pancit Bihon Noodles', 4, 'kg', 8.00, '2025-11-15 08:00:00', '2026-02-15', 'Rice vermicelli', 5.00, 100.00, 1),
(29, 'Sotanghon Noodles', 4, 'kg', 5.00, '2025-11-15 08:00:00', '2026-02-15', 'Glass noodles', 5.00, 100.00, 1),
(30, 'Spaghetti Noodles', 4, 'kg', 6.00, '2025-11-15 08:00:00', '2026-02-15', 'Italian pasta', 5.00, 100.00, 1),
(31, 'Onion', 2, 'kg', 15.00, '2025-11-20 08:00:00', '2025-12-05', 'Red onion preferred', 5.00, 100.00, 1),
(32, 'Garlic', 2, 'kg', 8.00, '2025-11-20 08:00:00', '2025-12-15', 'Native garlic', 5.00, 100.00, 1),
(33, 'Tomato', 2, 'kg', 10.00, '2025-11-21 06:00:00', '2025-11-28', 'Fresh ripe', 5.00, 100.00, 1),
(34, 'Ginger', 2, 'kg', 5.00, '2025-11-20 08:00:00', '2025-12-10', 'For soups and marinades', 5.00, 100.00, 1),
(35, 'Cabbage', 2, 'kg', 8.00, '2025-11-21 06:00:00', '2025-11-28', 'For pancit and lumpia', 5.00, 100.00, 1),
(36, 'Carrots', 2, 'kg', 6.00, '2025-11-21 06:00:00', '2025-12-01', 'For pancit and menudo', 5.00, 100.00, 1),
(37, 'Sayote (Chayote)', 2, 'kg', 5.00, '2025-11-21 06:00:00', '2025-11-30', 'For tinola', 5.00, 100.00, 1),
(38, 'Kangkong', 2, 'bundle', 15.00, '2025-11-21 06:00:00', '2025-11-24', 'Water spinach', 5.00, 100.00, 1),
(39, 'Pechay', 2, 'bundle', 12.00, '2025-11-21 06:00:00', '2025-11-24', 'Bok choy', 5.00, 100.00, 1),
(40, 'Green Beans (Sitaw)', 2, 'kg', 4.00, '2025-11-21 06:00:00', '2025-11-26', 'String beans', 5.00, 100.00, 1),
(41, 'Eggplant', 2, 'kg', 6.00, '2025-11-21 06:00:00', '2025-11-27', 'For tortang talong', 5.00, 100.00, 1),
(42, 'Ampalaya (Bitter Gourd)', 2, 'kg', 4.00, '2025-11-21 06:00:00', '2025-11-27', 'For ginisang ampalaya', 5.00, 100.00, 1),
(43, 'Malunggay Leaves', 2, 'bundle', 10.00, '2025-11-21 06:00:00', '2025-11-24', 'Moringa leaves', 5.00, 100.00, 1),
(44, 'Green Papaya', 2, 'kg', 5.00, '2025-11-21 06:00:00', '2025-11-28', 'For tinola', 5.00, 100.00, 1),
(45, 'Banana Blossom', 2, 'pc', 8.00, '2025-11-21 06:00:00', '2025-11-25', 'For kare-kare', 5.00, 100.00, 1),
(46, 'Talong (Eggplant)', 2, 'kg', 5.00, '2025-11-21 06:00:00', '2025-11-27', 'Long variety', 5.00, 100.00, 1),
(47, 'Bell Pepper', 2, 'kg', 3.00, '2025-11-21 06:00:00', '2025-11-28', 'Mixed colors', 5.00, 100.00, 1),
(48, 'Chili Peppers', 2, 'kg', 2.00, '2025-11-20 08:00:00', '2025-12-01', 'Siling labuyo', 5.00, 100.00, 1),
(49, 'Calamansi', 2, 'kg', 5.00, '2025-11-21 06:00:00', '2025-11-28', 'Philippine lime', 5.00, 100.00, 1),
(50, 'Lemon', 2, 'kg', 3.00, '2025-11-21 06:00:00', '2025-11-30', 'For drinks', 5.00, 100.00, 1),
(51, 'Lettuce', 2, 'kg', 4.00, '2025-11-21 06:00:00', '2025-11-25', 'Iceberg variety', 5.00, 100.00, 1),
(52, 'Cucumber', 2, 'kg', 4.00, '2025-11-21 06:00:00', '2025-11-27', 'For salads', 5.00, 100.00, 1),
(53, 'Potato', 2, 'kg', 10.00, '2025-11-20 08:00:00', '2025-12-10', 'For fries and menudo', 5.00, 100.00, 1),
(54, 'Corn', 2, 'kg', 5.00, '2025-11-21 06:00:00', '2025-11-26', 'Sweet corn', 5.00, 100.00, 1),
(55, 'Soy Sauce', 5, 'liter', 10.00, '2025-11-15 08:00:00', '2026-05-15', 'Silver Swan brand', 5.00, 100.00, 1),
(56, 'Vinegar', 5, 'liter', 10.00, '2025-11-15 08:00:00', '2026-05-15', 'Cane vinegar', 5.00, 100.00, 1),
(57, 'Fish Sauce (Patis)', 5, 'liter', 8.00, '2025-11-15 08:00:00', '2026-05-15', 'Rufina brand', 5.00, 100.00, 1),
(58, 'Oyster Sauce', 5, 'bottle', 12.00, '2025-11-15 08:00:00', '2026-03-15', 'Lee Kum Kee', 5.00, 100.00, 1),
(59, 'Banana Ketchup', 5, 'bottle', 15.00, '2025-11-15 08:00:00', '2026-03-15', 'Jufran brand', 5.00, 100.00, 1),
(60, 'Tomato Sauce', 5, 'can', 20.00, '2025-11-15 08:00:00', '2026-05-15', 'Del Monte', 5.00, 100.00, 1),
(61, 'Mayonnaise', 5, 'jar', 10.00, '2025-11-15 08:00:00', '2026-02-15', 'Best Foods', 5.00, 100.00, 1),
(62, 'Chili Garlic Sauce', 5, 'bottle', 8.00, '2025-11-15 08:00:00', '2026-03-15', 'For sisig', 5.00, 100.00, 1),
(63, 'Bagoong (Shrimp Paste)', 5, 'jar', 6.00, '2025-11-15 08:00:00', '2026-06-15', 'Sauteed', 5.00, 100.00, 1),
(64, 'Peanut Butter', 5, 'jar', 8.00, '2025-11-15 08:00:00', '2026-04-15', 'For kare-kare', 5.00, 100.00, 1),
(65, 'Liver Spread', 5, 'can', 12.00, '2025-11-15 08:00:00', '2026-04-15', 'For Filipino spaghetti', 5.00, 100.00, 1),
(66, 'Achuete (Annatto) Oil', 5, 'bottle', 5.00, '2025-11-15 08:00:00', '2026-06-15', 'For inasal color', 5.00, 100.00, 1),
(67, 'Worcestershire Sauce', 5, 'bottle', 4.00, '2025-11-15 08:00:00', '2026-06-15', 'Lea & Perrins', 5.00, 100.00, 1),
(68, 'Hot Sauce', 5, 'bottle', 6.00, '2025-11-15 08:00:00', '2026-06-15', 'Tabasco', 5.00, 100.00, 1),
(69, 'BBQ Sauce', 5, 'bottle', 6.00, '2025-11-15 08:00:00', '2026-03-15', 'For grilled items', 5.00, 100.00, 1),
(70, 'Gravy Mix', 5, 'pack', 15.00, '2025-11-15 08:00:00', '2026-06-15', 'Brown gravy', 5.00, 100.00, 1),
(71, 'Evaporated Milk', 3, 'can', 24.00, '2025-11-15 08:00:00', '2026-06-15', 'For desserts', 5.00, 100.00, 1),
(72, 'Condensed Milk', 3, 'can', 24.00, '2025-11-15 08:00:00', '2026-06-15', 'For halo-halo', 5.00, 100.00, 1),
(73, 'Coconut Milk', 3, 'liter', 10.00, '2025-11-18 08:00:00', '2025-12-18', 'For laing and ginataang', 5.00, 100.00, 1),
(74, 'Coconut Cream', 3, 'can', 12.00, '2025-11-15 08:00:00', '2026-03-15', 'Thick coconut milk', 5.00, 100.00, 1),
(75, 'Butter', 3, 'kg', 3.00, '2025-11-18 08:00:00', '2026-01-18', 'Salted', 5.00, 100.00, 1),
(76, 'Cheese', 3, 'kg', 4.00, '2025-11-18 08:00:00', '2025-12-18', 'Quick melt', 5.00, 100.00, 1),
(77, 'Fresh Milk', 3, 'liter', 8.00, '2025-11-21 06:00:00', '2025-11-28', 'For shakes', 5.00, 100.00, 1),
(78, 'Coffee', 7, 'kg', 3.00, '2025-11-15 08:00:00', '2026-05-15', 'Ground coffee', 5.00, 100.00, 1),
(79, 'Tea Bags', 7, 'box', 10.00, '2025-11-15 08:00:00', '2026-08-15', 'Assorted flavors', 5.00, 100.00, 1),
(80, 'Iced Tea Powder', 7, 'kg', 5.00, '2025-11-15 08:00:00', '2026-06-15', 'Lemon flavor', 5.00, 100.00, 1),
(81, 'Mango Shake Mix', 7, 'kg', 3.00, '2025-11-15 08:00:00', '2026-06-15', 'Powdered', 5.00, 100.00, 1),
(82, 'Chocolate Powder', 7, 'kg', 3.00, '2025-11-15 08:00:00', '2026-06-15', 'For drinks', 5.00, 100.00, 1),
(83, 'Soft Drinks', 7, 'case', 10.00, '2025-11-18 08:00:00', '2026-03-18', 'Assorted 1.5L', 5.00, 100.00, 1),
(84, 'Mineral Water', 7, 'case', 15.00, '2025-11-18 08:00:00', '2026-06-18', '500ml bottles', 5.00, 100.00, 1),
(85, 'Buko Juice', 7, 'liter', 8.00, '2025-11-21 06:00:00', '2025-11-25', 'Fresh coconut water', 5.00, 100.00, 1),
(86, 'Cooking Oil', 5, 'liter', 20.00, '2025-11-15 08:00:00', '2026-06-15', 'Vegetable oil', 5.00, 100.00, 1),
(87, 'Salt', 6, 'kg', 10.00, '2025-11-15 08:00:00', '2027-11-15', 'Iodized', 5.00, 100.00, 1),
(88, 'Sugar', 6, 'kg', 15.00, '2025-11-15 08:00:00', '2026-11-15', 'White refined', 5.00, 100.00, 1),
(89, 'Brown Sugar', 6, 'kg', 8.00, '2025-11-15 08:00:00', '2026-11-15', 'Muscovado', 5.00, 100.00, 1),
(90, 'Pepper', 6, 'kg', 2.00, '2025-11-15 08:00:00', '2026-11-15', 'Ground black pepper', 5.00, 100.00, 1),
(91, 'MSG', 6, 'kg', 3.00, '2025-11-15 08:00:00', '2026-11-15', 'Ajinomoto', 5.00, 100.00, 1),
(92, 'Flour', 4, 'kg', 10.00, '2025-11-15 08:00:00', '2026-05-15', 'All-purpose', 5.00, 100.00, 1),
(93, 'Cornstarch', 4, 'kg', 5.00, '2025-11-15 08:00:00', '2026-11-15', 'For breading', 5.00, 100.00, 1),
(94, 'Bread Crumbs', 4, 'kg', 4.00, '2025-11-15 08:00:00', '2026-03-15', 'Japanese panko', 5.00, 100.00, 1),
(95, 'Lumpia Wrapper', 10, 'pack', 20.00, '2025-11-18 08:00:00', '2025-12-18', '25 sheets per pack', 5.00, 100.00, 1),
(96, 'Spring Roll Wrapper', 10, 'pack', 15.00, '2025-11-18 08:00:00', '2025-12-18', 'Small size', 5.00, 100.00, 1),
(97, 'Leche Flan Mix', 10, 'pack', 10.00, '2025-11-15 08:00:00', '2026-06-15', 'Instant mix', 5.00, 100.00, 1),
(98, 'Gulaman (Agar)', 10, 'pack', 15.00, '2025-11-15 08:00:00', '2026-09-15', 'For halo-halo', 5.00, 100.00, 1),
(99, 'Sago Pearls', 10, 'kg', 5.00, '2025-11-15 08:00:00', '2026-09-15', 'Tapioca pearls', 5.00, 100.00, 1),
(100, 'Kaong (Palm Fruit)', 10, 'jar', 10.00, '2025-11-15 08:00:00', '2026-06-15', 'For halo-halo', 5.00, 100.00, 1),
(101, 'Nata de Coco', 10, 'jar', 10.00, '2025-11-15 08:00:00', '2026-06-15', 'Coconut gel', 5.00, 100.00, 1),
(102, 'Ube Halaya', 10, 'kg', 4.00, '2025-11-18 08:00:00', '2025-12-18', 'Purple yam jam', 5.00, 100.00, 1),
(103, 'Langka (Jackfruit)', 10, 'kg', 3.00, '2025-11-18 08:00:00', '2025-12-01', 'Sweetened', 5.00, 100.00, 1),
(104, 'Macapuno', 10, 'jar', 6.00, '2025-11-15 08:00:00', '2026-06-15', 'Coconut sport', 5.00, 100.00, 1),
(105, 'Ice Cream', 10, 'liter', 10.00, '2025-11-18 08:00:00', '2026-02-18', 'Assorted flavors', 5.00, 100.00, 1),
(106, 'Shaved Ice', 10, 'kg', 50.00, '2025-11-21 06:00:00', '2025-11-22', 'Made fresh daily', 5.00, 100.00, 1),
(107, 'Banana', 10, 'kg', 10.00, '2025-11-21 06:00:00', '2025-11-26', 'Saba variety', 5.00, 100.00, 1),
(108, 'Turon Wrapper', 10, 'pack', 10.00, '2025-11-18 08:00:00', '2025-12-18', 'Lumpia wrapper for turon', 5.00, 100.00, 1),
(109, 'Chicken Broth', 10, 'liter', 8.00, '2025-11-18 08:00:00', '2025-12-18', 'Homemade stock', 5.00, 100.00, 1),
(110, 'Pork Broth', 10, 'liter', 6.00, '2025-11-18 08:00:00', '2025-12-18', 'For sinigang', 5.00, 100.00, 1),
(111, 'Beef Broth', 10, 'liter', 5.00, '2025-11-18 08:00:00', '2025-12-18', 'For bulalo', 5.00, 100.00, 1),
(112, 'Tamarind Mix (Sinigang)', 10, 'pack', 20.00, '2025-11-15 08:00:00', '2026-06-15', 'Instant sinigang mix', 5.00, 100.00, 1),
(113, 'Miso Paste', 10, 'kg', 2.00, '2025-11-15 08:00:00', '2026-03-15', 'For miso soup', 5.00, 100.00, 1),
(114, 'Lemongrass', 6, 'bundle', 8.00, '2025-11-21 06:00:00', '2025-11-28', 'For inasal marinade', 5.00, 100.00, 1),
(115, 'Bay Leaves', 6, 'pack', 5.00, '2025-11-15 08:00:00', '2026-11-15', 'Dried', 5.00, 100.00, 1),
(116, 'Paprika', 6, 'kg', 1.00, '2025-11-15 08:00:00', '2026-11-15', 'Smoked', 5.00, 100.00, 1),
(117, 'Cumin', 6, 'kg', 0.50, '2025-11-15 08:00:00', '2026-11-15', 'Ground', 5.00, 100.00, 1),
(118, 'Oregano', 6, 'pack', 3.00, '2025-11-15 08:00:00', '2026-11-15', 'Dried', 5.00, 100.00, 1),
(119, 'Annatto Seeds', 6, 'kg', 1.00, '2025-11-15 08:00:00', '2026-11-15', 'For atsuete oil', 5.00, 100.00, 1),
(120, 'Pandan Leaves', 6, 'bundle', 5.00, '2025-11-21 06:00:00', '2025-11-26', 'For rice and desserts', 5.00, 100.00, 1);

-- --------------------------------------------------------

--
-- Table structure for table `ingredient_categories`
--

CREATE TABLE `ingredient_categories` (
  `CategoryID` int(10) NOT NULL,
  `CategoryName` varchar(100) NOT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `CreatedDate` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `ingredient_categories`
--

INSERT INTO `ingredient_categories` (`CategoryID`, `CategoryName`, `Description`, `CreatedDate`) VALUES
(1, 'Meat & Poultry', 'Fresh and frozen meat, chicken, pork, beef products', '2025-11-23 15:32:31'),
(2, 'Vegetables & Produce', 'Fresh vegetables, herbs, and produce', '2025-11-23 15:32:31'),
(3, 'Dairy & Eggs', 'Milk products, eggs, butter, cheese', '2025-11-23 15:32:31'),
(4, 'Dry Goods & Grains', 'Rice, noodles, flour, and dry ingredients', '2025-11-23 15:32:31'),
(5, 'Condiments & Sauces', 'Sauces, seasonings, oils, and condiments', '2025-11-23 15:32:31'),
(6, 'Spices & Seasonings', 'Herbs, spices, and flavor enhancers', '2025-11-23 15:32:31'),
(7, 'Beverages', 'Drinks, juices, coffee, tea', '2025-11-23 15:32:31'),
(8, 'Seafood', 'Fish, shellfish, and seafood products', '2025-11-23 15:32:31'),
(9, 'Frozen Items', 'Frozen foods and ingredients', '2025-11-23 15:32:31'),
(10, 'Dessert & Special Ingredients', 'Dessert ingredients, wrappers, specialty items', '2025-11-23 15:32:31');

-- --------------------------------------------------------

--
-- Table structure for table `inventory`
--

CREATE TABLE `inventory` (
  `InventoryID` int(10) NOT NULL COMMENT 'Unique inventory record ID',
  `IngredientID` int(10) NOT NULL COMMENT 'Linked to Ingredients(IngredientID)',
  `StockQuantity` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Current stock level',
  `UnitType` varchar(50) DEFAULT NULL COMMENT 'Measurement unit (kg, pack, liter, can, bottle, tray, bundle, jar, pc)',
  `LastRestockedDate` datetime DEFAULT NULL COMMENT 'Last restock date/time when purchased',
  `ExpirationDate` date DEFAULT NULL COMMENT 'Expiry date if perishable',
  `Remarks` varchar(255) DEFAULT NULL COMMENT 'Notes about ingredient condition or source',
  `CreatedDate` datetime DEFAULT current_timestamp() COMMENT 'Record creation date',
  `UpdatedDate` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last update timestamp'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `inventory`
--

INSERT INTO `inventory` (`InventoryID`, `IngredientID`, `StockQuantity`, `UnitType`, `LastRestockedDate`, `ExpirationDate`, `Remarks`, `CreatedDate`, `UpdatedDate`) VALUES
(1, 1, 25.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'Fresh delivery twice weekly', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(2, 2, 20.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'Main grilling meat', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(3, 3, 30.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'For inasal and fried chicken', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(4, 4, 15.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'Buffalo wings stock', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(5, 5, 18.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'For sisig and salads', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(6, 6, 12.00, 'kg', '2025-11-20 08:00:00', '2025-11-26', 'Pre-chopped pig face and ears', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(7, 7, 10.00, 'kg', '2025-11-21 06:00:00', '2025-11-24', 'Fresh catch', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(8, 8, 8.00, 'kg', '2025-11-21 06:00:00', '2025-11-24', 'Farm raised', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(9, 9, 5.00, 'kg', '2025-11-21 06:00:00', '2025-11-24', 'Medium size', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(10, 10, 6.00, 'kg', '2025-11-21 06:00:00', '2025-11-24', 'Cleaned', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(11, 11, 15.00, 'kg', '2025-11-20 08:00:00', '2025-11-26', 'For longganisa and lumpia', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(12, 12, 12.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'For bulalo and kare-kare', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(13, 13, 10.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'For crispy pata', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(14, 14, 8.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'Baby back ribs', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(15, 15, 10.00, 'kg', '2025-11-19 08:00:00', '2025-11-30', 'Pre-marinated', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(16, 16, 10.00, 'kg', '2025-11-19 08:00:00', '2025-11-30', 'Pre-marinated beef', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(17, 17, 8.00, 'kg', '2025-11-19 08:00:00', '2025-12-05', 'House recipe', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(18, 18, 20.00, 'pack', '2025-11-18 08:00:00', '2025-12-18', 'Jumbo size', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(19, 19, 5.00, 'kg', '2025-11-18 08:00:00', '2025-12-10', 'Smoked', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(20, 20, 24.00, 'can', '2025-11-15 08:00:00', '2026-11-15', 'Canned goods', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(21, 21, 20.00, 'can', '2025-11-15 08:00:00', '2026-11-15', 'Canned meat', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(22, 22, 10.00, 'tray', '2025-11-20 08:00:00', '2025-12-05', '30 pcs per tray', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(23, 23, 3.00, 'kg', '2025-11-18 08:00:00', '2025-12-18', 'Salted dried herring', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(24, 24, 2.50, 'kg', '2025-11-18 08:00:00', '2025-12-18', 'Dried rabbitfish', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(25, 25, 100.00, 'kg', '2025-11-19 08:00:00', '2026-05-19', 'Sinandomeng variety', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(26, 26, 10.00, 'kg', '2025-11-19 08:00:00', '2026-02-19', 'Pre-mixed seasoning', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(27, 27, 8.00, 'kg', '2025-11-15 08:00:00', '2026-02-15', 'Dried egg noodles', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(28, 28, 8.00, 'kg', '2025-11-15 08:00:00', '2026-02-15', 'Rice vermicelli', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(29, 29, 5.00, 'kg', '2025-11-15 08:00:00', '2026-02-15', 'Glass noodles', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(30, 30, 6.00, 'kg', '2025-11-15 08:00:00', '2026-02-15', 'Italian pasta', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(31, 31, 15.00, 'kg', '2025-11-20 08:00:00', '2025-12-05', 'Red onion preferred', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(32, 32, 8.00, 'kg', '2025-11-20 08:00:00', '2025-12-15', 'Native garlic', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(33, 33, 10.00, 'kg', '2025-11-21 06:00:00', '2025-11-28', 'Fresh ripe', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(34, 34, 5.00, 'kg', '2025-11-20 08:00:00', '2025-12-10', 'For soups and marinades', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(35, 35, 8.00, 'kg', '2025-11-21 06:00:00', '2025-11-28', 'For pancit and lumpia', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(36, 36, 6.00, 'kg', '2025-11-21 06:00:00', '2025-12-01', 'For pancit and menudo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(37, 37, 5.00, 'kg', '2025-11-21 06:00:00', '2025-11-30', 'For tinola', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(38, 38, 15.00, 'bundle', '2025-11-21 06:00:00', '2025-11-24', 'Water spinach', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(39, 39, 12.00, 'bundle', '2025-11-21 06:00:00', '2025-11-24', 'Bok choy', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(40, 40, 4.00, 'kg', '2025-11-21 06:00:00', '2025-11-26', 'String beans', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(41, 41, 6.00, 'kg', '2025-11-21 06:00:00', '2025-11-27', 'For tortang talong', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(42, 42, 4.00, 'kg', '2025-11-21 06:00:00', '2025-11-27', 'For ginisang ampalaya', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(43, 43, 10.00, 'bundle', '2025-11-21 06:00:00', '2025-11-24', 'Moringa leaves', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(44, 44, 5.00, 'kg', '2025-11-21 06:00:00', '2025-11-28', 'For tinola', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(45, 45, 8.00, 'pc', '2025-11-21 06:00:00', '2025-11-25', 'For kare-kare', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(46, 46, 5.00, 'kg', '2025-11-21 06:00:00', '2025-11-27', 'Long variety', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(47, 47, 3.00, 'kg', '2025-11-21 06:00:00', '2025-11-28', 'Mixed colors', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(48, 48, 2.00, 'kg', '2025-11-20 08:00:00', '2025-12-01', 'Siling labuyo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(49, 49, 5.00, 'kg', '2025-11-21 06:00:00', '2025-11-28', 'Philippine lime', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(50, 50, 3.00, 'kg', '2025-11-21 06:00:00', '2025-11-30', 'For drinks', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(51, 51, 4.00, 'kg', '2025-11-21 06:00:00', '2025-11-25', 'Iceberg variety', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(52, 52, 4.00, 'kg', '2025-11-21 06:00:00', '2025-11-27', 'For salads', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(53, 53, 10.00, 'kg', '2025-11-20 08:00:00', '2025-12-10', 'For fries and menudo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(54, 54, 5.00, 'kg', '2025-11-21 06:00:00', '2025-11-26', 'Sweet corn', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(55, 55, 10.00, 'liter', '2025-11-15 08:00:00', '2026-05-15', 'Silver Swan brand', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(56, 56, 10.00, 'liter', '2025-11-15 08:00:00', '2026-05-15', 'Cane vinegar', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(57, 57, 8.00, 'liter', '2025-11-15 08:00:00', '2026-05-15', 'Rufina brand', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(58, 58, 12.00, 'bottle', '2025-11-15 08:00:00', '2026-03-15', 'Lee Kum Kee', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(59, 59, 15.00, 'bottle', '2025-11-15 08:00:00', '2026-03-15', 'Jufran brand', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(60, 60, 20.00, 'can', '2025-11-15 08:00:00', '2026-05-15', 'Del Monte', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(61, 61, 10.00, 'jar', '2025-11-15 08:00:00', '2026-02-15', 'Best Foods', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(62, 62, 8.00, 'bottle', '2025-11-15 08:00:00', '2026-03-15', 'For sisig', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(63, 63, 6.00, 'jar', '2025-11-15 08:00:00', '2026-06-15', 'Sauteed', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(64, 64, 8.00, 'jar', '2025-11-15 08:00:00', '2026-04-15', 'For kare-kare', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(65, 65, 12.00, 'can', '2025-11-15 08:00:00', '2026-04-15', 'For Filipino spaghetti', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(66, 66, 5.00, 'bottle', '2025-11-15 08:00:00', '2026-06-15', 'For inasal color', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(67, 67, 4.00, 'bottle', '2025-11-15 08:00:00', '2026-06-15', 'Lea & Perrins', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(68, 68, 6.00, 'bottle', '2025-11-15 08:00:00', '2026-06-15', 'Tabasco', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(69, 69, 6.00, 'bottle', '2025-11-15 08:00:00', '2026-03-15', 'For grilled items', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(70, 70, 15.00, 'pack', '2025-11-15 08:00:00', '2026-06-15', 'Brown gravy', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(71, 71, 24.00, 'can', '2025-11-15 08:00:00', '2026-06-15', 'For desserts', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(72, 72, 24.00, 'can', '2025-11-15 08:00:00', '2026-06-15', 'For halo-halo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(73, 73, 10.00, 'liter', '2025-11-18 08:00:00', '2025-12-18', 'For laing and ginataang', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(74, 74, 12.00, 'can', '2025-11-15 08:00:00', '2026-03-15', 'Thick coconut milk', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(75, 75, 3.00, 'kg', '2025-11-18 08:00:00', '2026-01-18', 'Salted', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(76, 76, 4.00, 'kg', '2025-11-18 08:00:00', '2025-12-18', 'Quick melt', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(77, 77, 8.00, 'liter', '2025-11-21 06:00:00', '2025-11-28', 'For shakes', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(78, 78, 3.00, 'kg', '2025-11-15 08:00:00', '2026-05-15', 'Ground coffee', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(79, 79, 10.00, 'box', '2025-11-15 08:00:00', '2026-08-15', 'Assorted flavors', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(80, 80, 5.00, 'kg', '2025-11-15 08:00:00', '2026-06-15', 'Lemon flavor', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(81, 81, 3.00, 'kg', '2025-11-15 08:00:00', '2026-06-15', 'Powdered', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(82, 82, 3.00, 'kg', '2025-11-15 08:00:00', '2026-06-15', 'For drinks', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(83, 83, 10.00, 'case', '2025-11-18 08:00:00', '2026-03-18', 'Assorted 1.5L', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(84, 84, 15.00, 'case', '2025-11-18 08:00:00', '2026-06-18', '500ml bottles', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(85, 85, 8.00, 'liter', '2025-11-21 06:00:00', '2025-11-25', 'Fresh coconut water', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(86, 86, 20.00, 'liter', '2025-11-15 08:00:00', '2026-06-15', 'Vegetable oil', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(87, 87, 10.00, 'kg', '2025-11-15 08:00:00', '2027-11-15', 'Iodized', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(88, 88, 15.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'White refined', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(89, 89, 8.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'Muscovado', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(90, 90, 2.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'Ground black pepper', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(91, 91, 3.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'Ajinomoto', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(92, 92, 10.00, 'kg', '2025-11-15 08:00:00', '2026-05-15', 'All-purpose', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(93, 93, 5.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'For breading', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(94, 94, 4.00, 'kg', '2025-11-15 08:00:00', '2026-03-15', 'Japanese panko', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(95, 95, 20.00, 'pack', '2025-11-18 08:00:00', '2025-12-18', '25 sheets per pack', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(96, 96, 15.00, 'pack', '2025-11-18 08:00:00', '2025-12-18', 'Small size', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(97, 97, 10.00, 'pack', '2025-11-15 08:00:00', '2026-06-15', 'Instant mix', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(98, 98, 15.00, 'pack', '2025-11-15 08:00:00', '2026-09-15', 'For halo-halo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(99, 99, 5.00, 'kg', '2025-11-15 08:00:00', '2026-09-15', 'Tapioca pearls', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(100, 100, 10.00, 'jar', '2025-11-15 08:00:00', '2026-06-15', 'For halo-halo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(101, 101, 10.00, 'jar', '2025-11-15 08:00:00', '2026-06-15', 'Coconut gel', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(102, 102, 4.00, 'kg', '2025-11-18 08:00:00', '2025-12-18', 'Purple yam jam', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(103, 103, 3.00, 'kg', '2025-11-18 08:00:00', '2025-12-01', 'Sweetened', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(104, 104, 6.00, 'jar', '2025-11-15 08:00:00', '2026-06-15', 'Coconut sport', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(105, 105, 10.00, 'liter', '2025-11-18 08:00:00', '2026-02-18', 'Assorted flavors', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(106, 106, 50.00, 'kg', '2025-11-21 06:00:00', '2025-11-22', 'Made fresh daily', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(107, 107, 10.00, 'kg', '2025-11-21 06:00:00', '2025-11-26', 'Saba variety', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(108, 108, 10.00, 'pack', '2025-11-18 08:00:00', '2025-12-18', 'Lumpia wrapper for turon', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(109, 109, 8.00, 'liter', '2025-11-18 08:00:00', '2025-12-18', 'Homemade stock', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(110, 110, 6.00, 'liter', '2025-11-18 08:00:00', '2025-12-18', 'For sinigang', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(111, 111, 5.00, 'liter', '2025-11-18 08:00:00', '2025-12-18', 'For bulalo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(112, 112, 20.00, 'pack', '2025-11-15 08:00:00', '2026-06-15', 'Instant sinigang mix', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(113, 113, 2.00, 'kg', '2025-11-15 08:00:00', '2026-03-15', 'For miso soup', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(114, 114, 8.00, 'bundle', '2025-11-21 06:00:00', '2025-11-28', 'For inasal marinade', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(115, 115, 5.00, 'pack', '2025-11-15 08:00:00', '2026-11-15', 'Dried', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(116, 116, 1.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'Smoked', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(117, 117, 0.50, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'Ground', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(118, 118, 3.00, 'pack', '2025-11-15 08:00:00', '2026-11-15', 'Dried', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(119, 119, 1.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'For atsuete oil', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(120, 120, 5.00, 'bundle', '2025-11-21 06:00:00', '2025-11-26', 'For rice and desserts', '2025-11-22 01:06:39', '2025-11-22 01:06:39');

-- --------------------------------------------------------

--
-- Table structure for table `inventory_alerts`
--

CREATE TABLE `inventory_alerts` (
  `AlertID` int(10) NOT NULL,
  `AlertType` enum('Low Stock','Expiring Soon','Expired','Out of Stock','Overstocked') NOT NULL,
  `IngredientID` int(10) DEFAULT NULL,
  `BatchID` int(10) DEFAULT NULL,
  `AlertMessage` text NOT NULL,
  `Severity` enum('Critical','Warning','Info') DEFAULT 'Warning',
  `IsResolved` tinyint(1) DEFAULT 0,
  `ResolvedDate` datetime DEFAULT NULL,
  `CreatedDate` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `inventory_alerts`
--

INSERT INTO `inventory_alerts` (`AlertID`, `AlertType`, `IngredientID`, `BatchID`, `AlertMessage`, `Severity`, `IsResolved`, `ResolvedDate`, `CreatedDate`) VALUES
(128, 'Low Stock', 60, NULL, 'Tomato Sauce is low in stock. Current: 0.00 can, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(129, 'Low Stock', 28, NULL, 'Pancit Bihon Noodles is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(130, 'Low Stock', 92, NULL, 'Flour is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(131, 'Low Stock', 53, NULL, 'Potato is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(132, 'Low Stock', 117, NULL, 'Cumin is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(133, 'Low Stock', 21, NULL, 'Spam is low in stock. Current: 0.00 can, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(134, 'Low Stock', 85, NULL, 'Buko Juice is low in stock. Current: 0.00 liter, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(135, 'Low Stock', 46, NULL, 'Talong (Eggplant) is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(136, 'Low Stock', 110, NULL, 'Pork Broth is low in stock. Current: 0.00 liter, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(137, 'Low Stock', 14, NULL, 'Pork Ribs is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(138, 'Low Stock', 78, NULL, 'Coffee is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(139, 'Low Stock', 39, NULL, 'Pechay is low in stock. Current: 0.00 bundle, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(140, 'Low Stock', 103, NULL, 'Langka (Jackfruit) is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(141, 'Low Stock', 7, NULL, 'Bangus (Milkfish) is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(142, 'Low Stock', 71, NULL, 'Evaporated Milk is low in stock. Current: 0.00 can, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(143, 'Low Stock', 96, NULL, 'Spring Roll Wrapper is low in stock. Current: 0.00 pack, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(144, 'Low Stock', 64, NULL, 'Peanut Butter is low in stock. Current: 0.00 jar, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(145, 'Low Stock', 32, NULL, 'Garlic is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(146, 'Low Stock', 57, NULL, 'Fish Sauce (Patis) is low in stock. Current: 0.00 liter, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(147, 'Low Stock', 25, NULL, 'Rice is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(148, 'Low Stock', 89, NULL, 'Brown Sugar is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(149, 'Low Stock', 50, NULL, 'Lemon is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(150, 'Low Stock', 114, NULL, 'Lemongrass is low in stock. Current: 0.00 bundle, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(151, 'Low Stock', 18, NULL, 'Hotdog is low in stock. Current: 0.00 pack, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(152, 'Low Stock', 82, NULL, 'Chocolate Powder is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(153, 'Low Stock', 43, NULL, 'Malunggay Leaves is low in stock. Current: 0.00 bundle, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(154, 'Low Stock', 107, NULL, 'Banana is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(155, 'Low Stock', 11, NULL, 'Ground Pork is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(156, 'Low Stock', 75, NULL, 'Butter is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(157, 'Low Stock', 36, NULL, 'Carrots is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(158, 'Low Stock', 100, NULL, 'Kaong (Palm Fruit) is low in stock. Current: 0.00 jar, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(159, 'Low Stock', 4, NULL, 'Chicken Wings is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(160, 'Low Stock', 68, NULL, 'Hot Sauce is low in stock. Current: 0.00 bottle, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(161, 'Low Stock', 61, NULL, 'Mayonnaise is low in stock. Current: 0.00 jar, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(162, 'Low Stock', 29, NULL, 'Sotanghon Noodles is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(163, 'Low Stock', 93, NULL, 'Cornstarch is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(164, 'Low Stock', 54, NULL, 'Corn is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(165, 'Low Stock', 118, NULL, 'Oregano is low in stock. Current: 0.00 pack, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(166, 'Low Stock', 22, NULL, 'Eggs is low in stock. Current: 0.00 tray, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(167, 'Low Stock', 86, NULL, 'Cooking Oil is low in stock. Current: 0.00 liter, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(168, 'Low Stock', 47, NULL, 'Bell Pepper is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(169, 'Low Stock', 111, NULL, 'Beef Broth is low in stock. Current: 0.00 liter, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(170, 'Low Stock', 15, NULL, 'Tocino Meat is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(171, 'Low Stock', 79, NULL, 'Tea Bags is low in stock. Current: 0.00 box, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(172, 'Low Stock', 40, NULL, 'Green Beans (Sitaw) is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(173, 'Low Stock', 104, NULL, 'Macapuno is low in stock. Current: 0.00 jar, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(174, 'Low Stock', 8, NULL, 'Tilapia is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(175, 'Low Stock', 72, NULL, 'Condensed Milk is low in stock. Current: 0.00 can, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(176, 'Low Stock', 97, NULL, 'Leche Flan Mix is low in stock. Current: 0.00 pack, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(177, 'Low Stock', 1, NULL, 'Pork Belly is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(178, 'Low Stock', 65, NULL, 'Liver Spread is low in stock. Current: 0.00 can, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(179, 'Low Stock', 33, NULL, 'Tomato is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(180, 'Low Stock', 58, NULL, 'Oyster Sauce is low in stock. Current: 0.00 bottle, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(181, 'Low Stock', 26, NULL, 'Garlic Rice Mix is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(182, 'Low Stock', 90, NULL, 'Pepper is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(183, 'Low Stock', 51, NULL, 'Lettuce is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(184, 'Low Stock', 115, NULL, 'Bay Leaves is low in stock. Current: 0.00 pack, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(185, 'Low Stock', 19, NULL, 'Bacon is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(186, 'Low Stock', 83, NULL, 'Soft Drinks is low in stock. Current: 0.00 case, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(187, 'Low Stock', 44, NULL, 'Green Papaya is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(188, 'Low Stock', 108, NULL, 'Turon Wrapper is low in stock. Current: 0.00 pack, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(189, 'Low Stock', 12, NULL, 'Beef is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(190, 'Low Stock', 76, NULL, 'Cheese is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(191, 'Low Stock', 37, NULL, 'Sayote (Chayote) is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(192, 'Low Stock', 101, NULL, 'Nata de Coco is low in stock. Current: 0.00 jar, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(193, 'Low Stock', 5, NULL, 'Chicken Breast is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(194, 'Low Stock', 69, NULL, 'BBQ Sauce is low in stock. Current: 0.00 bottle, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(195, 'Low Stock', 62, NULL, 'Chili Garlic Sauce is low in stock. Current: 0.00 bottle, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(196, 'Low Stock', 30, NULL, 'Spaghetti Noodles is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(197, 'Low Stock', 94, NULL, 'Bread Crumbs is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(198, 'Low Stock', 55, NULL, 'Soy Sauce is low in stock. Current: 0.00 liter, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(199, 'Low Stock', 119, NULL, 'Annatto Seeds is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(200, 'Low Stock', 23, NULL, 'Dried Fish (Tuyo) is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(201, 'Low Stock', 87, NULL, 'Salt is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(202, 'Low Stock', 48, NULL, 'Chili Peppers is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(203, 'Low Stock', 112, NULL, 'Tamarind Mix (Sinigang) is low in stock. Current: 0.00 pack, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(204, 'Low Stock', 16, NULL, 'Tapa Meat is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(205, 'Low Stock', 80, NULL, 'Iced Tea Powder is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(206, 'Low Stock', 41, NULL, 'Eggplant is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(207, 'Low Stock', 105, NULL, 'Ice Cream is low in stock. Current: 0.00 liter, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(208, 'Low Stock', 9, NULL, 'Shrimp is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(209, 'Low Stock', 73, NULL, 'Coconut Milk is low in stock. Current: 0.00 liter, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(210, 'Low Stock', 98, NULL, 'Gulaman (Agar) is low in stock. Current: 0.00 pack, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(211, 'Low Stock', 2, NULL, 'Pork Liempo is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(212, 'Low Stock', 66, NULL, 'Achuete (Annatto) Oil is low in stock. Current: 0.00 bottle, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(213, 'Low Stock', 34, NULL, 'Ginger is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(214, 'Low Stock', 59, NULL, 'Banana Ketchup is low in stock. Current: 0.00 bottle, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(215, 'Low Stock', 27, NULL, 'Pancit Canton Noodles is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(216, 'Low Stock', 91, NULL, 'MSG is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(217, 'Low Stock', 52, NULL, 'Cucumber is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(218, 'Low Stock', 116, NULL, 'Paprika is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(219, 'Low Stock', 20, NULL, 'Corned Beef is low in stock. Current: 0.00 can, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(220, 'Low Stock', 84, NULL, 'Mineral Water is low in stock. Current: 0.00 case, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(221, 'Low Stock', 45, NULL, 'Banana Blossom is low in stock. Current: 0.00 pc, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(222, 'Low Stock', 109, NULL, 'Chicken Broth is low in stock. Current: 0.00 liter, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(223, 'Low Stock', 13, NULL, 'Pork Knuckle (Pata) is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(224, 'Low Stock', 77, NULL, 'Fresh Milk is low in stock. Current: 0.00 liter, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(225, 'Low Stock', 38, NULL, 'Kangkong is low in stock. Current: 0.00 bundle, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(226, 'Low Stock', 102, NULL, 'Ube Halaya is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(227, 'Low Stock', 6, NULL, 'Pork Sisig Meat is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(228, 'Low Stock', 70, NULL, 'Gravy Mix is low in stock. Current: 0.00 pack, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(229, 'Low Stock', 63, NULL, 'Bagoong (Shrimp Paste) is low in stock. Current: 0.00 jar, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(230, 'Low Stock', 31, NULL, 'Onion is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(231, 'Low Stock', 95, NULL, 'Lumpia Wrapper is low in stock. Current: 0.00 pack, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(232, 'Low Stock', 56, NULL, 'Vinegar is low in stock. Current: 0.00 liter, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(233, 'Low Stock', 120, NULL, 'Pandan Leaves is low in stock. Current: 0.00 bundle, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(234, 'Low Stock', 24, NULL, 'Danggit is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(235, 'Low Stock', 88, NULL, 'Sugar is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(236, 'Low Stock', 49, NULL, 'Calamansi is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(237, 'Low Stock', 113, NULL, 'Miso Paste is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(238, 'Low Stock', 17, NULL, 'Longganisa is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(239, 'Low Stock', 81, NULL, 'Mango Shake Mix is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(240, 'Low Stock', 42, NULL, 'Ampalaya (Bitter Gourd) is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(241, 'Low Stock', 106, NULL, 'Shaved Ice is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(242, 'Low Stock', 10, NULL, 'Squid is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(243, 'Low Stock', 74, NULL, 'Coconut Cream is low in stock. Current: 0.00 can, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(244, 'Low Stock', 99, NULL, 'Sago Pearls is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(245, 'Low Stock', 3, NULL, 'Chicken Whole is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(246, 'Low Stock', 67, NULL, 'Worcestershire Sauce is low in stock. Current: 0.00 bottle, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23'),
(247, 'Low Stock', 35, NULL, 'Cabbage is low in stock. Current: 0.00 kg, Min: 5.00', 'Warning', 0, NULL, '2025-11-23 18:23:23');

-- --------------------------------------------------------

--
-- Table structure for table `inventory_audit_logs`
--

CREATE TABLE `inventory_audit_logs` (
  `AuditID` int(10) NOT NULL,
  `BatchID` int(10) NOT NULL,
  `ExpectedStock` decimal(10,2) NOT NULL COMMENT 'System stock before count',
  `ActualStock` decimal(10,2) NOT NULL COMMENT 'Physically counted amount',
  `Variance` decimal(10,2) GENERATED ALWAYS AS (`ActualStock` - `ExpectedStock`) STORED,
  `VariancePercent` decimal(10,2) GENERATED ALWAYS AS (case when `ExpectedStock` > 0 then (`ActualStock` - `ExpectedStock`) / `ExpectedStock` * 100 else 0 end) STORED,
  `AuditDate` datetime DEFAULT current_timestamp(),
  `AuditedBy` varchar(100) DEFAULT NULL COMMENT 'Staff who performed count',
  `Notes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `inventory_backup`
--

CREATE TABLE `inventory_backup` (
  `InventoryID` int(10) NOT NULL DEFAULT 0 COMMENT 'Unique inventory record ID',
  `IngredientID` int(10) NOT NULL COMMENT 'Linked to Ingredients(IngredientID)',
  `StockQuantity` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Current stock level',
  `UnitType` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Measurement unit (kg, pack, liter, can, bottle, tray, bundle, jar, pc)',
  `LastRestockedDate` datetime DEFAULT NULL COMMENT 'Last restock date/time when purchased',
  `ExpirationDate` date DEFAULT NULL COMMENT 'Expiry date if perishable',
  `Remarks` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Notes about ingredient condition or source',
  `CreatedDate` datetime DEFAULT current_timestamp() COMMENT 'Record creation date',
  `UpdatedDate` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last update timestamp'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `inventory_backup`
--

INSERT INTO `inventory_backup` (`InventoryID`, `IngredientID`, `StockQuantity`, `UnitType`, `LastRestockedDate`, `ExpirationDate`, `Remarks`, `CreatedDate`, `UpdatedDate`) VALUES
(1, 1, 25.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'Fresh delivery twice weekly', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(2, 2, 20.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'Main grilling meat', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(3, 3, 30.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'For inasal and fried chicken', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(4, 4, 15.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'Buffalo wings stock', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(5, 5, 18.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'For sisig and salads', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(6, 6, 12.00, 'kg', '2025-11-20 08:00:00', '2025-11-26', 'Pre-chopped pig face and ears', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(7, 7, 10.00, 'kg', '2025-11-21 06:00:00', '2025-11-24', 'Fresh catch', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(8, 8, 8.00, 'kg', '2025-11-21 06:00:00', '2025-11-24', 'Farm raised', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(9, 9, 5.00, 'kg', '2025-11-21 06:00:00', '2025-11-24', 'Medium size', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(10, 10, 6.00, 'kg', '2025-11-21 06:00:00', '2025-11-24', 'Cleaned', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(11, 11, 15.00, 'kg', '2025-11-20 08:00:00', '2025-11-26', 'For longganisa and lumpia', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(12, 12, 12.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'For bulalo and kare-kare', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(13, 13, 10.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'For crispy pata', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(14, 14, 8.00, 'kg', '2025-11-20 08:00:00', '2025-11-27', 'Baby back ribs', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(15, 15, 10.00, 'kg', '2025-11-19 08:00:00', '2025-11-30', 'Pre-marinated', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(16, 16, 10.00, 'kg', '2025-11-19 08:00:00', '2025-11-30', 'Pre-marinated beef', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(17, 17, 8.00, 'kg', '2025-11-19 08:00:00', '2025-12-05', 'House recipe', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(18, 18, 20.00, 'pack', '2025-11-18 08:00:00', '2025-12-18', 'Jumbo size', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(19, 19, 5.00, 'kg', '2025-11-18 08:00:00', '2025-12-10', 'Smoked', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(20, 20, 24.00, 'can', '2025-11-15 08:00:00', '2026-11-15', 'Canned goods', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(21, 21, 20.00, 'can', '2025-11-15 08:00:00', '2026-11-15', 'Canned meat', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(22, 22, 10.00, 'tray', '2025-11-20 08:00:00', '2025-12-05', '30 pcs per tray', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(23, 23, 3.00, 'kg', '2025-11-18 08:00:00', '2025-12-18', 'Salted dried herring', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(24, 24, 2.50, 'kg', '2025-11-18 08:00:00', '2025-12-18', 'Dried rabbitfish', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(25, 25, 100.00, 'kg', '2025-11-19 08:00:00', '2026-05-19', 'Sinandomeng variety', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(26, 26, 10.00, 'kg', '2025-11-19 08:00:00', '2026-02-19', 'Pre-mixed seasoning', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(27, 27, 8.00, 'kg', '2025-11-15 08:00:00', '2026-02-15', 'Dried egg noodles', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(28, 28, 8.00, 'kg', '2025-11-15 08:00:00', '2026-02-15', 'Rice vermicelli', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(29, 29, 5.00, 'kg', '2025-11-15 08:00:00', '2026-02-15', 'Glass noodles', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(30, 30, 6.00, 'kg', '2025-11-15 08:00:00', '2026-02-15', 'Italian pasta', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(31, 31, 15.00, 'kg', '2025-11-20 08:00:00', '2025-12-05', 'Red onion preferred', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(32, 32, 8.00, 'kg', '2025-11-20 08:00:00', '2025-12-15', 'Native garlic', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(33, 33, 10.00, 'kg', '2025-11-21 06:00:00', '2025-11-28', 'Fresh ripe', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(34, 34, 5.00, 'kg', '2025-11-20 08:00:00', '2025-12-10', 'For soups and marinades', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(35, 35, 8.00, 'kg', '2025-11-21 06:00:00', '2025-11-28', 'For pancit and lumpia', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(36, 36, 6.00, 'kg', '2025-11-21 06:00:00', '2025-12-01', 'For pancit and menudo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(37, 37, 5.00, 'kg', '2025-11-21 06:00:00', '2025-11-30', 'For tinola', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(38, 38, 15.00, 'bundle', '2025-11-21 06:00:00', '2025-11-24', 'Water spinach', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(39, 39, 12.00, 'bundle', '2025-11-21 06:00:00', '2025-11-24', 'Bok choy', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(40, 40, 4.00, 'kg', '2025-11-21 06:00:00', '2025-11-26', 'String beans', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(41, 41, 6.00, 'kg', '2025-11-21 06:00:00', '2025-11-27', 'For tortang talong', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(42, 42, 4.00, 'kg', '2025-11-21 06:00:00', '2025-11-27', 'For ginisang ampalaya', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(43, 43, 10.00, 'bundle', '2025-11-21 06:00:00', '2025-11-24', 'Moringa leaves', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(44, 44, 5.00, 'kg', '2025-11-21 06:00:00', '2025-11-28', 'For tinola', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(45, 45, 8.00, 'pc', '2025-11-21 06:00:00', '2025-11-25', 'For kare-kare', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(46, 46, 5.00, 'kg', '2025-11-21 06:00:00', '2025-11-27', 'Long variety', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(47, 47, 3.00, 'kg', '2025-11-21 06:00:00', '2025-11-28', 'Mixed colors', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(48, 48, 2.00, 'kg', '2025-11-20 08:00:00', '2025-12-01', 'Siling labuyo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(49, 49, 5.00, 'kg', '2025-11-21 06:00:00', '2025-11-28', 'Philippine lime', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(50, 50, 3.00, 'kg', '2025-11-21 06:00:00', '2025-11-30', 'For drinks', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(51, 51, 4.00, 'kg', '2025-11-21 06:00:00', '2025-11-25', 'Iceberg variety', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(52, 52, 4.00, 'kg', '2025-11-21 06:00:00', '2025-11-27', 'For salads', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(53, 53, 10.00, 'kg', '2025-11-20 08:00:00', '2025-12-10', 'For fries and menudo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(54, 54, 5.00, 'kg', '2025-11-21 06:00:00', '2025-11-26', 'Sweet corn', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(55, 55, 10.00, 'liter', '2025-11-15 08:00:00', '2026-05-15', 'Silver Swan brand', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(56, 56, 10.00, 'liter', '2025-11-15 08:00:00', '2026-05-15', 'Cane vinegar', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(57, 57, 8.00, 'liter', '2025-11-15 08:00:00', '2026-05-15', 'Rufina brand', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(58, 58, 12.00, 'bottle', '2025-11-15 08:00:00', '2026-03-15', 'Lee Kum Kee', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(59, 59, 15.00, 'bottle', '2025-11-15 08:00:00', '2026-03-15', 'Jufran brand', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(60, 60, 20.00, 'can', '2025-11-15 08:00:00', '2026-05-15', 'Del Monte', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(61, 61, 10.00, 'jar', '2025-11-15 08:00:00', '2026-02-15', 'Best Foods', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(62, 62, 8.00, 'bottle', '2025-11-15 08:00:00', '2026-03-15', 'For sisig', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(63, 63, 6.00, 'jar', '2025-11-15 08:00:00', '2026-06-15', 'Sauteed', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(64, 64, 8.00, 'jar', '2025-11-15 08:00:00', '2026-04-15', 'For kare-kare', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(65, 65, 12.00, 'can', '2025-11-15 08:00:00', '2026-04-15', 'For Filipino spaghetti', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(66, 66, 5.00, 'bottle', '2025-11-15 08:00:00', '2026-06-15', 'For inasal color', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(67, 67, 4.00, 'bottle', '2025-11-15 08:00:00', '2026-06-15', 'Lea & Perrins', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(68, 68, 6.00, 'bottle', '2025-11-15 08:00:00', '2026-06-15', 'Tabasco', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(69, 69, 6.00, 'bottle', '2025-11-15 08:00:00', '2026-03-15', 'For grilled items', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(70, 70, 15.00, 'pack', '2025-11-15 08:00:00', '2026-06-15', 'Brown gravy', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(71, 71, 24.00, 'can', '2025-11-15 08:00:00', '2026-06-15', 'For desserts', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(72, 72, 24.00, 'can', '2025-11-15 08:00:00', '2026-06-15', 'For halo-halo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(73, 73, 10.00, 'liter', '2025-11-18 08:00:00', '2025-12-18', 'For laing and ginataang', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(74, 74, 12.00, 'can', '2025-11-15 08:00:00', '2026-03-15', 'Thick coconut milk', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(75, 75, 3.00, 'kg', '2025-11-18 08:00:00', '2026-01-18', 'Salted', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(76, 76, 4.00, 'kg', '2025-11-18 08:00:00', '2025-12-18', 'Quick melt', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(77, 77, 8.00, 'liter', '2025-11-21 06:00:00', '2025-11-28', 'For shakes', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(78, 78, 3.00, 'kg', '2025-11-15 08:00:00', '2026-05-15', 'Ground coffee', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(79, 79, 10.00, 'box', '2025-11-15 08:00:00', '2026-08-15', 'Assorted flavors', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(80, 80, 5.00, 'kg', '2025-11-15 08:00:00', '2026-06-15', 'Lemon flavor', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(81, 81, 3.00, 'kg', '2025-11-15 08:00:00', '2026-06-15', 'Powdered', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(82, 82, 3.00, 'kg', '2025-11-15 08:00:00', '2026-06-15', 'For drinks', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(83, 83, 10.00, 'case', '2025-11-18 08:00:00', '2026-03-18', 'Assorted 1.5L', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(84, 84, 15.00, 'case', '2025-11-18 08:00:00', '2026-06-18', '500ml bottles', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(85, 85, 8.00, 'liter', '2025-11-21 06:00:00', '2025-11-25', 'Fresh coconut water', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(86, 86, 20.00, 'liter', '2025-11-15 08:00:00', '2026-06-15', 'Vegetable oil', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(87, 87, 10.00, 'kg', '2025-11-15 08:00:00', '2027-11-15', 'Iodized', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(88, 88, 15.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'White refined', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(89, 89, 8.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'Muscovado', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(90, 90, 2.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'Ground black pepper', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(91, 91, 3.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'Ajinomoto', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(92, 92, 10.00, 'kg', '2025-11-15 08:00:00', '2026-05-15', 'All-purpose', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(93, 93, 5.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'For breading', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(94, 94, 4.00, 'kg', '2025-11-15 08:00:00', '2026-03-15', 'Japanese panko', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(95, 95, 20.00, 'pack', '2025-11-18 08:00:00', '2025-12-18', '25 sheets per pack', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(96, 96, 15.00, 'pack', '2025-11-18 08:00:00', '2025-12-18', 'Small size', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(97, 97, 10.00, 'pack', '2025-11-15 08:00:00', '2026-06-15', 'Instant mix', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(98, 98, 15.00, 'pack', '2025-11-15 08:00:00', '2026-09-15', 'For halo-halo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(99, 99, 5.00, 'kg', '2025-11-15 08:00:00', '2026-09-15', 'Tapioca pearls', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(100, 100, 10.00, 'jar', '2025-11-15 08:00:00', '2026-06-15', 'For halo-halo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(101, 101, 10.00, 'jar', '2025-11-15 08:00:00', '2026-06-15', 'Coconut gel', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(102, 102, 4.00, 'kg', '2025-11-18 08:00:00', '2025-12-18', 'Purple yam jam', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(103, 103, 3.00, 'kg', '2025-11-18 08:00:00', '2025-12-01', 'Sweetened', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(104, 104, 6.00, 'jar', '2025-11-15 08:00:00', '2026-06-15', 'Coconut sport', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(105, 105, 10.00, 'liter', '2025-11-18 08:00:00', '2026-02-18', 'Assorted flavors', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(106, 106, 50.00, 'kg', '2025-11-21 06:00:00', '2025-11-22', 'Made fresh daily', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(107, 107, 10.00, 'kg', '2025-11-21 06:00:00', '2025-11-26', 'Saba variety', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(108, 108, 10.00, 'pack', '2025-11-18 08:00:00', '2025-12-18', 'Lumpia wrapper for turon', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(109, 109, 8.00, 'liter', '2025-11-18 08:00:00', '2025-12-18', 'Homemade stock', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(110, 110, 6.00, 'liter', '2025-11-18 08:00:00', '2025-12-18', 'For sinigang', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(111, 111, 5.00, 'liter', '2025-11-18 08:00:00', '2025-12-18', 'For bulalo', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(112, 112, 20.00, 'pack', '2025-11-15 08:00:00', '2026-06-15', 'Instant sinigang mix', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(113, 113, 2.00, 'kg', '2025-11-15 08:00:00', '2026-03-15', 'For miso soup', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(114, 114, 8.00, 'bundle', '2025-11-21 06:00:00', '2025-11-28', 'For inasal marinade', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(115, 115, 5.00, 'pack', '2025-11-15 08:00:00', '2026-11-15', 'Dried', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(116, 116, 1.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'Smoked', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(117, 117, 0.50, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'Ground', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(118, 118, 3.00, 'pack', '2025-11-15 08:00:00', '2026-11-15', 'Dried', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(119, 119, 1.00, 'kg', '2025-11-15 08:00:00', '2026-11-15', 'For atsuete oil', '2025-11-22 01:06:39', '2025-11-22 01:06:39'),
(120, 120, 5.00, 'bundle', '2025-11-21 06:00:00', '2025-11-26', 'For rice and desserts', '2025-11-22 01:06:39', '2025-11-22 01:06:39');

-- --------------------------------------------------------

--
-- Table structure for table `inventory_batches`
--

CREATE TABLE `inventory_batches` (
  `BatchID` int(10) NOT NULL COMMENT 'Unique batch identifier',
  `IngredientID` int(10) NOT NULL COMMENT 'Reference to ingredients table',
  `BatchNumber` varchar(50) NOT NULL COMMENT 'Auto-generated batch number',
  `StockQuantity` decimal(10,2) NOT NULL DEFAULT 0.00 COMMENT 'Current stock in this batch',
  `OriginalQuantity` decimal(10,2) NOT NULL COMMENT 'Initial quantity purchased',
  `UnitType` varchar(50) NOT NULL COMMENT 'kg, g, L, ml, pc, pack, etc.',
  `CostPerUnit` decimal(10,2) DEFAULT 0.00 COMMENT 'Purchase cost per unit',
  `TotalCost` decimal(10,2) GENERATED ALWAYS AS (`OriginalQuantity` * `CostPerUnit`) STORED,
  `PurchaseDate` datetime NOT NULL COMMENT 'When this batch was purchased',
  `ExpirationDate` date DEFAULT NULL COMMENT 'Expiry date for this batch',
  `StorageLocation` enum('Freezer-Meat','Freezer-Seafood','Freezer-Processed','Refrigerator-Dairy','Refrigerator-Vegetables','Refrigerator-Condiments','Pantry-Dry-Goods','Pantry-Canned','Pantry-Condiments','Pantry-Spices','Pantry-Beverages') DEFAULT 'Pantry-Dry-Goods',
  `BatchStatus` enum('Active','Depleted','Expired','Discarded') DEFAULT 'Active',
  `Notes` text DEFAULT NULL COMMENT 'Any special notes about this batch',
  `CreatedDate` datetime DEFAULT current_timestamp(),
  `UpdatedDate` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `inventory_batches`
--

INSERT INTO `inventory_batches` (`BatchID`, `IngredientID`, `BatchNumber`, `StockQuantity`, `OriginalQuantity`, `UnitType`, `CostPerUnit`, `PurchaseDate`, `ExpirationDate`, `StorageLocation`, `BatchStatus`, `Notes`, `CreatedDate`, `UpdatedDate`) VALUES
(1, 1, 'POR001-20251124-001', 25.00, 25.00, 'kg', 180.00, '2025-11-24 01:04:07', '2025-12-01', 'Freezer-Meat', 'Active', 'Market Source: Quiapo Market | Fresh delivery, twice weekly supply', '2025-11-24 01:04:07', '2025-11-25 14:34:54'),
(2, 2, 'POR002-20251124-001', 20.00, 20.00, 'kg', 220.00, '2025-11-24 01:04:07', '2025-12-01', 'Freezer-Meat', 'Active', 'Market Source: Pasig Public Market | Premium grilling cut', '2025-11-24 01:04:07', '2025-11-25 14:34:54'),
(3, 3, 'CHI001-20251124-001', 30.00, 30.00, 'kg', 120.00, '2025-11-23 01:04:07', '2025-11-30', 'Freezer-Meat', 'Active', 'Market Source: Crown Poultry | Fresh whole chicken', '2025-11-24 01:04:07', '2025-11-25 14:34:54'),
(4, 4, 'CHI002-20251124-001', 15.00, 15.00, 'kg', 100.00, '2025-11-24 01:04:07', '2025-11-30', 'Freezer-Meat', 'Active', 'Market Source: Crown Poultry | Buffalo wings stock', '2025-11-24 01:04:07', '2025-11-25 14:34:54'),
(5, 5, 'CHI003-20251124-001', 18.00, 18.00, 'kg', 140.00, '2025-11-24 01:04:07', '2025-12-01', 'Freezer-Meat', 'Active', 'Market Source: Pasig Public Market | Boneless chicken breast', '2025-11-24 01:04:07', '2025-11-25 14:34:54'),
(6, 6, 'POR003-20251124-001', 12.00, 12.00, 'kg', 250.00, '2025-11-23 01:04:07', '2025-11-29', 'Freezer-Meat', 'Active', 'Market Source: Quiapo Market | Pre-chopped pig face and ears', '2025-11-24 01:04:07', '2025-11-25 14:34:54'),
(7, 7, 'SEA001-20251124-001', 10.00, 10.00, 'kg', 200.00, '2025-11-24 01:04:08', '2025-11-27', 'Freezer-Seafood', 'Active', 'Market Source: Navotas Fish Port | Fresh catch - early morning delivery', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(8, 8, 'SEA002-20251124-001', 8.00, 8.00, 'kg', 150.00, '2025-11-24 01:04:08', '2025-11-27', 'Freezer-Seafood', 'Active', 'Market Source: Laguna Fish Farm | Farm raised tilapia', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(9, 9, 'SEA003-20251124-001', 5.00, 5.00, 'kg', 350.00, '2025-11-24 01:04:08', '2025-11-26', 'Freezer-Seafood', 'Active', 'Market Source: Navotas Fish Port | Medium size fresh shrimp', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(10, 10, 'SEA004-20251124-001', 6.00, 6.00, 'kg', 280.00, '2025-11-24 01:04:08', '2025-11-26', 'Freezer-Seafood', 'Active', 'Market Source: Navotas Fish Port | Cleaned and ready to cook', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(11, 11, 'POR004-20251124-001', 15.00, 15.00, 'kg', 200.00, '2025-11-24 01:04:08', '2025-11-29', 'Freezer-Meat', 'Active', 'Market Source: Pasig Public Market | For longganisa and lumpia', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(12, 12, 'BEE001-20251124-001', 12.00, 12.00, 'kg', 320.00, '2025-11-23 01:04:08', '2025-11-30', 'Freezer-Meat', 'Active', 'Market Source: Pasig Public Market | For bulalo and kare-kare', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(13, 13, 'POR005-20251124-001', 10.00, 10.00, 'kg', 150.00, '2025-11-24 01:04:08', '2025-12-01', 'Freezer-Meat', 'Active', 'Market Source: Quiapo Market | For crispy pata', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(14, 14, 'POR006-20251124-001', 8.00, 8.00, 'kg', 280.00, '2025-11-24 01:04:08', '2025-12-01', 'Freezer-Meat', 'Active', 'Market Source: Quiapo Market | Baby back ribs', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(15, 15, 'POR007-20251124-001', 10.00, 10.00, 'kg', 280.00, '2025-11-22 01:04:08', '2025-12-02', 'Freezer-Processed', 'Active', 'Market Source: Pasig Public Market | Pre-marinated pork', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(16, 16, 'BEE002-20251124-001', 10.00, 10.00, 'kg', 350.00, '2025-11-22 01:04:08', '2025-12-02', 'Freezer-Processed', 'Active', 'Market Source: Pasig Public Market | Pre-marinated beef', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(17, 17, 'POR008-20251124-001', 8.00, 8.00, 'kg', 320.00, '2025-11-21 01:04:08', '2025-12-07', 'Freezer-Processed', 'Active', 'Market Source: Local Supplier | House recipe longganisa', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(18, 18, 'MET001-20251124-001', 20.00, 20.00, 'pack', 180.00, '2025-11-20 01:04:08', '2025-12-18', 'Freezer-Processed', 'Active', 'Market Source: Sari-Sari Store | Jumbo size hotdogs', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(19, 19, 'MET002-20251124-001', 5.00, 5.00, 'kg', 420.00, '2025-11-20 01:04:08', '2025-12-10', 'Freezer-Processed', 'Active', 'Market Source: Pasig Public Market | Smoked bacon', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(20, 20, 'MET003-20251124-001', 24.00, 24.00, 'can', 95.00, '2025-11-17 01:04:08', '2026-11-24', 'Pantry-Canned', 'Active', 'Market Source: Supermarket | Canned goods - long shelf life', '2025-11-24 01:04:08', '2025-11-25 14:34:54'),
(21, 21, 'MET004-20251124-001', 20.00, 20.00, 'can', 125.00, '2025-11-17 01:04:09', '2026-11-24', 'Pantry-Canned', 'Active', 'Market Source: Supermarket | Canned processed meat', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(22, 22, 'DAI001-20251124-001', 10.00, 10.00, 'tray', 140.00, '2025-11-24 01:04:09', '2025-12-09', 'Refrigerator-Dairy', 'Active', 'Market Source: Local Farm | 30 pcs per tray - fresh eggs', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(23, 27, 'DRY001-20251124-001', 8.00, 8.00, 'kg', 150.00, '2025-11-14 01:04:09', '2026-02-22', 'Pantry-Dry-Goods', 'Active', 'Market Source: Supermarket | Dried egg noodles', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(24, 28, 'DRY002-20251124-001', 8.00, 8.00, 'kg', 160.00, '2025-11-14 01:04:09', '2026-02-22', 'Pantry-Dry-Goods', 'Active', 'Market Source: Supermarket | Rice vermicelli', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(25, 29, 'DRY003-20251124-001', 5.00, 5.00, 'kg', 180.00, '2025-11-14 01:04:09', '2026-02-22', 'Pantry-Dry-Goods', 'Active', 'Market Source: Supermarket | Glass noodles', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(26, 30, 'DRY004-20251124-001', 6.00, 6.00, 'kg', 140.00, '2025-11-14 01:04:09', '2026-02-22', 'Pantry-Dry-Goods', 'Active', 'Market Source: Supermarket | Italian pasta', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(27, 31, 'VEG001-20251124-001', 15.00, 15.00, 'kg', 40.00, '2025-11-24 01:04:09', '2025-12-09', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | Red onion preferred', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(28, 32, 'VEG002-20251124-001', 8.00, 8.00, 'kg', 80.00, '2025-11-24 01:04:09', '2025-12-19', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | Native garlic', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(29, 33, 'VEG003-20251124-001', 10.00, 10.00, 'kg', 60.00, '2025-11-24 01:04:09', '2025-12-01', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | Fresh ripe tomatoes', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(30, 34, 'VEG004-20251124-001', 5.00, 5.00, 'kg', 100.00, '2025-11-24 01:04:09', '2025-12-14', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | For soups and marinades', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(31, 35, 'VEG005-20251124-001', 8.00, 8.00, 'kg', 50.00, '2025-11-24 01:04:09', '2025-12-01', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | For pancit and lumpia', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(32, 36, 'VEG006-20251124-001', 6.00, 6.00, 'kg', 45.00, '2025-11-24 01:04:09', '2025-12-04', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | For pancit and menudo', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(33, 53, 'VEG020-20251124-001', 10.00, 10.00, 'kg', 50.00, '2025-11-24 01:04:09', '2025-12-14', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | For fries and menudo', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(34, 55, 'CON001-20251124-001', 10.00, 10.00, 'liter', 80.00, '2025-11-17 01:04:09', '2026-05-23', 'Pantry-Condiments', 'Active', 'Market Source: Supermarket | Silver Swan brand', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(35, 56, 'CON002-20251124-001', 10.00, 10.00, 'liter', 60.00, '2025-11-17 01:04:09', '2026-05-23', 'Pantry-Condiments', 'Active', 'Market Source: Supermarket | Cane vinegar', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(36, 57, 'CON003-20251124-001', 8.00, 8.00, 'liter', 120.00, '2025-11-17 01:04:09', '2026-05-23', 'Pantry-Condiments', 'Active', 'Market Source: Supermarket | Rufina brand', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(37, 58, 'CON004-20251124-001', 12.00, 12.00, 'bottle', 100.00, '2025-11-17 01:04:09', '2026-03-24', 'Pantry-Condiments', 'Active', 'Market Source: Supermarket | Lee Kum Kee', '2025-11-24 01:04:09', '2025-11-25 14:34:54'),
(38, 59, 'CON005-20251124-001', 15.00, 15.00, 'bottle', 75.00, '2025-11-17 01:04:10', '2026-03-24', 'Pantry-Condiments', 'Active', 'Market Source: Supermarket | Jufran brand', '2025-11-24 01:04:10', '2025-11-25 14:34:54'),
(39, 60, 'CON006-20251124-001', 20.00, 20.00, 'can', 40.00, '2025-11-17 01:04:10', '2026-05-23', 'Pantry-Condiments', 'Active', 'Market Source: Supermarket | Del Monte', '2025-11-24 01:04:10', '2025-11-25 14:34:54'),
(40, 83, 'BEV001-20251124-001', 10.00, 10.00, 'case', 400.00, '2025-11-20 01:04:10', '2026-03-24', 'Pantry-Beverages', 'Active', 'Market Source: Distributor | Assorted 1.5L bottles', '2025-11-24 01:04:10', '2025-11-25 14:34:54'),
(41, 84, 'BEV002-20251124-001', 15.00, 15.00, 'case', 250.00, '2025-11-20 01:04:10', '2026-05-23', 'Pantry-Beverages', 'Active', 'Market Source: Distributor | 500ml bottles', '2025-11-24 01:04:10', '2025-11-25 14:34:54'),
(42, 85, 'BEV003-20251124-001', 8.00, 8.00, 'liter', 150.00, '2025-11-24 01:04:10', '2025-11-28', 'Pantry-Beverages', 'Active', 'Market Source: Local Vendor | Fresh coconut water', '2025-11-24 01:04:10', '2025-11-25 14:34:54'),
(43, 87, 'SPI001-20251124-001', 10.00, 10.00, 'kg', 30.00, '2025-10-25 01:04:10', '2026-11-24', 'Pantry-Spices', 'Active', 'Market Source: Supermarket | Iodized salt', '2025-11-24 01:04:10', '2025-11-25 14:34:54'),
(44, 88, 'SPI002-20251124-001', 15.00, 15.00, 'kg', 50.00, '2025-10-25 01:04:10', '2026-11-24', 'Pantry-Spices', 'Active', 'Market Source: Supermarket | White refined sugar', '2025-11-24 01:04:10', '2025-11-25 14:34:54'),
(45, 90, 'SPI004-20251124-001', 2.00, 2.00, 'kg', 400.00, '2025-10-25 01:04:10', '2026-11-24', 'Pantry-Spices', 'Active', 'Market Source: Supermarket | Ground black pepper', '2025-11-24 01:04:10', '2025-11-25 14:34:54'),
(46, 91, 'SPI005-20251124-001', 3.00, 3.00, 'kg', 200.00, '2025-10-25 01:04:10', '2026-11-24', 'Pantry-Spices', 'Active', 'Market Source: Supermarket | Ajinomoto', '2025-11-24 01:04:10', '2025-11-25 14:34:54'),
(69, 23, 'DRI001-20251124-001', 3.00, 3.00, 'kg', 200.00, '2025-11-20 01:05:04', '2025-12-24', 'Pantry-Dry-Goods', 'Active', 'Market Source: Quiapo Market | Salted dried herring', '2025-11-24 01:05:04', '2025-11-25 14:34:54'),
(70, 24, 'DRI002-20251124-001', 2.50, 2.50, 'kg', 250.00, '2025-11-20 01:05:04', '2025-12-24', 'Pantry-Dry-Goods', 'Active', 'Market Source: Quiapo Market | Dried rabbitfish', '2025-11-24 01:05:04', '2025-11-25 14:34:54'),
(75, 29, 'DRY005-20251124-001', 5.00, 5.00, 'kg', 180.00, '2025-11-14 01:05:04', '2026-02-22', 'Pantry-Dry-Goods', 'Active', 'Market Source: Supermarket | Glass noodles', '2025-11-24 01:05:04', '2025-11-25 14:34:54'),
(76, 30, 'DRY006-20251124-001', 6.00, 6.00, 'kg', 140.00, '2025-11-14 01:05:04', '2026-02-22', 'Pantry-Dry-Goods', 'Active', 'Market Source: Supermarket | Italian pasta', '2025-11-24 01:05:04', '2025-11-25 14:34:54'),
(83, 37, 'VEG007-20251124-001', 5.00, 5.00, 'kg', 40.00, '2025-11-24 01:05:04', '2025-12-04', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | For tinola', '2025-11-24 01:05:04', '2025-11-25 14:34:54'),
(84, 38, 'VEG008-20251124-001', 15.00, 15.00, 'bundle', 30.00, '2025-11-24 01:05:05', '2025-11-27', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | Water spinach - fresh daily', '2025-11-24 01:05:05', '2025-11-25 14:34:54'),
(85, 39, 'VEG009-20251124-001', 12.00, 12.00, 'bundle', 25.00, '2025-11-24 01:05:05', '2025-11-27', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | Bok choy - fresh', '2025-11-24 01:05:05', '2025-11-25 14:34:54'),
(86, 40, 'VEG010-20251124-001', 4.00, 4.00, 'kg', 50.00, '2025-11-24 01:05:05', '2025-11-30', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | String beans', '2025-11-24 01:05:05', '2025-11-25 14:34:54'),
(87, 41, 'VEG011-20251124-001', 6.00, 6.00, 'kg', 35.00, '2025-11-24 01:05:05', '2025-12-01', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | For tortang talong', '2025-11-24 01:05:05', '2025-11-25 14:34:54'),
(88, 42, 'VEG012-20251124-001', 4.00, 4.00, 'kg', 55.00, '2025-11-24 01:05:05', '2025-12-01', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | For ginisang ampalaya', '2025-11-24 01:05:05', '2025-11-25 14:34:54'),
(89, 43, 'VEG013-20251124-001', 10.00, 10.00, 'bundle', 25.00, '2025-11-24 01:05:05', '2025-11-27', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | Moringa leaves - nutritious', '2025-11-24 01:05:05', '2025-11-25 14:34:54'),
(90, 44, 'VEG014-20251124-001', 5.00, 5.00, 'kg', 45.00, '2025-11-24 01:05:05', '2025-12-01', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | For tinola', '2025-11-24 01:05:05', '2025-11-25 14:34:54'),
(91, 45, 'VEG015-20251124-001', 8.00, 8.00, 'pc', 40.00, '2025-11-24 01:05:05', '2025-11-29', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | For kare-kare', '2025-11-24 01:05:05', '2025-11-25 14:34:54'),
(92, 46, 'VEG016-20251124-001', 5.00, 5.00, 'kg', 40.00, '2025-11-24 01:05:05', '2025-12-01', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | Long eggplant variety', '2025-11-24 01:05:05', '2025-11-25 14:34:54'),
(93, 47, 'VEG017-20251124-001', 3.00, 3.00, 'kg', 80.00, '2025-11-24 01:05:05', '2025-12-01', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | Mixed colors', '2025-11-24 01:05:05', '2025-11-25 14:34:54'),
(94, 48, 'VEG018-20251124-001', 2.00, 2.00, 'kg', 120.00, '2025-11-24 01:05:05', '2025-12-04', 'Refrigerator-Vegetables', 'Active', 'Market Source: Pasig Public Market | Siling labuyo', '2025-11-24 01:05:05', '2025-11-25 14:34:54'),
(102, 123, 'AMP-20251125-001', 0.00, 23.00, 'pieces', 23.00, '2025-11-25 16:36:37', '2025-12-25', '', 'Discarded', 'Initial batch added on 2025-11-25', '2025-11-25 16:36:37', '2025-11-25 16:37:45'),
(105, 133, 'AHA-20251126-001', 45.00, 45.00, 'kg', 45.00, '2025-11-26 18:07:54', '2025-12-26', '', 'Discarded', 'Initial batch added on 2025-11-26', '2025-11-26 18:07:54', '2025-11-26 18:11:56'),
(113, 42, 'AMP-20251127-002', 0.00, 45.00, '5', 667.00, '2025-11-27 11:03:09', '2025-12-27', 'Freezer-Meat', 'Discarded', '54345', '2025-11-27 11:03:09', '2025-11-27 11:42:15'),
(114, 134, 'AAA-20251127-001', 56.00, 56.00, '67', 67.00, '2025-11-27 11:49:39', '2025-12-27', 'Freezer-Meat', 'Discarded', '676', '2025-11-27 11:49:39', '2025-11-27 12:50:35'),
(115, 134, 'AAA-20251127-002', 0.00, 577.00, '67', 676.00, '2025-11-27 11:58:46', '2025-12-27', 'Freezer-Meat', 'Discarded', '5645', '2025-11-27 11:58:46', '2025-11-27 11:59:38'),
(119, 66, 'ACH-20251127-001', 0.00, 66.00, '77', 656.00, '2025-11-27 12:00:18', '2025-12-27', 'Freezer-Meat', 'Discarded', '56547', '2025-11-27 12:00:18', '2025-11-27 12:00:23'),
(122, 134, 'AAA-20251127-003', 35.00, 35.00, '65', 565.00, '2025-11-27 12:17:03', '2025-12-27', 'Freezer-Meat', 'Discarded', '56565', '2025-11-27 12:17:03', '2025-11-27 12:50:35'),
(123, 137, 'A23-20251127-001', 43.00, 43.00, 'liters', 343.00, '2025-11-27 12:17:38', '2025-12-27', 'Pantry-Dry-Goods', 'Discarded', 'Initial batch added on 11/27/2025', '2025-11-27 12:17:38', '2025-11-27 12:22:26'),
(124, 137, 'A23-20251127-002', 54.00, 54.00, '45', 454.00, '2025-11-27 12:18:00', '2025-12-27', 'Freezer-Meat', 'Discarded', '45454', '2025-11-27 12:18:00', '2025-11-27 12:22:26'),
(127, 137, 'A23-20251127-003', 34.00, 34.00, '56', 565.00, '2025-11-27 12:18:37', '2025-12-27', 'Freezer-Meat', 'Discarded', '56565', '2025-11-27 12:18:37', '2025-11-27 12:22:26'),
(128, 137, 'A23-20251127-004', 34.00, 34.00, '6', 56.00, '2025-11-27 12:19:05', '2025-12-27', 'Freezer-Meat', 'Discarded', '5656', '2025-11-27 12:19:05', '2025-11-27 12:22:26'),
(135, 42, 'AMP-20251127-003', 0.00, 45.00, '56', 56.00, '2025-11-27 12:51:39', '2025-12-27', 'Freezer-Meat', 'Discarded', '56565', '2025-11-27 12:51:39', '2025-11-27 12:51:50'),
(137, 66, 'ACH-20251127-002', 0.00, 56.00, 'liters', 565.00, '2025-11-27 00:00:00', '2025-12-27', 'Freezer-Meat', 'Discarded', '56565', '2025-11-27 12:59:48', '2025-11-27 13:00:32'),
(138, 66, 'ACH-20251127-003', 0.00, 56.00, '677', 6.00, '2025-11-27 12:59:59', '2025-12-27', 'Freezer-Meat', 'Discarded', '676', '2025-11-27 12:59:59', '2025-11-27 13:00:29'),
(139, 66, 'ACH-20251127-004', 0.00, 34.00, 'boxes', 56.00, '2025-11-27 00:00:00', '2025-12-27', 'Freezer-Meat', 'Discarded', '45345', '2025-11-27 13:15:15', '2025-11-27 13:16:33'),
(140, 66, 'ACH-20251127-005', 0.00, 34.00, '56', 563.00, '2025-11-27 13:16:13', '2025-12-27', 'Freezer-Meat', 'Discarded', '34343', '2025-11-27 13:16:13', '2025-11-27 13:16:19');

--
-- Triggers `inventory_batches`
--
DELIMITER $$
CREATE TRIGGER `trg_check_expiration` BEFORE UPDATE ON `inventory_batches` FOR EACH ROW BEGIN
  IF NEW.`ExpirationDate` IS NOT NULL 
     AND NEW.`ExpirationDate` <= CURDATE() 
     AND NEW.`BatchStatus` = 'Active' THEN
    SET NEW.`BatchStatus` = 'Expired';
  END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Stand-in structure for view `inventory_status`
-- (See below for the actual view)
--
CREATE TABLE `inventory_status` (
`InventoryID` int(10)
,`IngredientID` int(10)
,`IngredientName` varchar(100)
,`StockQuantity` decimal(10,2)
,`UnitType` varchar(50)
,`ExpirationDate` date
,`Status` varchar(22)
,`DaysUntilExpiration` int(7)
,`LastRestockedDate` datetime
,`Remarks` varchar(255)
);

-- --------------------------------------------------------

--
-- Table structure for table `inventory_transactions`
--

CREATE TABLE `inventory_transactions` (
  `TransactionID` int(10) NOT NULL COMMENT 'Unique transaction record ID',
  `InventoryID` int(10) NOT NULL COMMENT 'Reference to inventory record',
  `TransactionType` enum('Restock','Usage','Adjustment') NOT NULL COMMENT 'Type of transaction',
  `QuantityChanged` decimal(10,2) NOT NULL COMMENT 'Amount of stock changed (positive for restock, negative for usage)',
  `StockBefore` decimal(10,2) NOT NULL COMMENT 'Stock quantity before transaction',
  `StockAfter` decimal(10,2) NOT NULL COMMENT 'Stock quantity after transaction',
  `ReferenceID` varchar(50) DEFAULT NULL COMMENT 'Reference to related order ID if from order usage',
  `Notes` text DEFAULT NULL COMMENT 'Notes about the transaction',
  `TransactionDate` datetime DEFAULT current_timestamp() COMMENT 'Date and time of transaction'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `inventory_transactions`
--

INSERT INTO `inventory_transactions` (`TransactionID`, `InventoryID`, `TransactionType`, `QuantityChanged`, `StockBefore`, `StockAfter`, `ReferenceID`, `Notes`, `TransactionDate`) VALUES
(1, 1, 'Restock', 25.00, 0.00, 25.00, NULL, 'Market purchase - Fresh delivery twice weekly', '2025-11-20 08:00:00'),
(2, 2, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - Main grilling meat', '2025-11-20 08:00:00'),
(3, 3, 'Restock', 30.00, 0.00, 30.00, NULL, 'Market purchase - For inasal and fried chicken', '2025-11-20 08:00:00'),
(4, 4, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - Buffalo wings stock', '2025-11-20 08:00:00'),
(5, 5, 'Restock', 18.00, 0.00, 18.00, NULL, 'Market purchase - For sisig and salads', '2025-11-20 08:00:00'),
(6, 6, 'Restock', 12.00, 0.00, 12.00, NULL, 'Market purchase - Pre-chopped pig face and ears', '2025-11-20 08:00:00'),
(7, 7, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Fresh catch', '2025-11-21 06:00:00'),
(8, 8, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Farm raised', '2025-11-21 06:00:00'),
(9, 9, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Medium size', '2025-11-21 06:00:00'),
(10, 10, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - Cleaned', '2025-11-21 06:00:00'),
(11, 11, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - For longganisa and lumpia', '2025-11-20 08:00:00'),
(12, 12, 'Restock', 12.00, 0.00, 12.00, NULL, 'Market purchase - For bulalo and kare-kare', '2025-11-20 08:00:00'),
(13, 13, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - For crispy pata', '2025-11-20 08:00:00'),
(14, 14, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Baby back ribs', '2025-11-20 08:00:00'),
(15, 15, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Pre-marinated', '2025-11-19 08:00:00'),
(16, 16, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Pre-marinated beef', '2025-11-19 08:00:00'),
(17, 17, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - House recipe', '2025-11-19 08:00:00'),
(18, 18, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - Jumbo size', '2025-11-18 08:00:00'),
(19, 19, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Smoked', '2025-11-18 08:00:00'),
(20, 20, 'Restock', 24.00, 0.00, 24.00, NULL, 'Market purchase - Canned goods', '2025-11-15 08:00:00'),
(21, 21, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - Canned meat', '2025-11-15 08:00:00'),
(22, 22, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - 30 pcs per tray', '2025-11-20 08:00:00'),
(23, 23, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Salted dried herring', '2025-11-18 08:00:00'),
(24, 24, 'Restock', 2.50, 0.00, 2.50, NULL, 'Market purchase - Dried rabbitfish', '2025-11-18 08:00:00'),
(25, 25, 'Restock', 100.00, 0.00, 100.00, NULL, 'Market purchase - Sinandomeng variety', '2025-11-19 08:00:00'),
(26, 26, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Pre-mixed seasoning', '2025-11-19 08:00:00'),
(27, 27, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Dried egg noodles', '2025-11-15 08:00:00'),
(28, 28, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Rice vermicelli', '2025-11-15 08:00:00'),
(29, 29, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Glass noodles', '2025-11-15 08:00:00'),
(30, 30, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - Italian pasta', '2025-11-15 08:00:00'),
(31, 31, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - Red onion preferred', '2025-11-20 08:00:00'),
(32, 32, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Native garlic', '2025-11-20 08:00:00'),
(33, 33, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Fresh ripe', '2025-11-21 06:00:00'),
(34, 34, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For soups and marinades', '2025-11-20 08:00:00'),
(35, 35, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - For pancit and lumpia', '2025-11-21 06:00:00'),
(36, 36, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - For pancit and menudo', '2025-11-21 06:00:00'),
(37, 37, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For tinola', '2025-11-21 06:00:00'),
(38, 38, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - Water spinach', '2025-11-21 06:00:00'),
(39, 39, 'Restock', 12.00, 0.00, 12.00, NULL, 'Market purchase - Bok choy', '2025-11-21 06:00:00'),
(40, 40, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - String beans', '2025-11-21 06:00:00'),
(41, 41, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - For tortang talong', '2025-11-21 06:00:00'),
(42, 42, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - For ginisang ampalaya', '2025-11-21 06:00:00'),
(43, 43, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Moringa leaves', '2025-11-21 06:00:00'),
(44, 44, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For tinola', '2025-11-21 06:00:00'),
(45, 45, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - For kare-kare', '2025-11-21 06:00:00'),
(46, 46, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Long variety', '2025-11-21 06:00:00'),
(47, 47, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Mixed colors', '2025-11-21 06:00:00'),
(48, 48, 'Restock', 2.00, 0.00, 2.00, NULL, 'Market purchase - Siling labuyo', '2025-11-20 08:00:00'),
(49, 49, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Philippine lime', '2025-11-21 06:00:00'),
(50, 50, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - For drinks', '2025-11-21 06:00:00'),
(51, 51, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - Iceberg variety', '2025-11-21 06:00:00'),
(52, 52, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - For salads', '2025-11-21 06:00:00'),
(53, 53, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - For fries and menudo', '2025-11-20 08:00:00'),
(54, 54, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Sweet corn', '2025-11-21 06:00:00'),
(55, 55, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Silver Swan brand', '2025-11-15 08:00:00'),
(56, 56, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Cane vinegar', '2025-11-15 08:00:00'),
(57, 57, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Rufina brand', '2025-11-15 08:00:00'),
(58, 58, 'Restock', 12.00, 0.00, 12.00, NULL, 'Market purchase - Lee Kum Kee', '2025-11-15 08:00:00'),
(59, 59, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - Jufran brand', '2025-11-15 08:00:00'),
(60, 60, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - Del Monte', '2025-11-15 08:00:00'),
(61, 61, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Best Foods', '2025-11-15 08:00:00'),
(62, 62, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - For sisig', '2025-11-15 08:00:00'),
(63, 63, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - Sauteed', '2025-11-15 08:00:00'),
(64, 64, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - For kare-kare', '2025-11-15 08:00:00'),
(65, 65, 'Restock', 12.00, 0.00, 12.00, NULL, 'Market purchase - For Filipino spaghetti', '2025-11-15 08:00:00'),
(66, 66, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For inasal color', '2025-11-15 08:00:00'),
(67, 67, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - Lea & Perrins', '2025-11-15 08:00:00'),
(68, 68, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - Tabasco', '2025-11-15 08:00:00'),
(69, 69, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - For grilled items', '2025-11-15 08:00:00'),
(70, 70, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - Brown gravy', '2025-11-15 08:00:00'),
(71, 71, 'Restock', 24.00, 0.00, 24.00, NULL, 'Market purchase - For desserts', '2025-11-15 08:00:00'),
(72, 72, 'Restock', 24.00, 0.00, 24.00, NULL, 'Market purchase - For halo-halo', '2025-11-15 08:00:00'),
(73, 73, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - For laing and ginataang', '2025-11-18 08:00:00'),
(74, 74, 'Restock', 12.00, 0.00, 12.00, NULL, 'Market purchase - Thick coconut milk', '2025-11-15 08:00:00'),
(75, 75, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Salted', '2025-11-18 08:00:00'),
(76, 76, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - Quick melt', '2025-11-18 08:00:00'),
(77, 77, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - For shakes', '2025-11-21 06:00:00'),
(78, 78, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Ground coffee', '2025-11-15 08:00:00'),
(79, 79, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Assorted flavors', '2025-11-15 08:00:00'),
(80, 80, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Lemon flavor', '2025-11-15 08:00:00'),
(81, 81, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Powdered', '2025-11-15 08:00:00'),
(82, 82, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - For drinks', '2025-11-15 08:00:00'),
(83, 83, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Assorted 1.5L', '2025-11-18 08:00:00'),
(84, 84, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - 500ml bottles', '2025-11-18 08:00:00'),
(85, 85, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Fresh coconut water', '2025-11-21 06:00:00'),
(86, 86, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - Vegetable oil', '2025-11-15 08:00:00'),
(87, 87, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Iodized', '2025-11-15 08:00:00'),
(88, 88, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - White refined', '2025-11-15 08:00:00'),
(89, 89, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Muscovado', '2025-11-15 08:00:00'),
(90, 90, 'Restock', 2.00, 0.00, 2.00, NULL, 'Market purchase - Ground black pepper', '2025-11-15 08:00:00'),
(91, 91, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Ajinomoto', '2025-11-15 08:00:00'),
(92, 92, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - All-purpose', '2025-11-15 08:00:00'),
(93, 93, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For breading', '2025-11-15 08:00:00'),
(94, 94, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - Japanese panko', '2025-11-15 08:00:00'),
(95, 95, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - 25 sheets per pack', '2025-11-18 08:00:00'),
(96, 96, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - Small size', '2025-11-18 08:00:00'),
(97, 97, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Instant mix', '2025-11-15 08:00:00'),
(98, 98, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - For halo-halo', '2025-11-15 08:00:00'),
(99, 99, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Tapioca pearls', '2025-11-15 08:00:00'),
(100, 100, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - For halo-halo', '2025-11-15 08:00:00'),
(101, 101, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Coconut gel', '2025-11-15 08:00:00'),
(102, 102, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - Purple yam jam', '2025-11-18 08:00:00'),
(103, 103, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Sweetened', '2025-11-18 08:00:00'),
(104, 104, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - Coconut sport', '2025-11-15 08:00:00'),
(105, 105, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Assorted flavors', '2025-11-18 08:00:00'),
(106, 106, 'Restock', 50.00, 0.00, 50.00, NULL, 'Market purchase - Made fresh daily', '2025-11-21 06:00:00'),
(107, 107, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Saba variety', '2025-11-21 06:00:00'),
(108, 108, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Lumpia wrapper for turon', '2025-11-18 08:00:00'),
(109, 109, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Homemade stock', '2025-11-18 08:00:00'),
(110, 110, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - For sinigang', '2025-11-18 08:00:00'),
(111, 111, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For bulalo', '2025-11-18 08:00:00'),
(112, 112, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - Instant sinigang mix', '2025-11-15 08:00:00'),
(113, 113, 'Restock', 2.00, 0.00, 2.00, NULL, 'Market purchase - For miso soup', '2025-11-15 08:00:00'),
(114, 114, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - For inasal marinade', '2025-11-21 06:00:00'),
(115, 115, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Dried', '2025-11-15 08:00:00'),
(116, 116, 'Restock', 1.00, 0.00, 1.00, NULL, 'Market purchase - Smoked', '2025-11-15 08:00:00'),
(117, 117, 'Restock', 0.50, 0.00, 0.50, NULL, 'Market purchase - Ground', '2025-11-15 08:00:00'),
(118, 118, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Dried', '2025-11-15 08:00:00'),
(119, 119, 'Restock', 1.00, 0.00, 1.00, NULL, 'Market purchase - For atsuete oil', '2025-11-15 08:00:00'),
(120, 120, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For rice and desserts', '2025-11-21 06:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `inventory_transactions_backup`
--

CREATE TABLE `inventory_transactions_backup` (
  `TransactionID` int(10) NOT NULL DEFAULT 0 COMMENT 'Unique transaction record ID',
  `InventoryID` int(10) NOT NULL COMMENT 'Reference to inventory record',
  `TransactionType` enum('Restock','Usage','Adjustment') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Type of transaction',
  `QuantityChanged` decimal(10,2) NOT NULL COMMENT 'Amount of stock changed (positive for restock, negative for usage)',
  `StockBefore` decimal(10,2) NOT NULL COMMENT 'Stock quantity before transaction',
  `StockAfter` decimal(10,2) NOT NULL COMMENT 'Stock quantity after transaction',
  `ReferenceID` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Reference to related order ID if from order usage',
  `Notes` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Notes about the transaction',
  `TransactionDate` datetime DEFAULT current_timestamp() COMMENT 'Date and time of transaction'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `inventory_transactions_backup`
--

INSERT INTO `inventory_transactions_backup` (`TransactionID`, `InventoryID`, `TransactionType`, `QuantityChanged`, `StockBefore`, `StockAfter`, `ReferenceID`, `Notes`, `TransactionDate`) VALUES
(1, 1, 'Restock', 25.00, 0.00, 25.00, NULL, 'Market purchase - Fresh delivery twice weekly', '2025-11-20 08:00:00'),
(2, 2, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - Main grilling meat', '2025-11-20 08:00:00'),
(3, 3, 'Restock', 30.00, 0.00, 30.00, NULL, 'Market purchase - For inasal and fried chicken', '2025-11-20 08:00:00'),
(4, 4, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - Buffalo wings stock', '2025-11-20 08:00:00'),
(5, 5, 'Restock', 18.00, 0.00, 18.00, NULL, 'Market purchase - For sisig and salads', '2025-11-20 08:00:00'),
(6, 6, 'Restock', 12.00, 0.00, 12.00, NULL, 'Market purchase - Pre-chopped pig face and ears', '2025-11-20 08:00:00'),
(7, 7, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Fresh catch', '2025-11-21 06:00:00'),
(8, 8, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Farm raised', '2025-11-21 06:00:00'),
(9, 9, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Medium size', '2025-11-21 06:00:00'),
(10, 10, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - Cleaned', '2025-11-21 06:00:00'),
(11, 11, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - For longganisa and lumpia', '2025-11-20 08:00:00'),
(12, 12, 'Restock', 12.00, 0.00, 12.00, NULL, 'Market purchase - For bulalo and kare-kare', '2025-11-20 08:00:00'),
(13, 13, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - For crispy pata', '2025-11-20 08:00:00'),
(14, 14, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Baby back ribs', '2025-11-20 08:00:00'),
(15, 15, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Pre-marinated', '2025-11-19 08:00:00'),
(16, 16, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Pre-marinated beef', '2025-11-19 08:00:00'),
(17, 17, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - House recipe', '2025-11-19 08:00:00'),
(18, 18, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - Jumbo size', '2025-11-18 08:00:00'),
(19, 19, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Smoked', '2025-11-18 08:00:00'),
(20, 20, 'Restock', 24.00, 0.00, 24.00, NULL, 'Market purchase - Canned goods', '2025-11-15 08:00:00'),
(21, 21, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - Canned meat', '2025-11-15 08:00:00'),
(22, 22, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - 30 pcs per tray', '2025-11-20 08:00:00'),
(23, 23, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Salted dried herring', '2025-11-18 08:00:00'),
(24, 24, 'Restock', 2.50, 0.00, 2.50, NULL, 'Market purchase - Dried rabbitfish', '2025-11-18 08:00:00'),
(25, 25, 'Restock', 100.00, 0.00, 100.00, NULL, 'Market purchase - Sinandomeng variety', '2025-11-19 08:00:00'),
(26, 26, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Pre-mixed seasoning', '2025-11-19 08:00:00'),
(27, 27, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Dried egg noodles', '2025-11-15 08:00:00'),
(28, 28, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Rice vermicelli', '2025-11-15 08:00:00'),
(29, 29, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Glass noodles', '2025-11-15 08:00:00'),
(30, 30, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - Italian pasta', '2025-11-15 08:00:00'),
(31, 31, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - Red onion preferred', '2025-11-20 08:00:00'),
(32, 32, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Native garlic', '2025-11-20 08:00:00'),
(33, 33, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Fresh ripe', '2025-11-21 06:00:00'),
(34, 34, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For soups and marinades', '2025-11-20 08:00:00'),
(35, 35, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - For pancit and lumpia', '2025-11-21 06:00:00'),
(36, 36, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - For pancit and menudo', '2025-11-21 06:00:00'),
(37, 37, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For tinola', '2025-11-21 06:00:00'),
(38, 38, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - Water spinach', '2025-11-21 06:00:00'),
(39, 39, 'Restock', 12.00, 0.00, 12.00, NULL, 'Market purchase - Bok choy', '2025-11-21 06:00:00'),
(40, 40, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - String beans', '2025-11-21 06:00:00'),
(41, 41, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - For tortang talong', '2025-11-21 06:00:00'),
(42, 42, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - For ginisang ampalaya', '2025-11-21 06:00:00'),
(43, 43, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Moringa leaves', '2025-11-21 06:00:00'),
(44, 44, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For tinola', '2025-11-21 06:00:00'),
(45, 45, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - For kare-kare', '2025-11-21 06:00:00'),
(46, 46, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Long variety', '2025-11-21 06:00:00'),
(47, 47, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Mixed colors', '2025-11-21 06:00:00'),
(48, 48, 'Restock', 2.00, 0.00, 2.00, NULL, 'Market purchase - Siling labuyo', '2025-11-20 08:00:00'),
(49, 49, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Philippine lime', '2025-11-21 06:00:00'),
(50, 50, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - For drinks', '2025-11-21 06:00:00'),
(51, 51, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - Iceberg variety', '2025-11-21 06:00:00'),
(52, 52, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - For salads', '2025-11-21 06:00:00'),
(53, 53, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - For fries and menudo', '2025-11-20 08:00:00'),
(54, 54, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Sweet corn', '2025-11-21 06:00:00'),
(55, 55, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Silver Swan brand', '2025-11-15 08:00:00'),
(56, 56, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Cane vinegar', '2025-11-15 08:00:00'),
(57, 57, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Rufina brand', '2025-11-15 08:00:00'),
(58, 58, 'Restock', 12.00, 0.00, 12.00, NULL, 'Market purchase - Lee Kum Kee', '2025-11-15 08:00:00'),
(59, 59, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - Jufran brand', '2025-11-15 08:00:00'),
(60, 60, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - Del Monte', '2025-11-15 08:00:00'),
(61, 61, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Best Foods', '2025-11-15 08:00:00'),
(62, 62, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - For sisig', '2025-11-15 08:00:00'),
(63, 63, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - Sauteed', '2025-11-15 08:00:00'),
(64, 64, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - For kare-kare', '2025-11-15 08:00:00'),
(65, 65, 'Restock', 12.00, 0.00, 12.00, NULL, 'Market purchase - For Filipino spaghetti', '2025-11-15 08:00:00'),
(66, 66, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For inasal color', '2025-11-15 08:00:00'),
(67, 67, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - Lea & Perrins', '2025-11-15 08:00:00'),
(68, 68, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - Tabasco', '2025-11-15 08:00:00'),
(69, 69, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - For grilled items', '2025-11-15 08:00:00'),
(70, 70, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - Brown gravy', '2025-11-15 08:00:00'),
(71, 71, 'Restock', 24.00, 0.00, 24.00, NULL, 'Market purchase - For desserts', '2025-11-15 08:00:00'),
(72, 72, 'Restock', 24.00, 0.00, 24.00, NULL, 'Market purchase - For halo-halo', '2025-11-15 08:00:00'),
(73, 73, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - For laing and ginataang', '2025-11-18 08:00:00'),
(74, 74, 'Restock', 12.00, 0.00, 12.00, NULL, 'Market purchase - Thick coconut milk', '2025-11-15 08:00:00'),
(75, 75, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Salted', '2025-11-18 08:00:00'),
(76, 76, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - Quick melt', '2025-11-18 08:00:00'),
(77, 77, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - For shakes', '2025-11-21 06:00:00'),
(78, 78, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Ground coffee', '2025-11-15 08:00:00'),
(79, 79, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Assorted flavors', '2025-11-15 08:00:00'),
(80, 80, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Lemon flavor', '2025-11-15 08:00:00'),
(81, 81, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Powdered', '2025-11-15 08:00:00'),
(82, 82, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - For drinks', '2025-11-15 08:00:00'),
(83, 83, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Assorted 1.5L', '2025-11-18 08:00:00'),
(84, 84, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - 500ml bottles', '2025-11-18 08:00:00'),
(85, 85, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Fresh coconut water', '2025-11-21 06:00:00'),
(86, 86, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - Vegetable oil', '2025-11-15 08:00:00'),
(87, 87, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Iodized', '2025-11-15 08:00:00'),
(88, 88, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - White refined', '2025-11-15 08:00:00'),
(89, 89, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Muscovado', '2025-11-15 08:00:00'),
(90, 90, 'Restock', 2.00, 0.00, 2.00, NULL, 'Market purchase - Ground black pepper', '2025-11-15 08:00:00'),
(91, 91, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Ajinomoto', '2025-11-15 08:00:00'),
(92, 92, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - All-purpose', '2025-11-15 08:00:00'),
(93, 93, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For breading', '2025-11-15 08:00:00'),
(94, 94, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - Japanese panko', '2025-11-15 08:00:00'),
(95, 95, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - 25 sheets per pack', '2025-11-18 08:00:00'),
(96, 96, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - Small size', '2025-11-18 08:00:00'),
(97, 97, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Instant mix', '2025-11-15 08:00:00'),
(98, 98, 'Restock', 15.00, 0.00, 15.00, NULL, 'Market purchase - For halo-halo', '2025-11-15 08:00:00'),
(99, 99, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Tapioca pearls', '2025-11-15 08:00:00'),
(100, 100, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - For halo-halo', '2025-11-15 08:00:00'),
(101, 101, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Coconut gel', '2025-11-15 08:00:00'),
(102, 102, 'Restock', 4.00, 0.00, 4.00, NULL, 'Market purchase - Purple yam jam', '2025-11-18 08:00:00'),
(103, 103, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Sweetened', '2025-11-18 08:00:00'),
(104, 104, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - Coconut sport', '2025-11-15 08:00:00'),
(105, 105, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Assorted flavors', '2025-11-18 08:00:00'),
(106, 106, 'Restock', 50.00, 0.00, 50.00, NULL, 'Market purchase - Made fresh daily', '2025-11-21 06:00:00'),
(107, 107, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Saba variety', '2025-11-21 06:00:00'),
(108, 108, 'Restock', 10.00, 0.00, 10.00, NULL, 'Market purchase - Lumpia wrapper for turon', '2025-11-18 08:00:00'),
(109, 109, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - Homemade stock', '2025-11-18 08:00:00'),
(110, 110, 'Restock', 6.00, 0.00, 6.00, NULL, 'Market purchase - For sinigang', '2025-11-18 08:00:00'),
(111, 111, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For bulalo', '2025-11-18 08:00:00'),
(112, 112, 'Restock', 20.00, 0.00, 20.00, NULL, 'Market purchase - Instant sinigang mix', '2025-11-15 08:00:00'),
(113, 113, 'Restock', 2.00, 0.00, 2.00, NULL, 'Market purchase - For miso soup', '2025-11-15 08:00:00'),
(114, 114, 'Restock', 8.00, 0.00, 8.00, NULL, 'Market purchase - For inasal marinade', '2025-11-21 06:00:00'),
(115, 115, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - Dried', '2025-11-15 08:00:00'),
(116, 116, 'Restock', 1.00, 0.00, 1.00, NULL, 'Market purchase - Smoked', '2025-11-15 08:00:00'),
(117, 117, 'Restock', 0.50, 0.00, 0.50, NULL, 'Market purchase - Ground', '2025-11-15 08:00:00'),
(118, 118, 'Restock', 3.00, 0.00, 3.00, NULL, 'Market purchase - Dried', '2025-11-15 08:00:00'),
(119, 119, 'Restock', 1.00, 0.00, 1.00, NULL, 'Market purchase - For atsuete oil', '2025-11-15 08:00:00'),
(120, 120, 'Restock', 5.00, 0.00, 5.00, NULL, 'Market purchase - For rice and desserts', '2025-11-21 06:00:00');

-- --------------------------------------------------------

--
-- Stand-in structure for view `inventory_transaction_history`
-- (See below for the actual view)
--
CREATE TABLE `inventory_transaction_history` (
`TransactionID` int(10)
,`InventoryID` int(10)
,`IngredientName` varchar(100)
,`TransactionType` enum('Restock','Usage','Adjustment')
,`QuantityChanged` decimal(10,2)
,`StockBefore` decimal(10,2)
,`StockAfter` decimal(10,2)
,`UnitType` varchar(50)
,`Notes` text
,`TransactionDate` datetime
);

-- --------------------------------------------------------

--
-- Table structure for table `logs`
--

CREATE TABLE `logs` (
  `id` int(11) NOT NULL,
  `dt` datetime NOT NULL,
  `user_accounts_id` int(11) NOT NULL,
  `event` varchar(100) DEFAULT NULL,
  `transactions` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `logs`
--

INSERT INTO `logs` (`id`, `dt`, `user_accounts_id`, `event`, `transactions`) VALUES
(1, '2025-11-21 12:26:21', 4, 'Login', 'Admin logged in'),
(2, '2025-11-22 20:09:20', 4, 'Login', 'Admin logged in'),
(3, '2025-11-22 20:44:42', 4, 'Login', 'Admin logged in'),
(4, '2025-11-22 20:49:37', 4, 'Login', 'Admin logged in'),
(5, '2025-11-22 20:57:52', 4, 'Login', 'Admin logged in'),
(6, '2025-11-23 01:23:18', 4, 'Login', 'Admin logged in'),
(7, '2025-11-23 01:27:06', 4, 'Login', 'Admin logged in'),
(8, '2025-11-23 02:18:22', 4, 'Login', 'Admin logged in'),
(9, '2025-11-23 02:22:21', 4, 'Login', 'Admin logged in'),
(10, '2025-11-23 02:24:25', 4, 'Login', 'Admin logged in'),
(11, '2025-11-23 02:42:48', 4, 'Login', 'Admin logged in'),
(12, '2025-11-23 03:02:21', 4, 'Login', 'Admin logged in'),
(13, '2025-11-23 09:41:54', 4, 'Login', 'Admin logged in'),
(14, '2025-11-23 09:55:48', 4, 'Login', 'Admin logged in'),
(15, '2025-11-23 10:03:34', 4, 'Login', 'Admin logged in'),
(16, '2025-11-23 10:15:37', 4, 'Login', 'Admin logged in'),
(17, '2025-11-23 10:24:31', 4, 'Login', 'Admin logged in'),
(18, '2025-11-23 10:37:24', 4, 'Login', 'Admin logged in'),
(19, '2025-11-23 10:38:52', 4, 'Login', 'Admin logged in'),
(20, '2025-11-23 10:41:57', 4, 'Login', 'Admin logged in'),
(21, '2025-11-23 10:54:28', 4, 'Login', 'Admin logged in'),
(22, '2025-11-23 10:59:17', 4, 'Login', 'Admin logged in'),
(23, '2025-11-23 11:03:30', 4, 'Login', 'Admin logged in'),
(24, '2025-11-23 11:13:20', 4, 'Login', 'Admin logged in'),
(25, '2025-11-23 11:25:09', 4, 'Login', 'Admin logged in'),
(26, '2025-11-23 11:31:49', 4, 'Login', 'Admin logged in'),
(27, '2025-11-23 11:34:33', 4, 'Login', 'Admin logged in'),
(28, '2025-11-23 12:13:29', 4, 'Login', 'Admin logged in'),
(29, '2025-11-23 13:43:50', 4, 'Login', 'Admin logged in'),
(30, '2025-11-23 14:14:36', 4, 'Login', 'Admin logged in'),
(31, '2025-11-23 14:20:46', 4, 'Login', 'Admin logged in'),
(32, '2025-11-23 14:25:43', 4, 'Login', 'Admin logged in'),
(33, '2025-11-23 14:28:46', 4, 'Login', 'Admin logged in'),
(34, '2025-11-23 15:59:36', 4, 'Login', 'Admin logged in'),
(35, '2025-11-23 16:21:27', 4, 'Login', 'Admin logged in'),
(36, '2025-11-23 16:24:12', 4, 'Login', 'Admin logged in'),
(37, '2025-11-23 16:36:15', 4, 'Login', 'Admin logged in'),
(38, '2025-11-23 16:42:35', 4, 'Login', 'Admin logged in'),
(39, '2025-11-23 17:16:56', 4, 'Login', 'Admin logged in'),
(40, '2025-11-23 18:28:47', 4, 'Login', 'Admin logged in'),
(41, '2025-11-23 23:27:36', 4, 'Login', 'Admin logged in'),
(42, '2025-11-24 00:00:59', 4, 'Login', 'Admin logged in'),
(43, '2025-11-24 00:36:56', 4, 'Login', 'Admin logged in'),
(44, '2025-11-24 00:52:13', 4, 'Login', 'Admin logged in'),
(45, '2025-11-24 01:12:10', 4, 'Login', 'Admin logged in'),
(46, '2025-11-25 15:09:54', 4, 'Login', 'Admin logged in'),
(47, '2025-11-25 15:21:08', 4, 'Login', 'Admin logged in'),
(48, '2025-11-25 16:08:18', 4, 'Login', 'Admin logged in'),
(49, '2025-11-25 16:13:12', 4, 'Login', 'Admin logged in'),
(50, '2025-11-25 16:21:39', 4, 'Login', 'Admin logged in'),
(51, '2025-11-25 16:35:31', 4, 'Login', 'Admin logged in'),
(52, '2025-11-25 17:40:46', 4, 'Login', 'Admin logged in'),
(53, '2025-11-25 17:48:00', 4, 'Login', 'Admin logged in'),
(54, '2025-11-25 18:47:54', 4, 'Login', 'Admin logged in'),
(55, '2025-11-25 19:19:45', 4, 'Login', 'Admin logged in'),
(56, '2025-11-25 22:10:50', 4, 'Login', 'Admin logged in'),
(57, '2025-11-25 22:46:56', 4, 'Login', 'Admin logged in'),
(58, '2025-11-25 22:49:21', 4, 'Login', 'Admin logged in'),
(59, '2025-11-25 22:54:28', 4, 'Login', 'Admin logged in'),
(60, '2025-11-25 23:03:57', 4, 'Login', 'Admin logged in'),
(61, '2025-11-26 00:36:12', 4, 'Login', 'Admin logged in'),
(62, '2025-11-26 00:43:55', 4, 'Login', 'Admin logged in'),
(63, '2025-11-26 00:45:57', 4, 'Login', 'Admin logged in'),
(64, '2025-11-26 01:13:05', 4, 'Login', 'Admin logged in'),
(65, '2025-11-26 01:19:31', 4, 'Login', 'Admin logged in'),
(66, '2025-11-26 01:28:28', 4, 'Login', 'Admin logged in'),
(67, '2025-11-26 02:08:52', 4, 'Login', 'Admin logged in'),
(68, '2025-11-26 02:21:52', 4, 'Login', 'Admin logged in'),
(69, '2025-11-26 02:37:25', 4, 'Login', 'Admin logged in'),
(70, '2025-11-26 02:38:50', 4, 'Login', 'Admin logged in'),
(71, '2025-11-26 16:49:25', 4, 'Login', 'Admin logged in'),
(72, '2025-11-26 17:01:18', 4, 'Login', 'Admin logged in'),
(73, '2025-11-26 17:07:01', 4, 'Login', 'Admin logged in'),
(74, '2025-11-26 17:16:45', 4, 'Login', 'Admin logged in'),
(75, '2025-11-26 17:39:06', 4, 'Login', 'Admin logged in'),
(76, '2025-11-26 17:41:35', 4, 'Login', 'Admin logged in'),
(77, '2025-11-26 17:43:01', 4, 'Login', 'Admin logged in'),
(78, '2025-11-26 17:59:35', 4, 'Login', 'Admin logged in'),
(79, '2025-11-26 18:07:32', 4, 'Login', 'Admin logged in'),
(80, '2025-11-26 18:36:05', 4, 'Login', 'Admin logged in'),
(81, '2025-11-26 18:56:33', 4, 'Login', 'Admin logged in'),
(82, '2025-11-26 19:10:29', 4, 'Login', 'Admin logged in'),
(83, '2025-11-26 19:39:41', 4, 'Login', 'Admin logged in'),
(84, '2025-11-26 19:46:00', 4, 'Login', 'Admin logged in'),
(85, '2025-11-26 19:50:43', 4, 'Login', 'Admin logged in'),
(86, '2025-11-26 20:12:01', 4, 'Login', 'Admin logged in'),
(87, '2025-11-26 22:52:17', 4, 'Login', 'Admin logged in'),
(88, '2025-11-26 22:54:51', 4, 'Login', 'Admin logged in'),
(89, '2025-11-26 23:43:08', 4, 'Login', 'Admin logged in'),
(90, '2025-11-27 00:08:15', 4, 'Login', 'Admin logged in'),
(91, '2025-11-27 00:22:31', 4, 'Login', 'Admin logged in'),
(92, '2025-11-27 00:26:46', 4, 'Login', 'Admin logged in'),
(93, '2025-11-27 00:30:12', 4, 'Login', 'Admin logged in'),
(94, '2025-11-27 11:02:52', 4, 'Login', 'Admin logged in'),
(95, '2025-11-27 11:16:37', 4, 'Login', 'Admin logged in'),
(96, '2025-11-27 11:38:21', 4, 'Login', 'Admin logged in'),
(97, '2025-11-27 11:49:27', 4, 'Login', 'Admin logged in'),
(98, '2025-11-27 11:58:31', 4, 'Login', 'Admin logged in'),
(99, '2025-11-27 12:00:48', 4, 'Login', 'Admin logged in'),
(100, '2025-11-27 12:15:42', 4, 'Login', 'Admin logged in'),
(101, '2025-11-27 12:22:12', 4, 'Login', 'Admin logged in'),
(102, '2025-11-27 12:50:28', 4, 'Login', 'Admin logged in'),
(103, '2025-11-27 12:59:02', 4, 'Login', 'Admin logged in'),
(104, '2025-11-27 13:14:56', 4, 'Login', 'Admin logged in'),
(105, '2025-11-27 13:16:01', 4, 'Login', 'Admin logged in');

-- --------------------------------------------------------

--
-- Stand-in structure for view `low_stock_items`
-- (See below for the actual view)
--
CREATE TABLE `low_stock_items` (
`InventoryID` int(10)
,`IngredientName` varchar(100)
,`StockQuantity` decimal(10,2)
,`UnitType` varchar(50)
,`LastRestockedDate` datetime
,`DaysSinceLastRestock` int(7)
,`Remarks` varchar(255)
);

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `OrderID` int(10) NOT NULL,
  `CustomerID` int(10) DEFAULT NULL,
  `EmployeeID` int(10) DEFAULT NULL,
  `OrderType` enum('Dine-in','Takeout','Online') NOT NULL,
  `OrderSource` enum('POS','Website') NOT NULL,
  `ReceiptNumber` varchar(20) DEFAULT NULL,
  `NumberOfDiners` int(3) DEFAULT NULL,
  `OrderDate` date NOT NULL,
  `OrderTime` time NOT NULL,
  `ItemsOrderedCount` int(4) NOT NULL,
  `TotalAmount` decimal(10,2) NOT NULL,
  `OrderStatus` enum('Preparing','Served','Completed','Cancelled') DEFAULT 'Preparing',
  `Remarks` text DEFAULT NULL,
  `OrderPriority` enum('Normal','Rush') DEFAULT 'Normal',
  `PreparationTimeEstimate` int(4) DEFAULT NULL,
  `SpecialRequestFlag` tinyint(1) DEFAULT 0,
  `CreatedDate` datetime DEFAULT current_timestamp(),
  `UpdatedDate` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`OrderID`, `CustomerID`, `EmployeeID`, `OrderType`, `OrderSource`, `ReceiptNumber`, `NumberOfDiners`, `OrderDate`, `OrderTime`, `ItemsOrderedCount`, `TotalAmount`, `OrderStatus`, `Remarks`, `OrderPriority`, `PreparationTimeEstimate`, `SpecialRequestFlag`, `CreatedDate`, `UpdatedDate`) VALUES
(1000, 8, NULL, 'Online', 'Website', NULL, NULL, '2025-11-23', '12:46:03', 2, 345.00, 'Preparing', NULL, 'Normal', NULL, 0, '2025-11-23 12:46:03', '2025-11-23 12:46:03');

-- --------------------------------------------------------

--
-- Table structure for table `order_ingredient_usage`
--

CREATE TABLE `order_ingredient_usage` (
  `UsageID` int(10) NOT NULL,
  `OrderID` int(10) NOT NULL,
  `OrderItemID` int(10) DEFAULT NULL,
  `BatchID` int(10) NOT NULL,
  `IngredientID` int(10) NOT NULL,
  `QuantityUsed` decimal(10,2) NOT NULL,
  `UnitType` varchar(50) NOT NULL,
  `UsageDate` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `OrderItemID` int(10) NOT NULL,
  `OrderID` int(10) NOT NULL,
  `ProductName` varchar(100) NOT NULL,
  `Quantity` int(4) NOT NULL,
  `UnitPrice` decimal(10,2) NOT NULL,
  `SpecialInstructions` text DEFAULT NULL,
  `ItemStatus` enum('Pending','Preparing','Ready','Served') DEFAULT 'Pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`OrderItemID`, `OrderID`, `ProductName`, `Quantity`, `UnitPrice`, `SpecialInstructions`, `ItemStatus`) VALUES
(1, 1000, 'S-C (w/ Shanghai, Ham & Cheese Sandwich)', 1, 180.00, NULL, 'Pending'),
(2, 1000, 'S-B (w/ Shanghai & Empanada)', 1, 165.00, NULL, 'Pending');

-- --------------------------------------------------------

--
-- Table structure for table `payments`
--

CREATE TABLE `payments` (
  `PaymentID` int(10) NOT NULL,
  `OrderID` int(10) NOT NULL,
  `PaymentDate` datetime DEFAULT current_timestamp(),
  `PaymentMethod` enum('Cash','GCash','COD') DEFAULT 'Cash',
  `PaymentStatus` enum('Pending','Completed','Refunded','Failed') DEFAULT 'Pending',
  `AmountPaid` decimal(10,2) NOT NULL,
  `PaymentSource` enum('POS','Website') NOT NULL,
  `TransactionID` varchar(50) DEFAULT NULL,
  `Notes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payments`
--

INSERT INTO `payments` (`PaymentID`, `OrderID`, `PaymentDate`, `PaymentMethod`, `PaymentStatus`, `AmountPaid`, `PaymentSource`, `TransactionID`, `Notes`) VALUES
(1, 1000, '2025-11-23 12:46:04', 'COD', 'Pending', 345.00, 'Website', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `ProductID` int(10) NOT NULL,
  `ProductName` varchar(100) NOT NULL,
  `Category` enum('SPAGHETTI MEAL','DESSERT','DRINKS & BEVERAGES','PLATTER','RICE MEAL','RICE','Bilao','SNACKS','NOODLES & PASTA') NOT NULL,
  `Description` text DEFAULT NULL,
  `Price` decimal(10,2) NOT NULL,
  `Availability` enum('Available','Not Available') DEFAULT 'Available',
  `ServingSize` enum('REGULAR','SMALL','MEDIUM','LARGE') DEFAULT NULL,
  `DateAdded` datetime DEFAULT current_timestamp(),
  `LastUpdated` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `ProductCode` varchar(20) DEFAULT NULL,
  `PopularityTag` enum('Best Seller','Regular') DEFAULT 'Regular',
  `MealTime` enum('Breakfast','Lunch','Dinner','All Day') DEFAULT NULL,
  `OrderCount` int(10) DEFAULT 0,
  `Image` varchar(255) DEFAULT NULL,
  `PrepTime` int(3) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`ProductID`, `ProductName`, `Category`, `Description`, `Price`, `Availability`, `ServingSize`, `DateAdded`, `LastUpdated`, `ProductCode`, `PopularityTag`, `MealTime`, `OrderCount`, `Image`, `PrepTime`) VALUES
(1, 'S-A (w/ Butter Bread)', 'SPAGHETTI MEAL', 'Sweet-style spaghetti served with toasted buttered bread.', 105.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:42', 'S-A', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870039518.jpg', 10),
(2, 'S-B (w/ Shanghai & Empanada)', 'SPAGHETTI MEAL', 'Spaghetti served with shanghai rolls and an empanada.', 165.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:42', 'S-B', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870028508.jpg', 12),
(3, 'S-C (w/ Shanghai, Ham & Cheese Sandwich)', 'SPAGHETTI MEAL', 'Spaghetti with shanghai and ham & cheese sandwich.', 180.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:42', 'S-C', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870037291.jpg', 13),
(4, 'S-D (w/ Empanada & Chicken)', 'SPAGHETTI MEAL', 'Spaghetti paired with empanada and fried chicken.', 165.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', 'S-D', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870027024.jpg', 13),
(5, 'S-E (w/ Chicken & Fries)', 'SPAGHETTI MEAL', 'Spaghetti with crispy chicken and fries.', 170.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', 'S-E', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870035752.jpg', 12),
(6, 'S-F (w/ Shanghai & Chicken)', 'SPAGHETTI MEAL', 'Spaghetti served with shanghai rolls and chicken.', 180.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', 'S-F', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870025216.jpg', 13),
(7, 'S-G (Ham & Cheese Sandwich w/ Fries)', 'SPAGHETTI MEAL', 'Spaghetti with ham & cheese sandwich and fries.', 170.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', 'S-G', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870030435.jpg', 12),
(8, 'S-H (Chicken, Pizza Roll & Fries)', 'SPAGHETTI MEAL', 'Spaghetti with chicken, pizza roll, and fries.', 185.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', 'S-H', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870023506.jpg', 14),
(9, 'Club Sandwich', 'SNACKS', 'Triple-layer sandwich with ham, egg, veggies and sauce.', 130.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (23).jpeg', 8),
(10, 'Ham & Cheese Sandwich', 'SNACKS', 'Toasted ham and cheese sandwich.', 55.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (24).jpeg', 5),
(11, 'Lomi Solo', 'SNACKS', 'Thick noodle soup with egg and toppings.', 105.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/LOMI.jpg', 12),
(12, 'Salo Salo', 'SNACKS', 'Assorted snacks plate for sharing.', 240.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/LOMI.jpg', 10),
(13, 'Fried Lumpia (6 PCS)', 'SNACKS', 'Crispy vegetable/meat rolls (6 pcs).', 75.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (25).jpeg', 7),
(14, 'Pizza Roll', 'SNACKS', 'Crispy roll filled with pizza-style cheese and sauce.', 58.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/pizza-bread-roll-recipe.jpg', 6),
(15, 'Empanada', 'SNACKS', 'Golden-fried empanada stuffed with savory filling.', 30.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (26).jpeg', 6),
(16, 'Potato Fries', 'SNACKS', 'Crispy seasoned fries served hot.', 90.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (27).jpeg', 8),
(17, 'Halo Halo', 'DESSERT', 'Shaved ice dessert with milk, beans and toppings.', 125.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/gallery3.jpg', 8),
(18, 'Maiz con Leche', 'DESSERT', 'Sweet corn in creamy milk, chilled.', 90.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870084790.jpg', 6),
(19, 'Leche Flan 1/4', 'DESSERT', 'Quarter portion of traditional caramel custard.', 40.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/filipino-leche-flan-cover-1.jpg', 5),
(20, 'Leche Flan Whole', 'DESSERT', 'Whole serving of rich caramel custard.', 145.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/filipino-leche-flan-cover-1.jpg', 8),
(21, 'Canned Soft Drink (Coke | Royal | Sprite | Mt. Dew)', 'DRINKS & BEVERAGES', 'Assorted canned sodas, 330ml.', 45.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (14).jpeg', 0),
(22, 'Bottled Water', 'DRINKS & BEVERAGES', 'Still bottled mineral water, 500ml.', 25.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/bottled_water.jpeg', 0),
(23, 'Pineapple Juice', 'DRINKS & BEVERAGES', 'Fresh pineapple juice, chilled.', 50.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (15).jpeg', 2),
(24, 'Mango Juice', 'DRINKS & BEVERAGES', 'Sweet mango juice, chilled.', 50.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (16).jpeg', 2),
(25, 'Iced Tea (Glass)', 'DRINKS & BEVERAGES', 'Fresh iced tea, served chilled.', 40.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (17).jpeg', 1),
(26, 'Iced Tea (Pitcher)', 'DRINKS & BEVERAGES', 'Pitcher of iced tea for sharing.', 85.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (17).jpeg', 2),
(27, 'Coffee', 'DRINKS & BEVERAGES', 'Hot brewed coffee, single cup.', 40.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (18).jpeg', 5),
(28, 'SMB Pale Pilsen', 'DRINKS & BEVERAGES', 'Bottle of local pale pilsen beer.', 65.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (19).jpeg', 0),
(29, 'Red Horse Stallion', 'DRINKS & BEVERAGES', 'Strong beer bottle, local brand.', 65.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (20).jpeg', 0),
(30, 'San Mig Light', 'DRINKS & BEVERAGES', 'Light beer bottle.', 65.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (21).jpeg', 0),
(31, 'Bucket of Six (Beers)', 'DRINKS & BEVERAGES', 'Six bottles of assorted beers in a bucket.', 360.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (21).jpeg', 0),
(32, 'Crispy Pork Sisig (Platter 3-4 pax)', 'PLATTER', 'Crispy sisig platter good for 3-4 persons.', 250.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (34).jpeg', 20),
(33, 'Crispy Pork Sisig w/ Egg (Platter)', 'PLATTER', 'Crispy sisig with sunny-side-up egg.', 265.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (34).jpeg', 22),
(34, 'Lechon Kawali (Platter)', 'PLATTER', 'Crispy lechon kawali platter for sharing.', 350.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (35).jpeg', 25),
(35, 'Lumpiang Shanghai (Platter)', 'PLATTER', 'Platter of lumpiang shanghai (many pcs).', 250.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870008092.jpg', 18),
(36, 'Buttered Chicken (Platter)', 'PLATTER', 'Savory buttered chicken served family-style.', 250.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (36).jpeg', 25),
(37, 'Calamares (Platter)', 'PLATTER', 'Crispy battered calamari platter.', 320.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (36).jpeg', 20),
(38, 'Fried Lumpia Veg. (12 PCS) (Platter)', 'PLATTER', 'Vegetable fried lumpia, 12 pcs.', 145.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/download.jpg', 15),
(39, 'Tokwa\'t Baboy (Platter)', 'PLATTER', 'Fried tokwa and pork with sauce.', 260.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (38).jpeg', 18),
(40, 'Beef Steak Tagalog (Platter)', 'PLATTER', 'Beef steak in savory sauce, platter size.', 340.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (39).jpeg', 25),
(41, 'Sizzling Spicy Squid (Platter)', 'PLATTER', 'Spicy squid served on a sizzling plate.', 360.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (40).jpeg', 20),
(42, 'Sizzling Tofu (Platter)', 'PLATTER', 'Sizzling tofu with savory sauce.', 180.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/Tofu-Sisig-with-Egg-scaled-1.jpg', 15),
(43, 'Bicol Express (Platter)', 'PLATTER', 'Spicy pork in coconut milk, platter share.', 260.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (41).jpeg', 20),
(44, 'Pork Adobo (Platter)', 'PLATTER', 'Classic pork adobo served family-style.', 250.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (42).jpeg', 22),
(45, '6 pcs Pork BBQ w/ Butter Veg. (Platter)', 'PLATTER', 'Six pork BBQ skewers with buttered vegetables.', 270.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (44).jpeg', 18),
(46, 'Chopsuey (Platter)', 'PLATTER', 'Mixed vegetables in light stir-fry sauce.', 250.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763869994665.jpg', 18),
(47, 'Chicken w/ Mixed Veg (Platter)', 'PLATTER', 'Chicken with mixed vegetables, platter.', 480.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (43).jpeg', 30),
(48, 'Garlic Butter Shrimp (Platter)', 'PLATTER', 'Shrimp tossed in garlic butter, for sharing.', 260.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (33).jpeg', 20),
(49, 'Shrimp & Squid Kare Kare (Platter)', 'PLATTER', 'Seafood kare-kare served with peanut sauce.', 480.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (32).jpeg', 35),
(50, 'Bagnet Kare Kare (Platter)', 'PLATTER', 'Crispy bagnet in kare-kare sauce, platter.', 450.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (1).jpg', 35),
(51, 'Shrimp Sinigang (Platter)', 'PLATTER', 'Sour tamarind soup with shrimp, family-size.', 350.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (31).jpeg', 30),
(52, 'Pork Sinigang (Platter)', 'PLATTER', 'Sinigang with pork, served family-style.', 380.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/Killer-Pork-Sinigang-jpg.webp', 30),
(53, 'Hototay Soup (Platter)', 'PLATTER', 'Mixed vegetable and seafood soup for sharing.', 260.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/hototay-scaled.jpg', 20),
(54, 'Pork Sisig Solo w/ Egg (Rice Meal)', 'RICE MEAL', 'Solo pork sisig served with garlic yellow rice and egg.', 135.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870457190.jpg', 12),
(55, 'Pork Adobo w/ Egg (Rice Meal)', 'RICE MEAL', 'Classic pork adobo with rice and fried egg.', 125.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (5).jpeg', 10),
(56, 'Pork Tocino w/ Egg (Rice Meal)', 'RICE MEAL', 'Sweet cured pork (tocino) with rice and egg.', 105.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (2).jpg', 10),
(57, 'Beef Tapa w/ Egg (Rice Meal)', 'RICE MEAL', 'Marinated beef tapa with rice and egg.', 110.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (6).jpeg', 12),
(58, 'Beef Teriyaki w/ Egg (Rice Meal)', 'RICE MEAL', 'Teriyaki-style beef served with rice and egg.', 125.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/teriyaki.jpg', 12),
(59, 'Breaded Porkchop w/ Egg (Rice Meal)', 'RICE MEAL', 'Crispy breaded porkchop with rice and egg.', 125.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (3).jpg', 15),
(60, 'Sizzling Tofu w/ Egg (Rice Meal)', 'RICE MEAL', 'Sizzling tofu with vegetables, rice and egg.', 100.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (8).jpeg', 12),
(61, 'Spam w/ Egg (Rice Meal)', 'RICE MEAL', 'Fried spam with garlic rice and egg.', 125.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (9).jpeg', 8),
(62, 'Breaded Chicken w/ Egg (Rice Meal)', 'RICE MEAL', 'Crispy breaded chicken with rice and egg.', 100.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (10).jpeg', 15),
(63, '2 pcs Pork BBQ w/ Butter Veg. (Rice Meal)', 'RICE MEAL', 'Two pork BBQ skewers with rice and veggies.', 130.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870519059.jpg', 12),
(64, '2 pcs Breaded Chicken (Rice Meal)', 'RICE MEAL', 'Two pieces of breaded chicken with rice.', 145.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (11).jpeg', 18),
(65, 'BBQ w/ Shanghai (Rice Meal)', 'RICE MEAL', 'Pork BBQ with shanghai and rice.', 135.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870517646.jpg', 14),
(66, 'BBQ & Chicken Meal (Rice Meal)', 'RICE MEAL', 'Combo of BBQ and chicken with rice.', 145.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870519059.jpg', 16),
(67, 'Bicol Express w/ Shanghai (Rice Meal)', 'RICE MEAL', 'Spicy Bicol Express with shanghai and rice.', 165.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (12).jpeg', 18),
(68, 'Bicol Express w/ Fried Chicken (Rice Meal)', 'RICE MEAL', 'Bicol Express paired with fried chicken and rice.', 165.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/bicolep.jpeg', 20),
(69, 'BBQ w/ Bicol Express (Rice Meal)', 'RICE MEAL', 'Pork BBQ served with Bicol Express and rice.', 140.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870519059.jpg', 18),
(70, 'Garlic Yellow Rice (Cup)', 'RICE', 'Single cup of garlic turmeric yellow rice.', 27.00, 'Available', 'REGULAR', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (22).jpeg', 1),
(71, 'Garlic Yellow Rice (Small - 3-4 persons)', 'RICE', 'Small tray of garlic yellow rice suitable for 3-4 persons.', 85.00, 'Available', 'SMALL', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (22).jpeg', 5),
(72, 'Garlic Yellow Rice (Medium - 5-6 persons)', 'RICE', 'Medium tray of garlic yellow rice for 5-6 persons.', 140.00, 'Available', 'MEDIUM', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (22).jpeg', 8),
(73, 'Garlic Yellow Rice (Large - 7-8 persons)', 'RICE', 'Large tray of garlic yellow rice for 7-8 persons.', 185.00, 'Available', 'LARGE', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (22).jpeg', 12),
(74, 'Plain Rice (Cup)', 'RICE', 'Single cup of steamed plain rice.', 18.00, 'Available', 'REGULAR', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/how-to-cook-rice.jpg', 1),
(75, 'Plain Rice (Small - 3-4 persons)', 'RICE', 'Small tray of plain steamed rice for 3-4 persons.', 65.00, 'Available', 'SMALL', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/how-to-cook-rice.jpg', 5),
(76, 'Plain Rice (Medium - 5-6 persons)', 'RICE', 'Medium tray of plain rice for 5-6 persons.', 95.00, 'Available', 'MEDIUM', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/how-to-cook-rice.jpg', 8),
(77, 'Plain Rice (Large - 7-8 persons)', 'RICE', 'Large tray of plain rice for 7-8 persons.', 130.00, 'Available', 'LARGE', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/how-to-cook-rice.jpg', 12),
(78, 'Pancit Canton Guisado (Good for 3-4 persons)', 'NOODLES & PASTA', 'Stir-fried pancit canton good for small group.', 200.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (4).jpg', 18),
(79, 'Pancit Canton Guisado (Small 8-10 persons)', 'NOODLES & PASTA', 'Small pancit canton for 8-10 persons.', 585.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (4).jpg', 30),
(80, 'Pancit Canton Guisado (Medium 12-15 persons)', 'NOODLES & PASTA', 'Medium pancit canton for 12-15 persons.', 880.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (4).jpg', 45),
(81, 'Pancit Canton Guisado (Large 17-20 persons)', 'NOODLES & PASTA', 'Large pancit canton for 17-20 persons.', 1150.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (4).jpg', 60),
(82, 'Bihon Miki Bihon (Good for 3-4 persons)', 'NOODLES & PASTA', 'Light bihon noodles suitable for 3-4 persons.', 200.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (28).jpeg', 18),
(83, 'Bihon Miki Bihon (Small 8-10 persons)', 'NOODLES & PASTA', 'Small bihon tray for 8-10 persons.', 585.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (28).jpeg', 30),
(84, 'Bihon Miki Bihon (Medium 12-15 persons)', 'NOODLES & PASTA', 'Medium bihon tray for 12-15 persons.', 880.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (28).jpeg', 45),
(85, 'Bihon Miki Bihon (Large 17-20 persons)', 'NOODLES & PASTA', 'Large bihon tray for 17-20 persons.', 1150.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (28).jpeg', 60),
(86, 'Sotanghon (Good for 3-4 persons)', 'NOODLES & PASTA', 'Glass noodle (sotanghon) dish for 3-4 persons.', 240.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (29).jpeg', 20),
(87, 'Sotanghon (Small 8-10 persons)', 'NOODLES & PASTA', 'Small sotanghon tray for 8-10 persons.', 690.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (29).jpeg', 35),
(88, 'Sotanghon (Medium 12-15 persons)', 'NOODLES & PASTA', 'Medium sotanghon tray for 12-15 persons.', 1050.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (29).jpeg', 50),
(89, 'Sotanghon (Large 17-20 persons)', 'NOODLES & PASTA', 'Large sotanghon tray for 17-20 persons.', 1390.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (29).jpeg', 70),
(90, 'Spaghetti Carbonara (Good for 3-4 persons)', 'NOODLES & PASTA', 'Creamy carbonara spaghetti for 3-4 people.', 255.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (5).jpg', 25),
(91, 'Spaghetti Carbonara (Small 8-10 persons)', 'NOODLES & PASTA', 'Small carbonara tray for 8-10 persons.', 730.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (5).jpg', 40),
(92, 'Spaghetti Carbonara (Medium 12-15 persons)', 'NOODLES & PASTA', 'Medium carbonara tray for 12-15 persons.', 1080.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (5).jpg', 60),
(93, 'Spaghetti Carbonara (Large 17-20 persons)', 'NOODLES & PASTA', 'Large carbonara tray for 17-20 persons.', 1495.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (5).jpg', 80),
(94, 'Palabok (Good for 3-4 persons)', 'NOODLES & PASTA', 'Traditional palabok for 3-4 persons.', 255.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (6).jpg', 25),
(95, 'Palabok (Small 8-10 persons)', 'NOODLES & PASTA', 'Small palabok tray for 8-10 persons.', 730.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (6).jpg', 40),
(96, 'Palabok (Medium 12-15 persons)', 'NOODLES & PASTA', 'Medium palabok tray for 12-15 persons.', 1080.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (6).jpg', 60),
(97, 'Palabok (Large 17-20 persons)', 'NOODLES & PASTA', 'Large palabok tray for 17-20 persons.', 1495.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (6).jpg', 80);

-- --------------------------------------------------------

--
-- Table structure for table `product_ingredients`
--

CREATE TABLE `product_ingredients` (
  `ProductIngredientID` int(10) NOT NULL COMMENT 'Unique identifier for each product–ingredient link',
  `ProductID` int(10) NOT NULL COMMENT 'References the related menu product',
  `IngredientID` int(10) NOT NULL COMMENT 'References the ingredient used',
  `QuantityUsed` decimal(10,2) NOT NULL COMMENT 'Amount of the ingredient used per product serving',
  `UnitType` varchar(50) DEFAULT NULL COMMENT 'Measurement unit (e.g., "g", "ml", "pcs", "tbsp", "tsp")',
  `CreatedDate` datetime DEFAULT current_timestamp() COMMENT 'Record creation date',
  `UpdatedDate` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last update timestamp'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `product_ingredients`
--

INSERT INTO `product_ingredients` (`ProductIngredientID`, `ProductID`, `IngredientID`, `QuantityUsed`, `UnitType`, `CreatedDate`, `UpdatedDate`) VALUES
(1, 1, 30, 150.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(2, 1, 60, 50.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(3, 1, 65, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(4, 1, 31, 10.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(5, 1, 32, 5.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(6, 1, 86, 20.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(7, 2, 30, 150.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(8, 2, 60, 50.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(9, 2, 65, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(10, 2, 11, 50.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(11, 2, 35, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(12, 2, 36, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(13, 2, 96, 2.00, 'pc', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(14, 2, 31, 10.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(15, 2, 86, 50.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(16, 3, 30, 150.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(17, 3, 60, 50.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(18, 3, 65, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(19, 3, 11, 50.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(20, 3, 35, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(21, 3, 96, 2.00, 'pc', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(22, 3, 76, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(23, 3, 61, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(24, 3, 86, 50.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(25, 4, 30, 150.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(26, 4, 60, 50.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(27, 4, 65, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(28, 4, 5, 100.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(29, 4, 93, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(30, 4, 31, 10.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(31, 4, 86, 50.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(32, 5, 30, 150.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(33, 5, 60, 50.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(34, 5, 65, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(35, 5, 5, 100.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(36, 5, 53, 100.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(37, 5, 93, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(38, 5, 86, 50.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(39, 6, 30, 150.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(40, 6, 60, 50.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(41, 6, 65, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(42, 6, 5, 100.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(43, 6, 11, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(44, 6, 35, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(45, 6, 96, 2.00, 'pc', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(46, 6, 86, 50.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(47, 7, 30, 150.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(48, 7, 60, 50.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(49, 7, 65, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(50, 7, 19, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(51, 7, 76, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(52, 7, 53, 100.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(53, 7, 86, 50.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(54, 8, 30, 150.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(55, 8, 60, 50.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(56, 8, 65, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(57, 8, 5, 100.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(58, 8, 76, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(59, 8, 53, 100.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(60, 8, 93, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(61, 8, 86, 50.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(62, 9, 19, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(63, 9, 22, 2.00, 'pc', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(64, 9, 31, 15.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(65, 9, 52, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(66, 9, 51, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(67, 9, 61, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(68, 9, 86, 15.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(69, 10, 19, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(70, 10, 76, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(71, 10, 61, 15.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(72, 10, 86, 10.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(73, 11, 25, 100.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(74, 11, 28, 150.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(75, 11, 22, 1.00, 'pc', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(76, 11, 31, 10.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(77, 11, 32, 5.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(78, 11, 55, 15.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(79, 11, 86, 20.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(80, 12, 11, 50.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(81, 12, 35, 40.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(82, 12, 36, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(83, 12, 22, 1.00, 'pc', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(84, 12, 76, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(85, 12, 31, 15.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(86, 12, 86, 80.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(87, 13, 11, 60.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(88, 13, 35, 50.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(89, 13, 36, 40.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(90, 13, 95, 6.00, 'pc', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(91, 13, 31, 10.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(92, 13, 86, 50.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(93, 14, 76, 25.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(94, 14, 60, 20.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(95, 14, 95, 1.00, 'pc', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(96, 14, 86, 30.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(97, 15, 11, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(98, 15, 31, 5.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(99, 15, 92, 30.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(100, 15, 86, 20.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(101, 16, 53, 150.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(102, 16, 87, 5.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(103, 16, 90, 2.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(104, 16, 86, 100.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(105, 17, 106, 150.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(106, 17, 72, 30.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(107, 17, 98, 20.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(108, 17, 99, 20.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(109, 17, 100, 20.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(110, 17, 101, 20.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(111, 18, 54, 80.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(112, 18, 72, 50.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(113, 18, 71, 50.00, 'ml', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(114, 18, 106, 100.00, 'g', '2025-11-22 09:42:56', '2025-11-22 09:42:56'),
(115, 19, 72, 50.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(116, 19, 71, 30.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(117, 19, 22, 2.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(118, 19, 97, 0.25, 'pack', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(119, 20, 72, 100.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(120, 20, 71, 80.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(121, 20, 22, 5.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(122, 20, 97, 1.00, 'pack', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(123, 54, 6, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(124, 54, 62, 10.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(125, 54, 31, 15.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(126, 54, 22, 1.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(127, 54, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(128, 54, 86, 20.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(129, 55, 1, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(130, 55, 55, 20.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(131, 55, 56, 15.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(132, 55, 31, 10.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(133, 55, 32, 5.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(134, 55, 22, 1.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(135, 55, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(136, 55, 86, 20.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(137, 56, 15, 100.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(138, 56, 22, 1.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(139, 56, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(140, 56, 86, 20.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(141, 57, 16, 100.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(142, 57, 22, 1.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(143, 57, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(144, 57, 86, 20.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(145, 58, 12, 100.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(146, 58, 55, 15.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(147, 58, 31, 10.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(148, 58, 22, 1.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(149, 58, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(150, 58, 86, 20.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(151, 59, 1, 100.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(152, 59, 93, 30.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(153, 59, 22, 1.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(154, 59, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(155, 59, 86, 50.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(156, 60, 31, 20.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(157, 60, 32, 10.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(158, 60, 35, 40.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(159, 60, 22, 1.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(160, 60, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(161, 60, 86, 30.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(162, 61, 21, 50.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(163, 61, 22, 1.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(164, 61, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(165, 61, 86, 20.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(166, 62, 5, 100.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(167, 62, 93, 30.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(168, 62, 22, 1.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(169, 62, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(170, 62, 86, 50.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(171, 63, 1, 100.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(172, 63, 55, 10.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(173, 63, 75, 10.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(174, 63, 35, 30.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(175, 63, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(176, 63, 86, 30.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(177, 64, 5, 120.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(178, 64, 93, 40.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(179, 64, 22, 1.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(180, 64, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(181, 64, 86, 50.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(182, 65, 1, 80.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(183, 65, 11, 40.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(184, 65, 35, 30.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(185, 65, 96, 2.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(186, 65, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(187, 65, 86, 40.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(188, 66, 1, 60.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(189, 66, 5, 80.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(190, 66, 93, 30.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(191, 66, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(192, 66, 86, 50.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(193, 67, 1, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(194, 67, 73, 100.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(195, 67, 48, 10.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(196, 67, 11, 40.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(197, 67, 35, 30.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(198, 67, 96, 2.00, 'pc', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(199, 67, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(200, 67, 86, 40.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(201, 68, 1, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(202, 68, 73, 100.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(203, 68, 48, 10.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(204, 68, 5, 100.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(205, 68, 93, 30.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(206, 68, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(207, 68, 86, 50.00, 'ml', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(214, 70, 25, 50.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(215, 70, 32, 10.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(216, 70, 75, 5.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(217, 70, 26, 5.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(218, 71, 25, 150.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(219, 71, 32, 25.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(220, 71, 75, 15.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(221, 71, 26, 15.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(222, 72, 25, 250.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(223, 72, 32, 40.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(224, 72, 75, 25.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(225, 72, 26, 25.00, 'g', '2025-11-22 09:42:57', '2025-11-22 09:42:57'),
(226, 73, 25, 350.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(227, 73, 32, 60.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(228, 73, 75, 35.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(229, 73, 26, 35.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(230, 74, 25, 50.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(231, 75, 25, 150.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(232, 76, 25, 250.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(233, 77, 25, 350.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(234, 78, 27, 150.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(235, 78, 11, 50.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(236, 78, 35, 50.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(237, 78, 36, 40.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(238, 78, 55, 15.00, 'ml', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(239, 78, 31, 15.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(240, 78, 86, 30.00, 'ml', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(241, 79, 27, 400.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(242, 79, 11, 150.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(243, 79, 35, 150.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(244, 79, 36, 120.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(245, 79, 55, 40.00, 'ml', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(246, 79, 31, 40.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(247, 79, 86, 80.00, 'ml', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(248, 80, 27, 600.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(249, 80, 11, 250.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(250, 80, 35, 250.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(251, 80, 36, 200.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(252, 80, 55, 60.00, 'ml', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(253, 80, 31, 60.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(254, 80, 86, 120.00, 'ml', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(255, 81, 27, 800.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(256, 81, 11, 350.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(257, 81, 35, 350.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(258, 81, 36, 280.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(259, 81, 55, 80.00, 'ml', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(260, 81, 31, 80.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(261, 81, 86, 150.00, 'ml', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(262, 82, 28, 150.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(263, 82, 11, 50.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(264, 82, 35, 50.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(265, 82, 36, 40.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(266, 82, 55, 15.00, 'ml', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(267, 82, 31, 15.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(268, 82, 86, 30.00, 'ml', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(269, 83, 28, 400.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(270, 83, 11, 150.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(271, 83, 35, 150.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(272, 83, 36, 120.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(273, 83, 55, 40.00, 'ml', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(274, 83, 31, 40.00, 'g', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(275, 83, 86, 80.00, 'ml', '2025-11-22 09:42:58', '2025-11-22 09:42:58'),
(483, 69, 1, 200.00, 'g', '2025-11-22 09:49:06', '2025-11-22 09:49:06'),
(484, 69, 73, 80.00, 'ml', '2025-11-22 09:49:06', '2025-11-22 09:49:06'),
(485, 69, 48, 8.00, 'g', '2025-11-22 09:49:06', '2025-11-22 09:49:06'),
(486, 69, 25, 150.00, 'g', '2025-11-22 09:49:06', '2025-11-22 09:49:06'),
(487, 69, 86, 40.00, 'ml', '2025-11-22 09:49:06', '2025-11-22 09:49:06');

-- --------------------------------------------------------

--
-- Table structure for table `reservations`
--

CREATE TABLE `reservations` (
  `ReservationID` int(10) NOT NULL,
  `CustomerID` int(10) NOT NULL,
  `AssignedStaffID` int(10) DEFAULT NULL,
  `ReservationType` enum('Online','Walk-in') NOT NULL,
  `EventType` varchar(50) NOT NULL,
  `EventDate` date NOT NULL,
  `EventTime` time NOT NULL,
  `NumberOfGuests` int(5) NOT NULL,
  `ProductSelection` text DEFAULT NULL,
  `SpecialRequests` text DEFAULT NULL,
  `ReservationStatus` enum('Pending','Confirmed','Cancelled') DEFAULT 'Pending',
  `ReservationDate` datetime DEFAULT current_timestamp(),
  `DeliveryAddress` varchar(500) DEFAULT NULL COMMENT 'Delivery address for catering',
  `DeliveryOption` enum('Pickup','Delivery') DEFAULT NULL,
  `ContactNumber` varchar(20) DEFAULT NULL,
  `UpdatedDate` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reservations`
--

INSERT INTO `reservations` (`ReservationID`, `CustomerID`, `AssignedStaffID`, `ReservationType`, `EventType`, `EventDate`, `EventTime`, `NumberOfGuests`, `ProductSelection`, `SpecialRequests`, `ReservationStatus`, `ReservationDate`, `DeliveryAddress`, `DeliveryOption`, `ContactNumber`, `UpdatedDate`) VALUES
(2, 7, NULL, 'Online', 'wedding', '2025-11-22', '18:00:00', 1, 'Lumpiang Shanghai (Platter) x1, Bicol Express (Platter) x1', 'awdwdad', 'Pending', '2025-11-22 15:32:36', 'p0wncacsad', 'Delivery', '09512994765', '2025-11-22 15:32:36'),
(3, 7, NULL, 'Online', 'anniversary', '2025-11-22', '16:00:00', 65, 'Lumpiang Shanghai (Platter) x1, Buttered Chicken (Platter) x1, Bicol Express (Platter) x1', 'wfafewafeafa', 'Pending', '2025-11-22 15:42:47', 'p0wncacsad', 'Delivery', '09512994765', '2025-11-22 15:42:47'),
(4, 7, NULL, 'Online', 'anniversary', '2025-11-22', '19:00:00', 45, 'Buttered Chicken (Platter) x1, Pork Adobo (Platter) x1', 'wdada', 'Pending', '2025-11-22 15:53:14', 'wdawdwa', 'Delivery', '09512994765', '2025-11-22 15:53:14'),
(5, 8, NULL, 'Online', 'anniversary', '2025-11-22', '19:00:00', 50, 'Shrimp & Squid Kare Kare (Platter) x1', 'no more sugar', 'Pending', '2025-11-22 22:37:24', '', 'Pickup', '09511299476', '2025-11-22 22:37:24'),
(6, 8, NULL, 'Online', 'anniversary', '2025-11-22', '16:00:00', 50, 'S-E (w/ Chicken & Fries) x1, S-H (Chicken, Pizza Roll & Fries) x1', '', 'Pending', '2025-11-23 00:17:36', '', 'Pickup', '09511299476', '2025-11-23 00:17:36'),
(7, 8, NULL, 'Online', 'anniversary', '2025-11-23', '18:00:00', 50, 'Bicol Express (Platter) x1', '', 'Pending', '2025-11-23 12:32:49', '', 'Pickup', '09511299476', '2025-11-23 12:32:49');

--
-- Triggers `reservations`
--
DELIMITER $$
CREATE TRIGGER `tr_reservation_approved` AFTER UPDATE ON `reservations` FOR EACH ROW BEGIN
    IF NEW.ReservationStatus = 'Approved' AND OLD.ReservationStatus != 'Approved' THEN
        CALL DeductIngredientsForReservation(NEW.ReservationID);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `reservation_items`
--

CREATE TABLE `reservation_items` (
  `ReservationItemID` int(10) NOT NULL,
  `ReservationID` int(10) NOT NULL,
  `ProductName` varchar(100) NOT NULL,
  `Quantity` int(4) NOT NULL,
  `UnitPrice` decimal(10,2) NOT NULL,
  `TotalPrice` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reservation_items`
--

INSERT INTO `reservation_items` (`ReservationItemID`, `ReservationID`, `ProductName`, `Quantity`, `UnitPrice`, `TotalPrice`) VALUES
(43, 2, 'Lumpiang Shanghai (Platter)', 1, 250.00, 250.00),
(44, 2, 'Bicol Express (Platter)', 1, 260.00, 260.00),
(45, 3, 'Lumpiang Shanghai (Platter)', 1, 250.00, 250.00),
(46, 3, 'Buttered Chicken (Platter)', 1, 250.00, 250.00),
(47, 3, 'Bicol Express (Platter)', 1, 260.00, 260.00),
(48, 4, 'Buttered Chicken (Platter)', 1, 250.00, 250.00),
(49, 4, 'Pork Adobo (Platter)', 1, 250.00, 250.00),
(50, 5, 'Shrimp & Squid Kare Kare (Platter)', 1, 480.00, 480.00),
(51, 6, 'S-E (w/ Chicken & Fries)', 1, 170.00, 170.00),
(52, 6, 'S-H (Chicken, Pizza Roll & Fries)', 1, 185.00, 185.00),
(53, 7, 'Bicol Express (Platter)', 1, 260.00, 260.00);

-- --------------------------------------------------------

--
-- Table structure for table `reservation_payments`
--

CREATE TABLE `reservation_payments` (
  `ReservationPaymentID` int(10) NOT NULL,
  `ReservationID` int(10) NOT NULL,
  `PaymentDate` datetime DEFAULT current_timestamp(),
  `PaymentMethod` enum('Cash','GCash','COD') DEFAULT 'Cash',
  `PaymentStatus` enum('Pending','Completed','Refunded','Failed') DEFAULT 'Pending',
  `AmountPaid` decimal(10,2) NOT NULL,
  `PaymentSource` enum('POS','Website') NOT NULL,
  `ProofOfPayment` varchar(255) DEFAULT NULL COMMENT 'Path to uploaded GCash receipt image',
  `ReceiptFileName` varchar(255) DEFAULT NULL COMMENT 'Original filename of receipt',
  `TransactionID` varchar(50) DEFAULT NULL,
  `UpdatedDate` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp() COMMENT 'Last update timestamp'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reservation_payments`
--

INSERT INTO `reservation_payments` (`ReservationPaymentID`, `ReservationID`, `PaymentDate`, `PaymentMethod`, `PaymentStatus`, `AmountPaid`, `PaymentSource`, `ProofOfPayment`, `ReceiptFileName`, `TransactionID`, `UpdatedDate`) VALUES
(2, 2, '2025-11-22 15:32:36', 'GCash', 'Pending', 510.00, 'Website', 'uploads/gcash_receipts/2025/11/receipt_7_1763796756_1626.jpg', 'receipt_7_1763796756_1626.jpg', NULL, '2025-11-22 15:32:36'),
(3, 3, '2025-11-22 15:42:47', 'GCash', 'Pending', 760.00, 'Website', 'uploads/gcash_receipts/2025/11/receipt_7_1763797367_7725.jpg', 'receipt_7_1763797367_7725.jpg', NULL, '2025-11-22 15:42:47'),
(4, 4, '2025-11-22 15:53:14', 'GCash', 'Pending', 500.00, 'Website', 'uploads/gcash_receipts/2025/11/receipt_7_1763797994_7710.jpg', 'receipt_7_1763797994_7710.jpg', NULL, '2025-11-22 15:53:14'),
(5, 5, '2025-11-22 22:37:24', 'GCash', 'Pending', 480.00, 'Website', 'uploads/gcash_receipts/2025/11/receipt_8_1763822244_9241.jpg', 'receipt_8_1763822244_9241.jpg', NULL, '2025-11-22 22:37:24'),
(6, 6, '2025-11-23 00:17:36', 'GCash', 'Pending', 355.00, 'Website', 'uploads/gcash_receipts/2025/11/receipt_8_1763828256_3785.jpg', 'receipt_8_1763828256_3785.jpg', NULL, '2025-11-23 00:17:36'),
(7, 7, '2025-11-23 12:32:49', 'GCash', 'Pending', 260.00, 'Website', 'uploads/gcash_receipts/2025/11/receipt_8_1763872369_2130.jpg', 'receipt_8_1763872369_2130.jpg', NULL, '2025-11-23 12:32:49');

-- --------------------------------------------------------

--
-- Stand-in structure for view `review_statistics`
-- (See below for the actual view)
--
CREATE TABLE `review_statistics` (
`total_reviews` bigint(21)
,`approved_reviews` bigint(21)
,`pending_reviews` bigint(21)
,`rejected_reviews` bigint(21)
,`avg_overall_rating` decimal(4,2)
,`avg_food_taste` decimal(13,2)
,`avg_portion_size` decimal(13,2)
,`avg_customer_service` decimal(13,2)
,`avg_ambience` decimal(13,2)
,`avg_cleanliness` decimal(13,2)
,`five_star_count` bigint(21)
,`four_star_count` bigint(21)
,`three_star_count` bigint(21)
,`two_star_count` bigint(21)
,`one_star_count` bigint(21)
);

-- --------------------------------------------------------

--
-- Table structure for table `user_accounts`
--

CREATE TABLE `user_accounts` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `position` varchar(100) DEFAULT NULL,
  `username` varchar(50) NOT NULL,
  `password` text NOT NULL,
  `type` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user_accounts`
--

INSERT INTO `user_accounts` (`id`, `name`, `position`, `username`, `password`, `type`, `created_at`) VALUES
(4, 'Administrator', 'Admin', 'admin', 'NRmacANXZLxcP3FyLn0u+fQEfntDUOQiRuhYv8lVjYc=', 1, '2025-11-21 04:26:16');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_batch_details`
-- (See below for the actual view)
--
CREATE TABLE `v_batch_details` (
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_expiring_batches`
-- (See below for the actual view)
--
CREATE TABLE `v_expiring_batches` (
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_inventory_summary`
-- (See below for the actual view)
--
CREATE TABLE `v_inventory_summary` (
`IngredientID` int(10)
,`IngredientName` varchar(100)
,`CategoryName` varchar(100)
,`DefaultUnit` varchar(50)
,`TotalStock` decimal(32,2)
,`ActiveBatches` bigint(21)
,`NextExpiration` date
,`MinStockLevel` decimal(10,2)
,`MaxStockLevel` decimal(10,2)
,`StockStatus` varchar(12)
,`TotalValue` decimal(42,4)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_low_stock_items`
-- (See below for the actual view)
--
CREATE TABLE `v_low_stock_items` (
`IngredientID` int(10)
,`IngredientName` varchar(100)
,`CategoryName` varchar(100)
,`CurrentStock` decimal(32,2)
,`UnitType` varchar(50)
,`MinStockLevel` decimal(10,2)
,`MaxStockLevel` decimal(10,2)
,`ReorderAmount` decimal(33,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_product_stock_availability`
-- (See below for the actual view)
--
CREATE TABLE `v_product_stock_availability` (
`ProductID` int(10)
,`ProductName` varchar(100)
,`ProductCategory` enum('SPAGHETTI MEAL','DESSERT','DRINKS & BEVERAGES','PLATTER','RICE MEAL','RICE','Bilao','SNACKS','NOODLES & PASTA')
,`TotalIngredientsNeeded` bigint(21)
,`IngredientsAvailable` bigint(21)
,`StockStatus` varchar(19)
,`MaxServings` decimal(33,0)
);

-- --------------------------------------------------------

--
-- Structure for view `active_online_customers`
--
DROP TABLE IF EXISTS `active_online_customers`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `active_online_customers`  AS SELECT `customers`.`CustomerID` AS `CustomerID`, `customers`.`FirstName` AS `FirstName`, `customers`.`LastName` AS `LastName`, `customers`.`Email` AS `Email`, `customers`.`ContactNumber` AS `ContactNumber`, `customers`.`TotalOrdersCount` AS `TotalOrdersCount`, `customers`.`ReservationCount` AS `ReservationCount`, `customers`.`LastLoginDate` AS `LastLoginDate`, `customers`.`SatisfactionRating` AS `SatisfactionRating` FROM `customers` WHERE `customers`.`CustomerType` = 'Online' AND `customers`.`AccountStatus` = 'Active' ORDER BY `customers`.`LastLoginDate` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `approved_customer_reviews`
--
DROP TABLE IF EXISTS `approved_customer_reviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `approved_customer_reviews`  AS SELECT `cr`.`ReviewID` AS `ReviewID`, `cr`.`CustomerID` AS `CustomerID`, concat(`c`.`FirstName`,' ',left(`c`.`LastName`,1),'.') AS `DisplayName`, `c`.`FirstName` AS `FirstName`, `cr`.`OverallRating` AS `OverallRating`, `cr`.`FoodTasteRating` AS `FoodTasteRating`, `cr`.`PortionSizeRating` AS `PortionSizeRating`, `cr`.`CustomerServiceRating` AS `CustomerServiceRating`, `cr`.`AmbienceRating` AS `AmbienceRating`, `cr`.`CleanlinessRating` AS `CleanlinessRating`, `cr`.`FoodTasteComment` AS `FoodTasteComment`, `cr`.`PortionSizeComment` AS `PortionSizeComment`, `cr`.`CustomerServiceComment` AS `CustomerServiceComment`, `cr`.`AmbienceComment` AS `AmbienceComment`, `cr`.`CleanlinessComment` AS `CleanlinessComment`, `cr`.`GeneralComment` AS `GeneralComment`, `cr`.`CreatedDate` AS `CreatedDate`, `cr`.`ApprovedDate` AS `ApprovedDate` FROM (`customer_reviews` `cr` join `customers` `c` on(`cr`.`CustomerID` = `c`.`CustomerID`)) WHERE `cr`.`Status` = 'Approved' ORDER BY `cr`.`CreatedDate` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `customer_statistics`
--
DROP TABLE IF EXISTS `customer_statistics`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `customer_statistics`  AS SELECT count(distinct `customers`.`CustomerID`) AS `total_customers`, count(case when `customers`.`AccountStatus` = 'Active' then 1 end) AS `active_customers`, count(case when `customers`.`AccountStatus` = 'Suspended' then 1 end) AS `suspended_customers`, count(case when `customers`.`CustomerType` = 'Online' then 1 end) AS `online_customers`, avg(`customers`.`SatisfactionRating`) AS `average_satisfaction`, sum(`customers`.`TotalOrdersCount`) AS `total_orders`, sum(`customers`.`ReservationCount`) AS `total_reservations` FROM `customers` ;

-- --------------------------------------------------------

--
-- Structure for view `expiring_ingredients`
--
DROP TABLE IF EXISTS `expiring_ingredients`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `expiring_ingredients`  AS SELECT `inv`.`InventoryID` AS `InventoryID`, `ing`.`IngredientName` AS `IngredientName`, `inv`.`StockQuantity` AS `StockQuantity`, `inv`.`UnitType` AS `UnitType`, `inv`.`ExpirationDate` AS `ExpirationDate`, to_days(`inv`.`ExpirationDate`) - to_days(curdate()) AS `DaysUntilExpiration`, CASE WHEN `inv`.`ExpirationDate` <= curdate() THEN 'EXPIRED - Remove Immediately' WHEN to_days(`inv`.`ExpirationDate`) - to_days(curdate()) <= 3 THEN 'CRITICAL - Use within 3 days' WHEN to_days(`inv`.`ExpirationDate`) - to_days(curdate()) <= 7 THEN 'WARNING - Use within 7 days' ELSE 'Monitor' END AS `Alert_Level`, `inv`.`Remarks` AS `Remarks` FROM (`inventory` `inv` join `ingredients` `ing` on(`inv`.`IngredientID` = `ing`.`IngredientID`)) WHERE `inv`.`ExpirationDate` is not null AND `inv`.`ExpirationDate` <= curdate() + interval 30 day ORDER BY `inv`.`ExpirationDate` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `inventory_status`
--
DROP TABLE IF EXISTS `inventory_status`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inventory_status`  AS SELECT `inv`.`InventoryID` AS `InventoryID`, `ing`.`IngredientID` AS `IngredientID`, `ing`.`IngredientName` AS `IngredientName`, `inv`.`StockQuantity` AS `StockQuantity`, `inv`.`UnitType` AS `UnitType`, `inv`.`ExpirationDate` AS `ExpirationDate`, CASE WHEN `inv`.`ExpirationDate` is not null AND `inv`.`ExpirationDate` <= curdate() THEN 'Expired' WHEN `inv`.`ExpirationDate` is not null AND `inv`.`ExpirationDate` <= curdate() + interval 3 day THEN 'Expiring Soon (3 days)' WHEN `inv`.`ExpirationDate` is not null AND `inv`.`ExpirationDate` <= curdate() + interval 7 day THEN 'Expiring Soon (7 days)' WHEN `inv`.`StockQuantity` = 0 THEN 'Out of Stock' WHEN `inv`.`StockQuantity` < 5 THEN 'Low Stock' ELSE 'In Stock' END AS `Status`, to_days(`inv`.`ExpirationDate`) - to_days(curdate()) AS `DaysUntilExpiration`, `inv`.`LastRestockedDate` AS `LastRestockedDate`, `inv`.`Remarks` AS `Remarks` FROM (`inventory` `inv` join `ingredients` `ing` on(`inv`.`IngredientID` = `ing`.`IngredientID`)) ORDER BY CASE WHEN `inv`.`ExpirationDate` is not null AND `inv`.`ExpirationDate` <= curdate() THEN 'Expired' WHEN `inv`.`ExpirationDate` is not null AND `inv`.`ExpirationDate` <= curdate() + interval 3 day THEN 'Expiring Soon (3 days)' WHEN `inv`.`ExpirationDate` is not null AND `inv`.`ExpirationDate` <= curdate() + interval 7 day THEN 'Expiring Soon (7 days)' WHEN `inv`.`StockQuantity` = 0 THEN 'Out of Stock' WHEN `inv`.`StockQuantity` < 5 THEN 'Low Stock' ELSE 'In Stock' END ASC, `inv`.`ExpirationDate` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `inventory_transaction_history`
--
DROP TABLE IF EXISTS `inventory_transaction_history`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inventory_transaction_history`  AS SELECT `it`.`TransactionID` AS `TransactionID`, `inv`.`InventoryID` AS `InventoryID`, `ing`.`IngredientName` AS `IngredientName`, `it`.`TransactionType` AS `TransactionType`, `it`.`QuantityChanged` AS `QuantityChanged`, `it`.`StockBefore` AS `StockBefore`, `it`.`StockAfter` AS `StockAfter`, `inv`.`UnitType` AS `UnitType`, `it`.`Notes` AS `Notes`, `it`.`TransactionDate` AS `TransactionDate` FROM ((`inventory_transactions` `it` join `inventory` `inv` on(`it`.`InventoryID` = `inv`.`InventoryID`)) join `ingredients` `ing` on(`inv`.`IngredientID` = `ing`.`IngredientID`)) ORDER BY `it`.`TransactionDate` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `low_stock_items`
--
DROP TABLE IF EXISTS `low_stock_items`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `low_stock_items`  AS SELECT `inv`.`InventoryID` AS `InventoryID`, `ing`.`IngredientName` AS `IngredientName`, `inv`.`StockQuantity` AS `StockQuantity`, `inv`.`UnitType` AS `UnitType`, `inv`.`LastRestockedDate` AS `LastRestockedDate`, to_days(current_timestamp()) - to_days(`inv`.`LastRestockedDate`) AS `DaysSinceLastRestock`, `inv`.`Remarks` AS `Remarks` FROM (`inventory` `inv` join `ingredients` `ing` on(`inv`.`IngredientID` = `ing`.`IngredientID`)) WHERE `inv`.`StockQuantity` < 5 ORDER BY `inv`.`StockQuantity` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `review_statistics`
--
DROP TABLE IF EXISTS `review_statistics`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `review_statistics`  AS SELECT count(0) AS `total_reviews`, count(case when `customer_reviews`.`Status` = 'Approved' then 1 end) AS `approved_reviews`, count(case when `customer_reviews`.`Status` = 'Pending' then 1 end) AS `pending_reviews`, count(case when `customer_reviews`.`Status` = 'Rejected' then 1 end) AS `rejected_reviews`, round(avg(case when `customer_reviews`.`Status` = 'Approved' then `customer_reviews`.`OverallRating` end),2) AS `avg_overall_rating`, round(avg(case when `customer_reviews`.`Status` = 'Approved' then `customer_reviews`.`FoodTasteRating` end),2) AS `avg_food_taste`, round(avg(case when `customer_reviews`.`Status` = 'Approved' then `customer_reviews`.`PortionSizeRating` end),2) AS `avg_portion_size`, round(avg(case when `customer_reviews`.`Status` = 'Approved' then `customer_reviews`.`CustomerServiceRating` end),2) AS `avg_customer_service`, round(avg(case when `customer_reviews`.`Status` = 'Approved' then `customer_reviews`.`AmbienceRating` end),2) AS `avg_ambience`, round(avg(case when `customer_reviews`.`Status` = 'Approved' then `customer_reviews`.`CleanlinessRating` end),2) AS `avg_cleanliness`, count(case when `customer_reviews`.`Status` = 'Approved' and `customer_reviews`.`OverallRating` = 5 then 1 end) AS `five_star_count`, count(case when `customer_reviews`.`Status` = 'Approved' and `customer_reviews`.`OverallRating` >= 4 and `customer_reviews`.`OverallRating` < 5 then 1 end) AS `four_star_count`, count(case when `customer_reviews`.`Status` = 'Approved' and `customer_reviews`.`OverallRating` >= 3 and `customer_reviews`.`OverallRating` < 4 then 1 end) AS `three_star_count`, count(case when `customer_reviews`.`Status` = 'Approved' and `customer_reviews`.`OverallRating` >= 2 and `customer_reviews`.`OverallRating` < 3 then 1 end) AS `two_star_count`, count(case when `customer_reviews`.`Status` = 'Approved' and `customer_reviews`.`OverallRating` >= 1 and `customer_reviews`.`OverallRating` < 2 then 1 end) AS `one_star_count` FROM `customer_reviews` ;

-- --------------------------------------------------------

--
-- Structure for view `v_batch_details`
--
DROP TABLE IF EXISTS `v_batch_details`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_batch_details`  AS SELECT `ib`.`BatchID` AS `BatchID`, `ib`.`BatchNumber` AS `BatchNumber`, `i`.`IngredientID` AS `IngredientID`, `i`.`IngredientName` AS `IngredientName`, `ic`.`CategoryName` AS `CategoryName`, `ib`.`StockQuantity` AS `StockQuantity`, `ib`.`OriginalQuantity` AS `OriginalQuantity`, `ib`.`UnitType` AS `UnitType`, `ib`.`CostPerUnit` AS `CostPerUnit`, `ib`.`TotalCost` AS `TotalCost`, `ib`.`PurchaseDate` AS `PurchaseDate`, `ib`.`ExpirationDate` AS `ExpirationDate`, to_days(`ib`.`ExpirationDate`) - to_days(curdate()) AS `DaysUntilExpiration`, `ib`.`MarketSource` AS `MarketSource`, `ib`.`BatchStatus` AS `BatchStatus`, CASE WHEN `ib`.`BatchStatus` = 'Expired' THEN 'EXPIRED - Remove' WHEN `ib`.`BatchStatus` = 'Depleted' THEN 'Depleted' WHEN `ib`.`ExpirationDate` is null THEN 'No Expiry' WHEN `ib`.`ExpirationDate` <= curdate() THEN 'EXPIRED - Remove Now' WHEN to_days(`ib`.`ExpirationDate`) - to_days(curdate()) <= 3 THEN 'CRITICAL - 3 Days' WHEN to_days(`ib`.`ExpirationDate`) - to_days(curdate()) <= 7 THEN 'WARNING - 7 Days' WHEN to_days(`ib`.`ExpirationDate`) - to_days(curdate()) <= 14 THEN 'Monitor - 14 Days' ELSE 'Fresh' END AS `ExpirationAlert`, round(`ib`.`StockQuantity` / `ib`.`OriginalQuantity` * 100,2) AS `RemainingPercent`, `ib`.`Notes` AS `Notes` FROM ((`inventory_batches` `ib` join `ingredients` `i` on(`ib`.`IngredientID` = `i`.`IngredientID`)) left join `ingredient_categories` `ic` on(`i`.`CategoryID` = `ic`.`CategoryID`)) WHERE `ib`.`BatchStatus` in ('Active','Expired') ORDER BY CASE WHEN `ib`.`ExpirationDate` is null THEN 1 ELSE 0 END ASC, `ib`.`ExpirationDate` ASC, `ib`.`PurchaseDate` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `v_expiring_batches`
--
DROP TABLE IF EXISTS `v_expiring_batches`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_expiring_batches`  AS SELECT `ib`.`BatchID` AS `BatchID`, `ib`.`BatchNumber` AS `BatchNumber`, `i`.`IngredientName` AS `IngredientName`, `ic`.`CategoryName` AS `CategoryName`, `ib`.`StockQuantity` AS `StockQuantity`, `ib`.`UnitType` AS `UnitType`, `ib`.`ExpirationDate` AS `ExpirationDate`, to_days(`ib`.`ExpirationDate`) - to_days(curdate()) AS `DaysLeft`, CASE WHEN `ib`.`ExpirationDate` <= curdate() THEN 'EXPIRED NOW' WHEN to_days(`ib`.`ExpirationDate`) - to_days(curdate()) <= 3 THEN 'CRITICAL' WHEN to_days(`ib`.`ExpirationDate`) - to_days(curdate()) <= 7 THEN 'WARNING' ELSE 'MONITOR' END AS `AlertLevel`, `ib`.`MarketSource` AS `MarketSource` FROM ((`inventory_batches` `ib` join `ingredients` `i` on(`ib`.`IngredientID` = `i`.`IngredientID`)) left join `ingredient_categories` `ic` on(`i`.`CategoryID` = `ic`.`CategoryID`)) WHERE `ib`.`BatchStatus` = 'Active' AND `ib`.`ExpirationDate` is not null AND `ib`.`ExpirationDate` <= curdate() + interval 14 day ORDER BY `ib`.`ExpirationDate` ASC, `i`.`IngredientName` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `v_inventory_summary`
--
DROP TABLE IF EXISTS `v_inventory_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_inventory_summary`  AS SELECT `i`.`IngredientID` AS `IngredientID`, `i`.`IngredientName` AS `IngredientName`, `ic`.`CategoryName` AS `CategoryName`, `i`.`UnitType` AS `DefaultUnit`, coalesce(sum(`ib`.`StockQuantity`),0) AS `TotalStock`, count(case when `ib`.`BatchStatus` = 'Active' then 1 end) AS `ActiveBatches`, min(`ib`.`ExpirationDate`) AS `NextExpiration`, `i`.`MinStockLevel` AS `MinStockLevel`, `i`.`MaxStockLevel` AS `MaxStockLevel`, CASE WHEN coalesce(sum(`ib`.`StockQuantity`),0) = 0 THEN 'Out of Stock' WHEN coalesce(sum(`ib`.`StockQuantity`),0) < `i`.`MinStockLevel` THEN 'Low Stock' WHEN coalesce(sum(`ib`.`StockQuantity`),0) > `i`.`MaxStockLevel` THEN 'Overstocked' ELSE 'In Stock' END AS `StockStatus`, coalesce(sum(`ib`.`StockQuantity` * `ib`.`CostPerUnit`),0) AS `TotalValue` FROM ((`ingredients` `i` left join `ingredient_categories` `ic` on(`i`.`CategoryID` = `ic`.`CategoryID`)) left join `inventory_batches` `ib` on(`i`.`IngredientID` = `ib`.`IngredientID` and `ib`.`BatchStatus` = 'Active')) WHERE `i`.`IsActive` = 1 GROUP BY `i`.`IngredientID`, `i`.`IngredientName`, `ic`.`CategoryName`, `i`.`UnitType`, `i`.`MinStockLevel`, `i`.`MaxStockLevel` ;

-- --------------------------------------------------------

--
-- Structure for view `v_low_stock_items`
--
DROP TABLE IF EXISTS `v_low_stock_items`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_low_stock_items`  AS SELECT `i`.`IngredientID` AS `IngredientID`, `i`.`IngredientName` AS `IngredientName`, `ic`.`CategoryName` AS `CategoryName`, coalesce(sum(`ib`.`StockQuantity`),0) AS `CurrentStock`, `i`.`UnitType` AS `UnitType`, `i`.`MinStockLevel` AS `MinStockLevel`, `i`.`MaxStockLevel` AS `MaxStockLevel`, `i`.`MinStockLevel`- coalesce(sum(`ib`.`StockQuantity`),0) AS `ReorderAmount` FROM ((`ingredients` `i` left join `ingredient_categories` `ic` on(`i`.`CategoryID` = `ic`.`CategoryID`)) left join `inventory_batches` `ib` on(`i`.`IngredientID` = `ib`.`IngredientID` and `ib`.`BatchStatus` = 'Active')) WHERE `i`.`IsActive` = 1 GROUP BY `i`.`IngredientID`, `i`.`IngredientName`, `ic`.`CategoryName`, `i`.`UnitType`, `i`.`MinStockLevel`, `i`.`MaxStockLevel` HAVING coalesce(sum(`ib`.`StockQuantity`),0) < `i`.`MinStockLevel` ORDER BY coalesce(sum(`ib`.`StockQuantity`),0) ASC ;

-- --------------------------------------------------------

--
-- Structure for view `v_product_stock_availability`
--
DROP TABLE IF EXISTS `v_product_stock_availability`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_product_stock_availability`  AS SELECT `p`.`ProductID` AS `ProductID`, `p`.`ProductName` AS `ProductName`, `p`.`Category` AS `ProductCategory`, count(distinct `pi`.`IngredientID`) AS `TotalIngredientsNeeded`, count(distinct case when coalesce(`ib_stock`.`TotalStock`,0) >= `pi`.`QuantityUsed` then `pi`.`IngredientID` end) AS `IngredientsAvailable`, CASE WHEN count(distinct `pi`.`IngredientID`) = count(distinct case when coalesce(`ib_stock`.`TotalStock`,0) >= `pi`.`QuantityUsed` then `pi`.`IngredientID` end) THEN 'Available' WHEN count(distinct case when coalesce(`ib_stock`.`TotalStock`,0) >= `pi`.`QuantityUsed` then `pi`.`IngredientID` end) = 0 THEN 'Out of Stock' ELSE 'Partially Available' END AS `StockStatus`, min(case when coalesce(`ib_stock`.`TotalStock`,0) < `pi`.`QuantityUsed` then floor(coalesce(`ib_stock`.`TotalStock`,0) / `pi`.`QuantityUsed`) else 999999 end) AS `MaxServings` FROM ((`products` `p` left join `product_ingredients` `pi` on(`p`.`ProductID` = `pi`.`ProductID`)) left join (select `inventory_batches`.`IngredientID` AS `IngredientID`,sum(`inventory_batches`.`StockQuantity`) AS `TotalStock` from `inventory_batches` where `inventory_batches`.`BatchStatus` = 'Active' group by `inventory_batches`.`IngredientID`) `ib_stock` on(`pi`.`IngredientID` = `ib_stock`.`IngredientID`)) GROUP BY `p`.`ProductID`, `p`.`ProductName`, `p`.`Category` ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `batch_transactions`
--
ALTER TABLE `batch_transactions`
  ADD PRIMARY KEY (`TransactionID`),
  ADD KEY `idx_batch` (`BatchID`),
  ADD KEY `idx_transaction_type` (`TransactionType`),
  ADD KEY `idx_transaction_date` (`TransactionDate`),
  ADD KEY `idx_reference` (`ReferenceID`),
  ADD KEY `idx_batch_history` (`BatchID`,`TransactionDate`);

--
-- Indexes for table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`CustomerID`),
  ADD UNIQUE KEY `Email` (`Email`),
  ADD UNIQUE KEY `email_unique` (`Email`),
  ADD KEY `idx_customer_type` (`CustomerType`),
  ADD KEY `idx_account_status` (`AccountStatus`),
  ADD KEY `idx_created_date` (`CreatedDate`),
  ADD KEY `idx_last_login` (`LastLoginDate`),
  ADD KEY `idx_customer_type_status` (`CustomerType`,`AccountStatus`),
  ADD KEY `idx_email_status` (`Email`,`AccountStatus`);

--
-- Indexes for table `customers_archive`
--
ALTER TABLE `customers_archive`
  ADD PRIMARY KEY (`CustomerID`),
  ADD UNIQUE KEY `Email` (`Email`),
  ADD UNIQUE KEY `email_unique` (`Email`),
  ADD KEY `idx_customer_type` (`CustomerType`),
  ADD KEY `idx_account_status` (`AccountStatus`),
  ADD KEY `idx_created_date` (`CreatedDate`),
  ADD KEY `idx_last_login` (`LastLoginDate`),
  ADD KEY `idx_customer_type_status` (`CustomerType`,`AccountStatus`),
  ADD KEY `idx_email_status` (`Email`,`AccountStatus`);

--
-- Indexes for table `customer_logs`
--
ALTER TABLE `customer_logs`
  ADD PRIMARY KEY (`LogID`),
  ADD KEY `fk_customer` (`CustomerID`),
  ADD KEY `idx_transaction_type` (`TransactionType`),
  ADD KEY `idx_log_date` (`LogDate`);

--
-- Indexes for table `customer_reviews`
--
ALTER TABLE `customer_reviews`
  ADD PRIMARY KEY (`ReviewID`),
  ADD KEY `idx_customer_id` (`CustomerID`),
  ADD KEY `idx_status` (`Status`),
  ADD KEY `idx_created_date` (`CreatedDate`),
  ADD KEY `idx_overall_rating` (`OverallRating`);

--
-- Indexes for table `employee`
--
ALTER TABLE `employee`
  ADD PRIMARY KEY (`EmployeeID`),
  ADD UNIQUE KEY `Email` (`Email`);

--
-- Indexes for table `gcash_receipts`
--
ALTER TABLE `gcash_receipts`
  ADD PRIMARY KEY (`ReceiptID`),
  ADD KEY `idx_payment_id` (`ReservationPaymentID`),
  ADD KEY `idx_upload_date` (`UploadedDate`),
  ADD KEY `idx_verification_status` (`VerificationStatus`);

--
-- Indexes for table `ingredients`
--
ALTER TABLE `ingredients`
  ADD PRIMARY KEY (`IngredientID`),
  ADD UNIQUE KEY `IngredientName` (`IngredientName`),
  ADD KEY `idx_category` (`CategoryID`),
  ADD KEY `idx_active` (`IsActive`);

--
-- Indexes for table `ingredient_categories`
--
ALTER TABLE `ingredient_categories`
  ADD PRIMARY KEY (`CategoryID`),
  ADD UNIQUE KEY `category_name_unique` (`CategoryName`);

--
-- Indexes for table `inventory`
--
ALTER TABLE `inventory`
  ADD PRIMARY KEY (`InventoryID`),
  ADD UNIQUE KEY `ingredient_unique` (`IngredientID`),
  ADD KEY `idx_stock_quantity` (`StockQuantity`),
  ADD KEY `idx_expiration_date` (`ExpirationDate`),
  ADD KEY `idx_last_restocked` (`LastRestockedDate`);

--
-- Indexes for table `inventory_alerts`
--
ALTER TABLE `inventory_alerts`
  ADD PRIMARY KEY (`AlertID`),
  ADD KEY `IngredientID` (`IngredientID`),
  ADD KEY `BatchID` (`BatchID`),
  ADD KEY `idx_alert_status` (`IsResolved`,`Severity`);

--
-- Indexes for table `inventory_audit_logs`
--
ALTER TABLE `inventory_audit_logs`
  ADD PRIMARY KEY (`AuditID`),
  ADD KEY `BatchID` (`BatchID`);

--
-- Indexes for table `inventory_batches`
--
ALTER TABLE `inventory_batches`
  ADD PRIMARY KEY (`BatchID`),
  ADD UNIQUE KEY `batch_number_unique` (`BatchNumber`),
  ADD KEY `idx_ingredient` (`IngredientID`),
  ADD KEY `idx_expiration` (`ExpirationDate`),
  ADD KEY `idx_batch_status` (`BatchStatus`),
  ADD KEY `idx_purchase_date` (`PurchaseDate`),
  ADD KEY `idx_fifo_priority` (`IngredientID`,`ExpirationDate`,`PurchaseDate`),
  ADD KEY `idx_stock_lookup` (`IngredientID`,`BatchStatus`,`StockQuantity`),
  ADD KEY `idx_storage` (`StorageLocation`);

--
-- Indexes for table `inventory_transactions`
--
ALTER TABLE `inventory_transactions`
  ADD PRIMARY KEY (`TransactionID`),
  ADD KEY `idx_inventory_id` (`InventoryID`),
  ADD KEY `idx_transaction_type` (`TransactionType`),
  ADD KEY `idx_transaction_date` (`TransactionDate`),
  ADD KEY `idx_stock_tracking` (`InventoryID`,`TransactionDate`),
  ADD KEY `idx_transaction_lookup` (`ReferenceID`,`TransactionType`);

--
-- Indexes for table `logs`
--
ALTER TABLE `logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_accounts_id` (`user_accounts_id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`OrderID`),
  ADD UNIQUE KEY `ReceiptNumber` (`ReceiptNumber`),
  ADD UNIQUE KEY `receipt_unique` (`ReceiptNumber`),
  ADD KEY `idx_customer_id` (`CustomerID`),
  ADD KEY `idx_order_date` (`OrderDate`),
  ADD KEY `idx_order_status` (`OrderStatus`);

--
-- Indexes for table `order_ingredient_usage`
--
ALTER TABLE `order_ingredient_usage`
  ADD PRIMARY KEY (`UsageID`),
  ADD KEY `OrderID` (`OrderID`),
  ADD KEY `BatchID` (`BatchID`),
  ADD KEY `IngredientID` (`IngredientID`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`OrderItemID`),
  ADD KEY `idx_order_id` (`OrderID`);

--
-- Indexes for table `payments`
--
ALTER TABLE `payments`
  ADD PRIMARY KEY (`PaymentID`),
  ADD KEY `idx_order_id` (`OrderID`),
  ADD KEY `idx_payment_status` (`PaymentStatus`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`ProductID`),
  ADD UNIQUE KEY `ProductCode` (`ProductCode`);

--
-- Indexes for table `product_ingredients`
--
ALTER TABLE `product_ingredients`
  ADD PRIMARY KEY (`ProductIngredientID`),
  ADD UNIQUE KEY `product_ingredient_unique` (`ProductID`,`IngredientID`),
  ADD KEY `idx_product_id` (`ProductID`),
  ADD KEY `idx_ingredient_id` (`IngredientID`);

--
-- Indexes for table `reservations`
--
ALTER TABLE `reservations`
  ADD PRIMARY KEY (`ReservationID`),
  ADD KEY `idx_customer_id` (`CustomerID`),
  ADD KEY `idx_event_date` (`EventDate`),
  ADD KEY `idx_reservation_status` (`ReservationStatus`);

--
-- Indexes for table `reservation_items`
--
ALTER TABLE `reservation_items`
  ADD PRIMARY KEY (`ReservationItemID`),
  ADD KEY `idx_reservation_id` (`ReservationID`);

--
-- Indexes for table `reservation_payments`
--
ALTER TABLE `reservation_payments`
  ADD PRIMARY KEY (`ReservationPaymentID`),
  ADD KEY `idx_reservation_id` (`ReservationID`),
  ADD KEY `idx_payment_status` (`PaymentStatus`);

--
-- Indexes for table `user_accounts`
--
ALTER TABLE `user_accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `batch_transactions`
--
ALTER TABLE `batch_transactions`
  MODIFY `TransactionID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=95;

--
-- AUTO_INCREMENT for table `customers`
--
ALTER TABLE `customers`
  MODIFY `CustomerID` int(10) NOT NULL AUTO_INCREMENT COMMENT 'Unique identifier for each customer', AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `customers_archive`
--
ALTER TABLE `customers_archive`
  MODIFY `CustomerID` int(10) NOT NULL AUTO_INCREMENT COMMENT 'Unique identifier for each customer', AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `customer_logs`
--
ALTER TABLE `customer_logs`
  MODIFY `LogID` int(10) NOT NULL AUTO_INCREMENT COMMENT 'Unique log identifier', AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `customer_reviews`
--
ALTER TABLE `customer_reviews`
  MODIFY `ReviewID` int(10) NOT NULL AUTO_INCREMENT COMMENT 'Unique review identifier', AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `employee`
--
ALTER TABLE `employee`
  MODIFY `EmployeeID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `gcash_receipts`
--
ALTER TABLE `gcash_receipts`
  MODIFY `ReceiptID` int(10) NOT NULL AUTO_INCREMENT COMMENT 'Unique receipt record ID';

--
-- AUTO_INCREMENT for table `ingredients`
--
ALTER TABLE `ingredients`
  MODIFY `IngredientID` int(10) NOT NULL AUTO_INCREMENT COMMENT 'Unique identifier for each ingredient', AUTO_INCREMENT=142;

--
-- AUTO_INCREMENT for table `ingredient_categories`
--
ALTER TABLE `ingredient_categories`
  MODIFY `CategoryID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT for table `inventory`
--
ALTER TABLE `inventory`
  MODIFY `InventoryID` int(10) NOT NULL AUTO_INCREMENT COMMENT 'Unique inventory record ID', AUTO_INCREMENT=121;

--
-- AUTO_INCREMENT for table `inventory_alerts`
--
ALTER TABLE `inventory_alerts`
  MODIFY `AlertID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=248;

--
-- AUTO_INCREMENT for table `inventory_audit_logs`
--
ALTER TABLE `inventory_audit_logs`
  MODIFY `AuditID` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `inventory_batches`
--
ALTER TABLE `inventory_batches`
  MODIFY `BatchID` int(10) NOT NULL AUTO_INCREMENT COMMENT 'Unique batch identifier', AUTO_INCREMENT=141;

--
-- AUTO_INCREMENT for table `inventory_transactions`
--
ALTER TABLE `inventory_transactions`
  MODIFY `TransactionID` int(10) NOT NULL AUTO_INCREMENT COMMENT 'Unique transaction record ID', AUTO_INCREMENT=121;

--
-- AUTO_INCREMENT for table `logs`
--
ALTER TABLE `logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=106;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `OrderID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1001;

--
-- AUTO_INCREMENT for table `order_ingredient_usage`
--
ALTER TABLE `order_ingredient_usage`
  MODIFY `UsageID` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `OrderItemID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `payments`
--
ALTER TABLE `payments`
  MODIFY `PaymentID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `ProductID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=101;

--
-- AUTO_INCREMENT for table `product_ingredients`
--
ALTER TABLE `product_ingredients`
  MODIFY `ProductIngredientID` int(10) NOT NULL AUTO_INCREMENT COMMENT 'Unique identifier for each product–ingredient link', AUTO_INCREMENT=544;

--
-- AUTO_INCREMENT for table `reservations`
--
ALTER TABLE `reservations`
  MODIFY `ReservationID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `reservation_items`
--
ALTER TABLE `reservation_items`
  MODIFY `ReservationItemID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=54;

--
-- AUTO_INCREMENT for table `reservation_payments`
--
ALTER TABLE `reservation_payments`
  MODIFY `ReservationPaymentID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `user_accounts`
--
ALTER TABLE `user_accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `batch_transactions`
--
ALTER TABLE `batch_transactions`
  ADD CONSTRAINT `batch_transactions_ibfk_1` FOREIGN KEY (`BatchID`) REFERENCES `inventory_batches` (`BatchID`) ON DELETE CASCADE;

--
-- Constraints for table `customer_logs`
--
ALTER TABLE `customer_logs`
  ADD CONSTRAINT `customer_logs_ibfk_1` FOREIGN KEY (`CustomerID`) REFERENCES `customers` (`CustomerID`) ON DELETE CASCADE;

--
-- Constraints for table `customer_reviews`
--
ALTER TABLE `customer_reviews`
  ADD CONSTRAINT `fk_review_customer` FOREIGN KEY (`CustomerID`) REFERENCES `customers` (`CustomerID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `gcash_receipts`
--
ALTER TABLE `gcash_receipts`
  ADD CONSTRAINT `gcash_receipts_ibfk_1` FOREIGN KEY (`ReservationPaymentID`) REFERENCES `reservation_payments` (`ReservationPaymentID`) ON DELETE CASCADE;

--
-- Constraints for table `ingredients`
--
ALTER TABLE `ingredients`
  ADD CONSTRAINT `fk_ingredient_category` FOREIGN KEY (`CategoryID`) REFERENCES `ingredient_categories` (`CategoryID`) ON DELETE SET NULL;

--
-- Constraints for table `inventory`
--
ALTER TABLE `inventory`
  ADD CONSTRAINT `inventory_ibfk_1` FOREIGN KEY (`IngredientID`) REFERENCES `ingredients` (`IngredientID`) ON DELETE CASCADE;

--
-- Constraints for table `inventory_audit_logs`
--
ALTER TABLE `inventory_audit_logs`
  ADD CONSTRAINT `inventory_audit_logs_ibfk_1` FOREIGN KEY (`BatchID`) REFERENCES `inventory_batches` (`BatchID`) ON DELETE CASCADE;

--
-- Constraints for table `inventory_batches`
--
ALTER TABLE `inventory_batches`
  ADD CONSTRAINT `inventory_batches_ibfk_1` FOREIGN KEY (`IngredientID`) REFERENCES `ingredients` (`IngredientID`) ON DELETE CASCADE;

--
-- Constraints for table `inventory_transactions`
--
ALTER TABLE `inventory_transactions`
  ADD CONSTRAINT `inventory_transactions_ibfk_1` FOREIGN KEY (`InventoryID`) REFERENCES `inventory` (`InventoryID`) ON DELETE CASCADE;

--
-- Constraints for table `logs`
--
ALTER TABLE `logs`
  ADD CONSTRAINT `logs_ibfk_1` FOREIGN KEY (`user_accounts_id`) REFERENCES `user_accounts` (`id`);

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`CustomerID`) REFERENCES `customers` (`CustomerID`);

--
-- Constraints for table `order_items`
--
ALTER TABLE `order_items`
  ADD CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE;

--
-- Constraints for table `payments`
--
ALTER TABLE `payments`
  ADD CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`OrderID`) REFERENCES `orders` (`OrderID`) ON DELETE CASCADE;

--
-- Constraints for table `product_ingredients`
--
ALTER TABLE `product_ingredients`
  ADD CONSTRAINT `product_ingredients_ibfk_1` FOREIGN KEY (`ProductID`) REFERENCES `products` (`ProductID`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_ingredients_ibfk_2` FOREIGN KEY (`IngredientID`) REFERENCES `ingredients` (`IngredientID`) ON DELETE CASCADE;

--
-- Constraints for table `reservations`
--
ALTER TABLE `reservations`
  ADD CONSTRAINT `reservations_ibfk_1` FOREIGN KEY (`CustomerID`) REFERENCES `customers` (`CustomerID`);

--
-- Constraints for table `reservation_items`
--
ALTER TABLE `reservation_items`
  ADD CONSTRAINT `reservation_items_ibfk_1` FOREIGN KEY (`ReservationID`) REFERENCES `reservations` (`ReservationID`) ON DELETE CASCADE;

--
-- Constraints for table `reservation_payments`
--
ALTER TABLE `reservation_payments`
  ADD CONSTRAINT `reservation_payments_ibfk_1` FOREIGN KEY (`ReservationID`) REFERENCES `reservations` (`ReservationID`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
