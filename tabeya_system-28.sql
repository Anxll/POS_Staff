-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 30, 2025 at 05:46 PM
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
    DECLARE v_ingredient_name VARCHAR(100);
    DECLARE v_batch_count INT;
    DECLARE v_date_code VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_batch_id = -1;
        SET p_batch_number = 'ERROR';
    END;

    START TRANSACTION;

    -- =========================================
    -- Generate batch code
    -- =========================================
    SELECT 
        UPPER(LEFT(REPLACE(IngredientName, ' ', ''), 3)),
        IngredientName
    INTO 
        v_ingredient_code,
        v_ingredient_name
    FROM ingredients
    WHERE IngredientID = p_ingredient_id;

    SELECT COUNT(*) + 1
    INTO v_batch_count
    FROM inventory_batches
    WHERE IngredientID = p_ingredient_id;

    SET v_date_code = DATE_FORMAT(NOW(), '%Y%m%d');
    SET p_batch_number = CONCAT(
        v_ingredient_code, '-', v_date_code, '-', LPAD(v_batch_count, 3, '0')
    );

    -- =========================================
    -- Insert batch record
    -- =========================================
    INSERT INTO inventory_batches (
        IngredientID, BatchNumber, StockQuantity, OriginalQuantity,
        UnitType, CostPerUnit, PurchaseDate, ExpirationDate,
        StorageLocation, BatchStatus, Notes
    ) VALUES (
        p_ingredient_id, p_batch_number, p_quantity, p_quantity,
        p_unit_type, p_cost_per_unit, NOW(), p_expiration_date,
        COALESCE(NULLIF(p_storage_location, ''), 'Pantry-Dry-Goods'),
        'Active', p_notes
    );

    SET p_batch_id = LAST_INSERT_ID();

    -- =========================================
    -- Insert Movement Log (GLOBAL STOCK)
    -- =========================================
    CALL InsertInventoryMovement(
        p_ingredient_id,
        p_batch_id,
        'ADD',
        p_quantity,
        p_unit_type,
        'New Batch Purchase',
        'ADMIN',
        NULL,
        'Admin User',
        NULL,
        NULL,
        p_batch_number,
        CONCAT(
            'New batch created: ', p_batch_number,
            ' | ', v_ingredient_name,
            ' | Qty: ', p_quantity, ' ', p_unit_type,
            ' | Cost: ₱', p_cost_per_unit,
            IF(p_notes IS NOT NULL AND p_notes <> '', CONCAT(' | Notes: ', p_notes), '')
        )
    );

    -- =========================================
    -- Update total ingredient stock
    -- =========================================
    UPDATE ingredients
    SET 
        StockQuantity = StockQuantity + p_quantity,
        LastRestockedDate = NOW()
    WHERE IngredientID = p_ingredient_id;

    COMMIT;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ClearMovementHistory` (IN `p_ingredient_id` INT, IN `p_before_date` DATE)   BEGIN
    DECLARE v_rows_deleted INT;
    
    START TRANSACTION;
    
    IF p_ingredient_id IS NULL THEN
        -- Clear all history before specified date
        DELETE FROM inventory_movement_log
        WHERE DATE(MovementDate) < p_before_date;
    ELSE
        -- Clear specific ingredient history before specified date
        DELETE FROM inventory_movement_log
        WHERE IngredientID = p_ingredient_id
        AND DATE(MovementDate) < p_before_date;
    END IF;
    
    SET v_rows_deleted = ROW_COUNT();
    
    COMMIT;
    
    SELECT v_rows_deleted AS RowsDeleted;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeductIngredientsForPOSOrder` (IN `p_order_id` INT)   BEGIN
    DECLARE v_product_name VARCHAR(100);
    DECLARE v_quantity INT;
    DECLARE v_ingredient_id INT;
    DECLARE v_ingredient_name VARCHAR(100);
    DECLARE v_quantity_needed DECIMAL(10,2);
    DECLARE v_unit_type VARCHAR(50);
    DECLARE v_remaining_needed DECIMAL(10,2);
    DECLARE v_batch_id INT;
    DECLARE v_batch_number VARCHAR(50);
    DECLARE v_batch_stock DECIMAL(10,2);
    DECLARE v_batch_expiration DATE;
    DECLARE v_deduct_amount DECIMAL(10,2);
    DECLARE v_stock_before DECIMAL(10,2);
    DECLARE v_stock_after DECIMAL(10,2);
    DECLARE v_employee_id INT;
    DECLARE v_employee_name VARCHAR(150);
    DECLARE v_receipt_number VARCHAR(20);
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE item_cursor CURSOR FOR
        SELECT ProductName, Quantity
        FROM order_items
        WHERE OrderID = p_order_id;
    
    DECLARE ingredient_cursor CURSOR FOR
        SELECT pi.IngredientID, i.IngredientName, pi.QuantityUsed, pi.UnitType
        FROM product_ingredients pi
        INNER JOIN products p ON pi.ProductID = p.ProductID
        INNER JOIN ingredients i ON pi.IngredientID = i.IngredientID
        WHERE p.ProductName = v_product_name;
    
    DECLARE batch_cursor CURSOR FOR
        SELECT BatchID, BatchNumber, StockQuantity, ExpirationDate
        FROM inventory_batches
        WHERE IngredientID = v_ingredient_id
        AND BatchStatus = 'Active'
        AND StockQuantity > 0
        ORDER BY 
            CASE WHEN ExpirationDate IS NULL THEN 1 ELSE 0 END,
            ExpirationDate ASC,
            PurchaseDate ASC
        FOR UPDATE;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- UPDATED: Removed ROLLBACK
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        RESIGNAL; -- rethrow error but no rollback
    END;
    
    -- REMOVED: START TRANSACTION;

    -- Get employee information
    SELECT o.EmployeeID, COALESCE(CONCAT(e.FirstName, ' ', e.LastName), 'POS User'), o.ReceiptNumber
    INTO v_employee_id, v_employee_name, v_receipt_number
    FROM orders o
    LEFT JOIN employee e ON o.EmployeeID = e.EmployeeID
    WHERE o.OrderID = p_order_id;
    
    IF v_receipt_number IS NULL THEN
        SET v_receipt_number = CONCAT('ORD-', p_order_id);
    END IF;

    OPEN item_cursor;
    item_loop: LOOP
        FETCH item_cursor INTO v_product_name, v_quantity;
        IF done THEN LEAVE item_loop; END IF;

        SET done = FALSE;
        OPEN ingredient_cursor;
        ingredient_loop:LOOP
            FETCH ingredient_cursor INTO v_ingredient_id, v_ingredient_name, v_quantity_needed, v_unit_type;
            IF done THEN LEAVE ingredient_loop; END IF;

            SET v_remaining_needed = v_quantity_needed * v_quantity;

            SET done = FALSE;
            OPEN batch_cursor;
            batch_loop: LOOP
                FETCH batch_cursor INTO v_batch_id, v_batch_number, v_batch_stock, v_batch_expiration;
                IF done OR v_remaining_needed <= 0 THEN LEAVE batch_loop; END IF;

                IF v_batch_stock >= v_remaining_needed THEN
                    SET v_deduct_amount = v_remaining_needed;
                ELSE
                    SET v_deduct_amount = v_batch_stock;
                END IF;

                SET v_stock_before = v_batch_stock;
                SET v_stock_after = v_batch_stock - v_deduct_amount;

                UPDATE inventory_batches
                SET StockQuantity = v_stock_after,
                    BatchStatus = CASE 
                        WHEN v_stock_after = 0 THEN 'Depleted'
                        ELSE BatchStatus
                    END
                WHERE BatchID = v_batch_id;

                INSERT INTO batch_transactions (
                    BatchID, TransactionType, QuantityChanged, StockBefore, StockAfter,
                    ReferenceID, PerformedBy, Reason, Notes, TransactionDate
                ) VALUES (
                    v_batch_id, 'Usage', -v_deduct_amount, v_stock_before, v_stock_after,
                    v_receipt_number, v_employee_name, 'POS Order',
                    CONCAT('Deducted for order #', p_order_id, ' - ', v_product_name, 
                           ' (', v_quantity, ' units) by ', v_employee_name), NOW()
                );

                CALL LogInventoryMovement(
                    v_ingredient_id,
                    v_batch_id,
                    'DEDUCT',
                    -v_deduct_amount,
                    v_stock_before,
                    v_stock_after,
                    v_unit_type,
                    CONCAT('POS Order - ', v_product_name),
                    'POS',
                    v_employee_id,
                    v_employee_name,
                    p_order_id,
                    NULL,
                    v_receipt_number,
                    CONCAT('Batch: ', v_batch_number, ' | Product: ', v_product_name, 
                           ' (Qty: ', v_quantity, ') | Ingredient: ', v_ingredient_name,
                           ' | Receipt: ', v_receipt_number)
                );

                SET v_remaining_needed = v_remaining_needed - v_deduct_amount;

            END LOOP batch_loop;
            CLOSE batch_cursor;

            UPDATE ingredients
            SET StockQuantity = (
                SELECT COALESCE(SUM(StockQuantity), 0)
                FROM inventory_batches
                WHERE IngredientID = v_ingredient_id
                AND BatchStatus = 'Active'
            )
            WHERE IngredientID = v_ingredient_id;

            SET done = FALSE;
        END LOOP ingredient_loop;
        CLOSE ingredient_cursor;

        SET done = FALSE;
    END LOOP item_loop;
    CLOSE item_cursor;

    -- REMOVED: COMMIT;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeductIngredientsForReservation` (IN `p_reservation_id` INT)   BEGIN
    DECLARE v_product_name VARCHAR(100);
    DECLARE v_quantity INT;
    DECLARE v_ingredient_id INT;
    DECLARE v_ingredient_name VARCHAR(100);
    DECLARE v_quantity_needed DECIMAL(10,2);
    DECLARE v_unit_type VARCHAR(50);
    DECLARE v_remaining_needed DECIMAL(10,2);
    DECLARE v_batch_id INT;
    DECLARE v_batch_number VARCHAR(50);
    DECLARE v_batch_stock DECIMAL(10,2);
    DECLARE v_batch_expiration DATE;
    DECLARE v_deduct_amount DECIMAL(10,2);
    DECLARE v_stock_before DECIMAL(10,2);
    DECLARE v_stock_after DECIMAL(10,2);
    DECLARE v_customer_id INT;
    DECLARE v_customer_name VARCHAR(150);
    DECLARE v_reference_number VARCHAR(50);
    DECLARE done INT DEFAULT FALSE;
    
    -- Cursor for reservation items
    DECLARE item_cursor CURSOR FOR
        SELECT ProductName, Quantity
        FROM reservation_items
        WHERE ReservationID = p_reservation_id;
    
    -- Cursor for product ingredients
    DECLARE ingredient_cursor CURSOR FOR
        SELECT pi.IngredientID, i.IngredientName, pi.QuantityUsed, pi.UnitType
        FROM product_ingredients pi
        INNER JOIN products p ON pi.ProductID = p.ProductID
        INNER JOIN ingredients i ON pi.IngredientID = i.IngredientID
        WHERE p.ProductName = v_product_name;
    
    -- Cursor for inventory batches (FIFO)
    DECLARE batch_cursor CURSOR FOR
        SELECT BatchID, BatchNumber, StockQuantity, ExpirationDate
        FROM inventory_batches
        WHERE IngredientID = v_ingredient_id
        AND BatchStatus = 'Active'
        AND StockQuantity > 0
        ORDER BY 
            CASE WHEN ExpirationDate IS NULL THEN 1 ELSE 0 END,
            ExpirationDate ASC,
            PurchaseDate ASC
        FOR UPDATE;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- *** CHANGED: Removed ROLLBACK ***
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- No rollback (removed)
        RESIGNAL; -- Still rethrow the error
    END;

    -- Removed START TRANSACTION;

    -- Get customer information
    SELECT c.CustomerID, CONCAT(c.FirstName, ' ', c.LastName)
    INTO v_customer_id, v_customer_name
    FROM reservations r
    INNER JOIN customers c ON r.CustomerID = c.CustomerID
    WHERE r.ReservationID = p_reservation_id;

    SET v_reference_number = CONCAT('RES-', p_reservation_id);

    -- Loop through reservation items
    OPEN item_cursor;
    item_loop: LOOP
        FETCH item_cursor INTO v_product_name, v_quantity;
        IF done THEN LEAVE item_loop; END IF;

        SET done = FALSE;
        OPEN ingredient_cursor;
        ingredient_loop:LOOP
            FETCH ingredient_cursor INTO v_ingredient_id, v_ingredient_name, v_quantity_needed, v_unit_type;
            IF done THEN LEAVE ingredient_loop; END IF;

            SET v_remaining_needed = v_quantity_needed * v_quantity;

            SET done = FALSE;
            OPEN batch_cursor;
            batch_loop: LOOP
                FETCH batch_cursor INTO v_batch_id, v_batch_number, v_batch_stock, v_batch_expiration;
                IF done OR v_remaining_needed <= 0 THEN LEAVE batch_loop; END IF;

                IF v_batch_stock >= v_remaining_needed THEN
                    SET v_deduct_amount = v_remaining_needed;
                ELSE
                    SET v_deduct_amount = v_batch_stock;
                END IF;

                SET v_stock_before = v_batch_stock;
                SET v_stock_after = v_batch_stock - v_deduct_amount;

                UPDATE inventory_batches
                SET StockQuantity = v_stock_after,
                    BatchStatus = CASE 
                        WHEN v_stock_after = 0 THEN 'Depleted'
                        ELSE BatchStatus
                    END
                WHERE BatchID = v_batch_id;

                INSERT INTO batch_transactions (
                    BatchID, TransactionType, QuantityChanged, StockBefore, StockAfter,
                    ReferenceID, PerformedBy, Reason, Notes, TransactionDate
                ) VALUES (
                    v_batch_id, 'Usage', -v_deduct_amount, v_stock_before, v_stock_after,
                    v_reference_number, 'System', 'Reservation Confirmed',
                    CONCAT('Deducted for reservation #', p_reservation_id, ' - ', v_product_name,
                           ' (', v_quantity, ' units) by ', v_customer_name), NOW()
                );

                CALL LogInventoryMovement(
                    v_ingredient_id,
                    v_batch_id,
                    'DEDUCT',
                    -v_deduct_amount,
                    v_stock_before,
                    v_stock_after,
                    v_unit_type,
                    CONCAT('Website Reservation Confirmed - ', v_product_name),
                    'WEBSITE',
                    v_customer_id,
                    v_customer_name,
                    NULL,
                    p_reservation_id,
                    v_reference_number,
                    CONCAT('Batch: ', v_batch_number, ' | Product: ', v_product_name,
                           ' (Qty: ', v_quantity, ') | Ingredient: ', v_ingredient_name)
                );

                SET v_remaining_needed = v_remaining_needed - v_deduct_amount;

            END LOOP batch_loop;
            CLOSE batch_cursor;

            UPDATE ingredients
            SET StockQuantity = (
                SELECT COALESCE(SUM(StockQuantity), 0)
                FROM inventory_batches
                WHERE IngredientID = v_ingredient_id
                AND BatchStatus = 'Active'
            )
            WHERE IngredientID = v_ingredient_id;

            SET done = FALSE;
        END LOOP ingredient_loop;
        CLOSE ingredient_cursor;

        SET done = FALSE;
    END LOOP item_loop;
    CLOSE item_cursor;

    -- Removed COMMIT;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DiscardBatch` (IN `p_batch_id` INT, IN `p_reason` VARCHAR(255), IN `p_notes` TEXT)   BEGIN
    DECLARE v_ingredient_id INT;
    DECLARE v_ingredient_name VARCHAR(100);
    DECLARE v_batch_number VARCHAR(50);
    DECLARE v_batch_stock DECIMAL(10,2);
    DECLARE v_unit_type VARCHAR(50);

    DECLARE v_global_before DECIMAL(10,2) DEFAULT 0;
    DECLARE v_global_after DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- ==========================================
    -- 1. GET BATCH DETAILS BEFORE DISCARD
    -- ==========================================
    SELECT 
        ib.IngredientID,
        i.IngredientName,
        ib.BatchNumber,
        ib.StockQuantity,
        ib.UnitType
    INTO 
        v_ingredient_id,
        v_ingredient_name,
        v_batch_number,
        v_batch_stock,
        v_unit_type
    FROM inventory_batches ib
    INNER JOIN ingredients i ON ib.IngredientID = i.IngredientID
    WHERE ib.BatchID = p_batch_id;

    -- ==========================================
    -- 2. GET LATEST GLOBAL STOCK BEFORE MOVEMENT
    -- ==========================================
    SELECT StockAfter
    INTO v_global_before
    FROM inventory_movement_log
    WHERE IngredientID = v_ingredient_id
    ORDER BY MovementID DESC
    LIMIT 1;

    IF v_global_before IS NULL THEN 
        SET v_global_before = 0;
    END IF;

    SET v_global_after = v_global_before - v_batch_stock;

    -- ==========================================
    -- 3. UPDATE BATCH → SET TO 0 AND DISCARDED
    -- ==========================================
    UPDATE inventory_batches
    SET BatchStatus = 'Discarded',
        StockQuantity = 0,
        UpdatedDate = NOW()
    WHERE BatchID = p_batch_id;

    -- ==========================================
    -- 4. LOG TO batch_transactions (OLD SYSTEM)
    -- ==========================================
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
        'Discard',
        -v_batch_stock,
        v_batch_stock,
        0,
        NULL,
        'System User',
        COALESCE(p_reason, 'Manual Discard'),
        COALESCE(p_notes, CONCAT('Batch ', v_batch_number, ' discarded.')),
        NOW()
    );

    -- ==========================================
    -- 5. LOG TO inventory_movement_log (GLOBAL)
    -- ==========================================
    INSERT INTO inventory_movement_log (
        IngredientID,
        BatchID,
        ChangeType,
        QuantityChanged,
        StockBefore,
        StockAfter,
        UnitType,
        Reason,
        Source,
        SourceID,
        SourceName,
        OrderID,
        ReservationID,
        ReferenceNumber,
        Notes,
        MovementDate
    ) VALUES (
        v_ingredient_id,
        p_batch_id,
        'DISCARD',
        -v_batch_stock,
        v_global_before,
        v_global_after,
        v_unit_type,
        COALESCE(p_reason, 'Batch Discarded'),
        'ADMIN',
        NULL,
        'Admin User',
        NULL,
        NULL,
        v_batch_number,
        CONCAT(
            'Batch Discarded: ', v_ingredient_name,
            ' | Batch: ', v_batch_number,
            ' | Quantity Removed: ', FORMAT(v_batch_stock, 2), ' ', v_unit_type,
            COALESCE(CONCAT(' | Reason: ', p_reason), ''),
            COALESCE(CONCAT(' | Notes: ', p_notes), '')
        ),
        NOW()
    );

    -- ==========================================
    -- 6. UPDATE INGREDIENT TOTAL STOCK
    -- ==========================================
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `GenerateBatchesWithLogging` ()   BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_ing INT;
    DECLARE v_unit VARCHAR(50);

    DECLARE cur CURSOR FOR 
        SELECT IngredientID, UnitType 
        FROM ingredients 
        WHERE IsActive = 1;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;

    batch_loop: LOOP
        FETCH cur INTO v_ing, v_unit;
        IF done THEN LEAVE batch_loop; END IF;

        -- Call your AddInventoryBatch and let it handle logging
        CALL AddInventoryBatch(
            v_ing,                    -- Ingredient ID
            50,                       -- Stock qty
            v_unit,                   -- Unit Type
            10 + RAND() * 40,         -- Random cost 10–50
            DATE_ADD(CURDATE(), INTERVAL FLOOR(RAND()*25 + 5) DAY), -- random expiry
            'AutoGen',                -- Storage
            'Auto-generated batch',   -- Notes
            @batch_id,
            @batch_number
        );
    END LOOP;

    CLOSE cur;
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

CREATE DEFINER=`root`@`localhost` PROCEDURE `GetInventoryMovementHistory` (IN `p_ingredient_id` INT, IN `p_start_date` DATE, IN `p_end_date` DATE, IN `p_source` VARCHAR(20), IN `p_change_type` VARCHAR(20))   BEGIN
    SELECT 
        MovementID,
        MovementDate,
        IngredientName,
        CategoryName,
        BatchNumber,
        ChangeType,
        QuantityChanged,
        UnitType,
        StockBefore,
        StockAfter,
        Reason,
        Source,
        SourceName,
        OrderID,
        ReservationID,
        ReferenceNumber,
        Notes,
        StorageLocation,
        ExpirationDate
    FROM inventory_movement_details
    WHERE 
        (p_ingredient_id IS NULL OR IngredientID = p_ingredient_id)
        AND (p_start_date IS NULL OR DATE(MovementDate) >= p_start_date)
        AND (p_end_date IS NULL OR DATE(MovementDate) <= p_end_date)
        AND (p_source IS NULL OR Source = p_source)
        AND (p_change_type IS NULL OR ChangeType = p_change_type)
    ORDER BY MovementDate DESC
    LIMIT 1000;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `InsertInventoryMovement` (IN `p_ingredient_id` INT, IN `p_batch_id` INT, IN `p_change_type` VARCHAR(50), IN `p_quantity_changed` DECIMAL(10,2), IN `p_unit_type` VARCHAR(10), IN `p_reason` VARCHAR(255), IN `p_source` VARCHAR(50), IN `p_source_id` INT, IN `p_source_name` VARCHAR(255), IN `p_order_id` INT, IN `p_reservation_id` INT, IN `p_reference_number` VARCHAR(255), IN `p_notes` TEXT)   BEGIN
    DECLARE v_stock_before DECIMAL(10,2) DEFAULT 0;
    DECLARE v_stock_after  DECIMAL(10,2) DEFAULT 0;

    -- GET LAST STOCK OF INGREDIENT (GLOBAL)
    SELECT StockAfter
    INTO v_stock_before
    FROM inventory_movement_log
    WHERE IngredientID = p_ingredient_id
    ORDER BY MovementDate DESC, MovementID DESC
    LIMIT 1;

    SET v_stock_before = IFNULL(v_stock_before, 0);

    -- Compute new stock
    SET v_stock_after = v_stock_before + p_quantity_changed;

    -- Prevent negative stock
    IF v_stock_after < 0 THEN 
        SET v_stock_after = 0;
    END IF;

    -- INSERT MOVEMENT LOG ENTRY
    INSERT INTO inventory_movement_log (
        IngredientID,
        BatchID,
        ChangeType,
        QuantityChanged,
        StockBefore,
        StockAfter,
        UnitType,
        Reason,
        Source,
        SourceID,
        SourceName,
        OrderID,
        ReservationID,
        ReferenceNumber,
        Notes,
        MovementDate
    )
    VALUES (
        p_ingredient_id,
        p_batch_id,
        p_change_type,
        p_quantity_changed,
        v_stock_before,
        v_stock_after,
        p_unit_type,
        p_reason,
        p_source,
        p_source_id,
        p_source_name,
        p_order_id,
        p_reservation_id,
        p_reference_number,
        p_notes,
        NOW()
    );

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `LogBatchEdit` (IN `p_batch_id` INT, IN `p_ingredient_id` INT, IN `p_old_quantity` DECIMAL(10,2), IN `p_new_quantity` DECIMAL(10,2), IN `p_unit_type` VARCHAR(50), IN `p_batch_number` VARCHAR(50), IN `p_ingredient_name` VARCHAR(100), IN `p_reason` VARCHAR(255), IN `p_notes` TEXT)   BEGIN
    DECLARE v_quantity_change DECIMAL(10,2);
    DECLARE v_change_type VARCHAR(20);
    DECLARE v_stock_before DECIMAL(10,2);
    DECLARE v_stock_after DECIMAL(10,2);

    -- Compute difference
    SET v_quantity_change = p_new_quantity - p_old_quantity;

    IF v_quantity_change <> 0 THEN

        SET v_change_type = 'ADJUST';

        -- ==========================================
        -- GET LAST GLOBAL STOCK
        -- ==========================================
        SELECT StockAfter
        INTO v_stock_before
        FROM inventory_movement_log
        WHERE IngredientID = p_ingredient_id
        ORDER BY MovementID DESC
        LIMIT 1;

        SET v_stock_before = IFNULL(v_stock_before, 0);

        -- New total stock
        SET v_stock_after = v_stock_before + v_quantity_change;

        -- ==========================================
        -- INSERT MOVEMENT LOG
        -- ==========================================
        INSERT INTO inventory_movement_log (
            IngredientID,
            BatchID,
            ChangeType,
            QuantityChanged,
            StockBefore,
            StockAfter,
            UnitType,
            Reason,
            Source,
            SourceID,
            SourceName,
            OrderID,
            ReservationID,
            ReferenceNumber,
            Notes,
            MovementDate
        ) VALUES (
            p_ingredient_id,
            p_batch_id,
            v_change_type,
            v_quantity_change,
            v_stock_before,
            v_stock_after,
            p_unit_type,
            p_reason,
            'ADMIN',
            NULL,
            'Admin User',
            NULL,
            NULL,
            p_batch_number,
            CONCAT(
                'Batch Edit: ', p_ingredient_name,
                ' | Previous: ', p_old_quantity, ' ', p_unit_type,
                ' | New: ', p_new_quantity, ' ', p_unit_type,
                ' | Change: ', v_quantity_change, ' ', p_unit_type,
                IF(p_notes IS NOT NULL AND p_notes <> '',
                    CONCAT(' | Notes: ', p_notes),
                    ''
                )
            ),
            NOW()
        );

        -- ==========================================
        -- UPDATE INGREDIENT TOTAL STOCK
        -- ==========================================
        UPDATE ingredients
        SET StockQuantity = v_stock_after
        WHERE IngredientID = p_ingredient_id;

    END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `LogInventoryMovement` (IN `p_ingredient_id` INT, IN `p_batch_id` INT, IN `p_change_type` ENUM('ADD','DEDUCT','ADJUST','DISCARD','TRANSFER'), IN `p_quantity_changed` DECIMAL(10,2), IN `p_stock_before` DECIMAL(10,2), IN `p_stock_after` DECIMAL(10,2), IN `p_unit_type` VARCHAR(50), IN `p_reason` VARCHAR(255), IN `p_source` ENUM('POS','WEBSITE','ADMIN','SYSTEM'), IN `p_source_id` INT, IN `p_source_name` VARCHAR(100), IN `p_order_id` INT, IN `p_reservation_id` INT, IN `p_reference_number` VARCHAR(50), IN `p_notes` TEXT)   BEGIN
    INSERT INTO inventory_movement_log (
        IngredientID,
        BatchID,
        ChangeType,
        QuantityChanged,
        StockBefore,
        StockAfter,
        UnitType,
        Reason,
        Source,
        SourceID,
        SourceName,
        OrderID,
        ReservationID,
        ReferenceNumber,
        Notes,
        MovementDate
    ) VALUES (
        p_ingredient_id,
        p_batch_id,
        p_change_type,
        p_quantity_changed,
        p_stock_before,
        p_stock_after,
        p_unit_type,
        p_reason,
        p_source,
        p_source_id,
        p_source_name,
        p_order_id,
        p_reservation_id,
        p_reference_number,
        p_notes,
        NOW()
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateBatchStock` (IN `p_batch_id` INT, IN `p_quantity_change` DECIMAL(10,2), IN `p_transaction_type` ENUM('Purchase','Usage','Adjustment','Discard','Transfer'), IN `p_reference_id` VARCHAR(50), IN `p_performed_by` VARCHAR(100), IN `p_reason` VARCHAR(255), IN `p_notes` TEXT)   BEGIN
    DECLARE v_ingredient_id INT;
    DECLARE v_ingredient_name VARCHAR(100);
    DECLARE v_unit_type VARCHAR(50);
    DECLARE v_stock_before DECIMAL(10,2);
    DECLARE v_stock_after DECIMAL(10,2);
    DECLARE v_change_type VARCHAR(20);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    -- Get current stock and ingredient info
    SELECT ib.IngredientID, ib.StockQuantity, ib.UnitType, i.IngredientName
    INTO v_ingredient_id, v_stock_before, v_unit_type, v_ingredient_name
    FROM inventory_batches ib
    INNER JOIN ingredients i ON ib.IngredientID = i.IngredientID
    WHERE ib.BatchID = p_batch_id;
    
    -- Calculate new stock
    SET v_stock_after = v_stock_before + p_quantity_change;
    
    -- Prevent negative stock
    IF v_stock_after < 0 THEN
        SET v_stock_after = 0;
    END IF;
    
    -- Determine change type for movement log
    SET v_change_type = CASE 
        WHEN p_transaction_type = 'Purchase' THEN 'ADD'
        WHEN p_transaction_type = 'Usage' THEN 'DEDUCT'
        WHEN p_transaction_type = 'Adjustment' THEN 'ADJUST'
        WHEN p_transaction_type = 'Discard' THEN 'DISCARD'
        WHEN p_transaction_type = 'Transfer' THEN 'TRANSFER'
        ELSE 'ADJUST'
    END;
    
    -- Update batch stock
    UPDATE inventory_batches
    SET StockQuantity = v_stock_after,
        BatchStatus = CASE 
            WHEN v_stock_after = 0 THEN 'Depleted'
            WHEN ExpirationDate IS NOT NULL AND ExpirationDate <= CURDATE() THEN 'Expired'
            ELSE 'Active'
        END
    WHERE BatchID = p_batch_id;
    
    -- Log in batch_transactions (existing)
    INSERT INTO batch_transactions (
        BatchID, TransactionType, QuantityChanged, StockBefore, StockAfter,
        ReferenceID, PerformedBy, Reason, Notes, TransactionDate
    ) VALUES (
        p_batch_id, p_transaction_type, p_quantity_change, v_stock_before, v_stock_after,
        p_reference_id, p_performed_by, p_reason, p_notes, NOW()
    );
    
    -- *** NEW: Log in inventory_movement_log ***
    CALL LogInventoryMovement(
        v_ingredient_id,
        p_batch_id,
        v_change_type,
        p_quantity_change,
        v_stock_before,
        v_stock_after,
        v_unit_type,
        p_reason,
        'ADMIN',
        NULL,
        COALESCE(p_performed_by, 'Admin User'),
        NULL,
        NULL,
        p_reference_id,
        CONCAT('Manual adjustment: ', v_ingredient_name, 
               ' | Reason: ', p_reason,
               COALESCE(CONCAT(' | Notes: ', p_notes), ''))
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
-- Table structure for table `active_online_customers`
--

CREATE TABLE `active_online_customers` (
  `CustomerID` int(10) DEFAULT NULL,
  `FirstName` varchar(50) DEFAULT NULL,
  `LastName` varchar(50) DEFAULT NULL,
  `Email` varchar(100) DEFAULT NULL,
  `ContactNumber` varchar(20) DEFAULT NULL,
  `TotalOrdersCount` int(10) DEFAULT NULL,
  `ReservationCount` int(10) DEFAULT NULL,
  `LastLoginDate` datetime DEFAULT NULL,
  `SatisfactionRating` decimal(3,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `approved_customer_reviews`
--

CREATE TABLE `approved_customer_reviews` (
  `ReviewID` int(10) DEFAULT NULL,
  `CustomerID` int(10) DEFAULT NULL,
  `DisplayName` varchar(53) DEFAULT NULL,
  `FirstName` varchar(50) DEFAULT NULL,
  `OverallRating` decimal(2,1) DEFAULT NULL,
  `FoodTasteRating` int(1) DEFAULT NULL,
  `PortionSizeRating` int(1) DEFAULT NULL,
  `CustomerServiceRating` int(1) DEFAULT NULL,
  `AmbienceRating` int(1) DEFAULT NULL,
  `CleanlinessRating` int(1) DEFAULT NULL,
  `FoodTasteComment` text DEFAULT NULL,
  `PortionSizeComment` text DEFAULT NULL,
  `CustomerServiceComment` text DEFAULT NULL,
  `AmbienceComment` text DEFAULT NULL,
  `CleanlinessComment` text DEFAULT NULL,
  `GeneralComment` text DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `ApprovedDate` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
(94, 139, 'Adjustment', -20.00, 34.00, 14.00, NULL, NULL, 'Manual Edit', 'Batch edited by user', '2025-11-27 13:16:28'),
(0, 141, 'Purchase', 56.00, 0.00, 56.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-29. 5634535', '2025-11-29 02:16:22'),
(0, 141, 'Adjustment', -36.00, 56.00, 20.00, NULL, NULL, 'Manual Edit', 'Batch edited by user', '2025-11-29 02:38:52'),
(0, 142, 'Purchase', 56.00, 0.00, 56.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-29. e34545', '2025-11-29 02:55:14'),
(0, 143, 'Purchase', 5.00, 0.00, 5.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-29. weererer', '2025-11-29 03:08:20'),
(0, 144, 'Purchase', 4.00, 0.00, 4.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-29. 4545', '2025-11-29 03:09:44'),
(0, 142, 'Adjustment', -46.00, 56.00, 10.00, NULL, NULL, 'Manual Edit', 'Batch edited by user', '2025-11-29 12:18:21'),
(0, 143, 'Adjustment', -4.00, 5.00, 1.00, NULL, NULL, 'Manual Edit', 'Batch edited by user', '2025-11-29 12:18:59'),
(0, 145, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-29. 657567', '2025-11-29 12:20:21'),
(0, 144, 'Discard', -4.00, 4.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 12:56:06'),
(0, 143, 'Discard', -1.00, 1.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 13:33:04'),
(0, 142, 'Discard', -10.00, 10.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 13:33:11'),
(0, 146, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-29. fgbsdfafe', '2025-11-29 13:34:39'),
(0, 147, 'Purchase', 20.00, 0.00, 20.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-29. Additional batch added on 2025-11-29', '2025-11-29 13:35:15'),
(0, 146, 'Discard', -10.00, 10.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 13:45:55'),
(0, 147, 'Discard', -20.00, 20.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 13:45:59'),
(0, 148, 'Purchase', 10.00, 0.00, 10.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-29. Additional batch added on 2025-11-29', '2025-11-29 13:46:17'),
(0, 149, 'Purchase', 20.00, 0.00, 20.00, NULL, NULL, NULL, 'Initial stock purchase on 2025-11-29. Additional batch added on 2025-11-29', '2025-11-29 13:46:32'),
(0, 149, 'Adjustment', -5.00, 20.00, 15.00, NULL, NULL, 'Manual Edit', 'Batch edited by user', '2025-11-29 13:47:18'),
(0, 148, 'Discard', -10.00, 10.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 14:10:59'),
(0, 149, 'Discard', -15.00, 15.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 14:11:17'),
(0, 150, 'Adjustment', -36.00, 56.00, 20.00, NULL, NULL, 'Manual Edit', 'Batch edited by user', '2025-11-29 14:13:49'),
(0, 151, 'Adjustment', -5.00, 10.00, 5.00, NULL, NULL, 'Manual Edit', 'Batch edited by user', '2025-11-29 14:20:09'),
(0, 150, 'Discard', -20.00, 20.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 14:20:46'),
(0, 151, 'Discard', -5.00, 5.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 14:20:57'),
(0, 153, 'Adjustment', -5.00, 20.00, 15.00, NULL, NULL, 'Manual Edit', 'Batch edited by user', '2025-11-29 14:21:42'),
(0, 152, 'Discard', -10.00, 10.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 14:32:46'),
(0, 153, 'Discard', -15.00, 15.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 14:32:50'),
(0, 155, 'Adjustment', -5.00, 20.00, 15.00, NULL, NULL, 'Manual Edit', 'Batch edited by user', '2025-11-29 14:33:48'),
(0, 155, 'Discard', -15.00, 15.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 14:34:13'),
(0, 154, 'Discard', -10.00, 10.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 14:42:29'),
(0, 157, 'Adjustment', -14.00, 34.00, 20.00, NULL, NULL, 'Manual Edit', 'Batch edited by user', '2025-11-29 14:43:51'),
(0, 157, 'Discard', -20.00, 20.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 14:44:35'),
(0, 88, 'Adjustment', -3.00, 4.00, 1.00, NULL, NULL, 'Manual Edit', 'Batch edited by user', '2025-11-29 14:45:56'),
(0, 88, 'Discard', -1.00, 1.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 14:46:20'),
(0, 156, 'Discard', -23.00, 23.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 14:52:57'),
(0, 245, 'Discard', -50.00, 50.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 15:09:00'),
(0, 159, 'Discard', -34.00, 34.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 15:13:54'),
(0, 158, 'Discard', -12.00, 12.00, 0.00, NULL, 'System User', 'Expired/Damaged', 'Batch discarded from Batch Management interface', '2025-11-29 15:13:58'),
(0, 444, 'Usage', -50.00, 50.00, 0.00, 'RES-6', 'System', 'Reservation Confirmed', 'Deducted for reservation #6 - S-E (w/ Chicken & Fries) (1 units) by Ronal Sevill', '2025-11-29 17:21:26'),
(0, 474, 'Usage', -50.00, 50.00, 0.00, 'RES-6', 'System', 'Reservation Confirmed', 'Deducted for reservation #6 - S-E (w/ Chicken & Fries) (1 units) by Ronal Sevill', '2025-11-29 17:21:26'),
(0, 479, 'Usage', -20.00, 50.00, 30.00, 'RES-6', 'System', 'Reservation Confirmed', 'Deducted for reservation #6 - S-E (w/ Chicken & Fries) (1 units) by Ronal Sevill', '2025-11-29 17:21:26'),
(0, 419, 'Usage', -50.00, 50.00, 0.00, 'RES-6', 'System', 'Reservation Confirmed', 'Deducted for reservation #6 - S-E (w/ Chicken & Fries) (1 units) by Ronal Sevill', '2025-11-29 17:21:26'),
(0, 467, 'Usage', -50.00, 50.00, 0.00, 'RES-6', 'System', 'Reservation Confirmed', 'Deducted for reservation #6 - S-E (w/ Chicken & Fries) (1 units) by Ronal Sevill', '2025-11-29 17:21:26'),
(0, 507, 'Usage', -30.00, 50.00, 20.00, 'RES-6', 'System', 'Reservation Confirmed', 'Deducted for reservation #6 - S-E (w/ Chicken & Fries) (1 units) by Ronal Sevill', '2025-11-29 17:21:26'),
(0, 500, 'Usage', -50.00, 50.00, 0.00, 'RES-6', 'System', 'Reservation Confirmed', 'Deducted for reservation #6 - S-E (w/ Chicken & Fries) (1 units) by Ronal Sevill', '2025-11-29 17:21:26'),
(0, 479, 'Usage', -20.00, 30.00, 10.00, 'RES-6', 'System', 'Reservation Confirmed', 'Deducted for reservation #6 - S-H (Chicken, Pizza Roll & Fries) (1 units) by Ronal Sevill', '2025-11-29 17:21:26'),
(0, 490, 'Usage', -20.00, 50.00, 30.00, 'RES-6', 'System', 'Reservation Confirmed', 'Deducted for reservation #6 - S-H (Chicken, Pizza Roll & Fries) (1 units) by Ronal Sevill', '2025-11-29 17:21:26'),
(0, 507, 'Usage', -20.00, 20.00, 0.00, 'RES-6', 'System', 'Reservation Confirmed', 'Deducted for reservation #6 - S-H (Chicken, Pizza Roll & Fries) (1 units) by Ronal Sevill', '2025-11-29 17:21:26'),
(0, 479, 'Usage', -10.00, 10.00, 0.00, 'ORD-1000', 'POS User', 'POS Order', 'Deducted for order #1000 - S-C (w/ Shanghai, Ham & Cheese Sandwich) (1 units) by POS User', '2025-11-30 22:28:25'),
(0, 425, 'Usage', -50.00, 50.00, 0.00, 'ORD-1000', 'POS User', 'POS Order', 'Deducted for order #1000 - S-C (w/ Shanghai, Ham & Cheese Sandwich) (1 units) by POS User', '2025-11-30 22:28:25'),
(0, 449, 'Usage', -30.00, 50.00, 20.00, 'ORD-1000', 'POS User', 'POS Order', 'Deducted for order #1000 - S-C (w/ Shanghai, Ham & Cheese Sandwich) (1 units) by POS User', '2025-11-30 22:28:25'),
(0, 510, 'Usage', -2.00, 50.00, 48.00, 'ORD-1000', 'POS User', 'POS Order', 'Deducted for order #1000 - S-C (w/ Shanghai, Ham & Cheese Sandwich) (1 units) by POS User', '2025-11-30 22:28:25'),
(0, 490, 'Usage', -30.00, 30.00, 0.00, 'ORD-1000', 'POS User', 'POS Order', 'Deducted for order #1000 - S-C (w/ Shanghai, Ham & Cheese Sandwich) (1 units) by POS User', '2025-11-30 22:28:25'),
(0, 475, 'Usage', -20.00, 50.00, 30.00, 'ORD-1000', 'POS User', 'POS Order', 'Deducted for order #1000 - S-C (w/ Shanghai, Ham & Cheese Sandwich) (1 units) by POS User', '2025-11-30 22:28:25'),
(0, 449, 'Usage', -20.00, 20.00, 0.00, 'ORD-1000', 'POS User', 'POS Order', 'Deducted for order #1000 - S-B (w/ Shanghai & Empanada) (1 units) by POS User', '2025-11-30 22:28:25'),
(0, 450, 'Usage', -20.00, 50.00, 30.00, 'ORD-1000', 'POS User', 'POS Order', 'Deducted for order #1000 - S-B (w/ Shanghai & Empanada) (1 units) by POS User', '2025-11-30 22:28:25'),
(0, 510, 'Usage', -2.00, 48.00, 46.00, 'ORD-1000', 'POS User', 'POS Order', 'Deducted for order #1000 - S-B (w/ Shanghai & Empanada) (1 units) by POS User', '2025-11-30 22:28:25'),
(0, 445, 'Usage', -10.00, 50.00, 40.00, 'ORD-1000', 'POS User', 'POS Order', 'Deducted for order #1000 - S-B (w/ Shanghai & Empanada) (1 units) by POS User', '2025-11-30 22:28:25');

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
(2, 'Ronald', 'Sevillaaaaee', 'sevillaronald32@gmail.com', '$2y$12$YUalmxXNTAnYHqE4YuE9f.OvHg/.rAfqFFE38JQa4idQeP7mvdWvO', '09511299476', 'Online', 3, 0, 3, '2025-12-01 00:21:33', '2025-11-25 00:06:51', '2025-11-06 23:34:05', 'Active', 4.00),
(5, 'Test', 'User', 'test_1762492324@example.com', '$2y$10$oICfw2SwBITYnSkGtyduZubnjRCktRLv0Uraut8a3YxiRO.JpO8kG', '09123456789', 'Online', 0, 0, 0, NULL, NULL, '2025-11-07 13:12:04', 'Active', 0.00),
(6, 'TestJS', 'UserJS', 'testjs@example.com', '$2y$10$7vpPF.mup7IeLZ1Rv6XYHOfR1bov3BR5jKsERDKgyQ7mKrWVluDpy', '09123456789', 'Online', 0, 0, 0, NULL, NULL, '2025-11-07 13:35:28', 'Active', 0.00),
(7, 'Ronald', 'Sevilla', 'sevillaronald@gmail.com', '$2y$12$de0QIvl638SHw4FryePZeOJfkkJK0uhpo6/ynmbn1MjSrKQf6HM9C', '09512994765', 'Online', 3, 0, 3, '2025-11-22 15:53:14', '2025-11-07 14:51:08', '2025-11-07 13:40:13', 'Active', 4.50),
(8, 'Ronal', 'Sevill', 'sevillaronald9@gmail.com', '$2y$12$NvAqawV6IsJSEXIGObqOR.h1p2FJcozHohRB1Xk5RAUFt2id6WRL.', '09511299476', 'Online', 2, 1, 3, '2025-11-23 12:46:04', NULL, '2025-11-22 17:18:23', 'Active', 4.00);

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
(4, 8, 4.0, 4, 5, 4, 4, 4, 'sdasdasdasda', 'asdafwgsdgsxgd', 'afafwafafdsfadfdafd', 'sfagecvhtehr', 'dawhdutrhsghwt', 'ddadkjsiurhaubfdsgfe', 'Approved', '2025-11-22 18:14:42', '2025-11-25 22:12:21', '2025-11-25 22:12:21'),
(0, 2, 4.0, 5, 5, 4, 5, 4, 'good', 'wow', 'great', 'wow', 'okay', 'hahahah sna al lal hwfwad', 'Approved', '2025-11-28 23:46:01', '2025-11-28 23:46:44', '2025-11-28 23:46:44');

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
DELIMITER $$
CREATE TRIGGER `update_customer_satisfaction_rating` AFTER UPDATE ON `customer_reviews` FOR EACH ROW BEGIN
    -- Only update when status changes to 'Approved' or when an approved review is updated
    IF NEW.Status = 'Approved' THEN
        UPDATE customers 
        SET SatisfactionRating = (
            SELECT ROUND(AVG(OverallRating), 2)
            FROM customer_reviews
            WHERE CustomerID = NEW.CustomerID 
            AND Status = 'Approved'
        )
        WHERE CustomerID = NEW.CustomerID;
    END IF;
    
    -- If status changed from Approved to something else, recalculate
    IF OLD.Status = 'Approved' AND NEW.Status != 'Approved' THEN
        UPDATE customers 
        SET SatisfactionRating = (
            SELECT COALESCE(ROUND(AVG(OverallRating), 2), 0.00)
            FROM customer_reviews
            WHERE CustomerID = NEW.CustomerID 
            AND Status = 'Approved'
        )
        WHERE CustomerID = NEW.CustomerID;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `customer_statistics`
--

CREATE TABLE `customer_statistics` (
  `total_customers` bigint(21) DEFAULT NULL,
  `active_customers` bigint(21) DEFAULT NULL,
  `suspended_customers` bigint(21) DEFAULT NULL,
  `online_customers` bigint(21) DEFAULT NULL,
  `average_satisfaction` decimal(7,6) DEFAULT NULL,
  `total_orders` decimal(32,0) DEFAULT NULL,
  `total_reservations` decimal(32,0) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
-- Table structure for table `expiring_ingredients`
--

CREATE TABLE `expiring_ingredients` (
  `InventoryID` int(10) DEFAULT NULL,
  `IngredientName` varchar(100) DEFAULT NULL,
  `StockQuantity` decimal(10,2) DEFAULT NULL,
  `UnitType` varchar(50) DEFAULT NULL,
  `ExpirationDate` date DEFAULT NULL,
  `DaysUntilExpiration` int(7) DEFAULT NULL,
  `Alert_Level` varchar(28) DEFAULT NULL,
  `Remarks` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
(1, 'Pork Belly', 1, 'kg', 75.00, '2025-11-29 16:42:19', '2025-11-27', 'Fresh delivery twice weekly', 5.00, 100.00, 1, 1, NULL),
(2, 'Pork Liempo', 1, 'kg', 70.00, '2025-11-29 16:42:20', '2025-11-27', 'Main grilling meat', 5.00, 100.00, 1, 1, NULL),
(3, 'Chicken Whole', 1, 'kg', 80.00, '2025-11-29 16:42:20', '2025-11-27', 'For inasal and fried chicken', 5.00, 100.00, 1, 1, NULL),
(4, 'Chicken Wings', 1, 'kg', 65.00, '2025-11-29 16:42:20', '2025-11-27', 'Buffalo wings stock', 5.00, 100.00, 1, 1, NULL),
(5, 'Chicken Breast', 1, 'kg', 0.00, '2025-11-29 16:42:20', '2025-11-27', 'For sisig and salads', 5.00, 100.00, 1, 1, NULL),
(6, 'Pork Sisig Meat', 1, 'kg', 62.00, '2025-11-29 16:42:20', '2025-11-26', 'Pre-chopped pig face and ears', 5.00, 100.00, 1, 1, NULL),
(7, 'Bangus (Milkfish)', 8, 'kg', 60.00, '2025-11-29 16:42:20', '2025-11-24', 'Fresh catch', 5.00, 100.00, 1, 1, NULL),
(8, 'Tilapia', 8, 'kg', 58.00, '2025-11-29 16:42:20', '2025-11-24', 'Farm raised', 5.00, 100.00, 1, 1, NULL),
(9, 'Shrimp', 8, 'kg', 55.00, '2025-11-29 16:42:20', '2025-11-24', 'Medium size', 5.00, 100.00, 1, 1, NULL),
(10, 'Squid', 8, 'kg', 56.00, '2025-11-29 16:42:20', '2025-11-24', 'Cleaned', 5.00, 100.00, 1, 1, NULL),
(11, 'Ground Pork', 1, 'kg', 0.00, '2025-11-29 16:42:20', '2025-11-26', 'For longganisa and lumpia', 5.00, 100.00, 1, 1, NULL),
(12, 'Beef', 1, 'kg', 62.00, '2025-11-29 16:42:20', '2025-11-27', 'For bulalo and kare-kare', 5.00, 100.00, 1, 1, NULL),
(13, 'Pork Knuckle (Pata)', 1, 'kg', 60.00, '2025-11-29 16:42:20', '2025-11-27', 'For crispy pata', 5.00, 100.00, 1, 1, NULL),
(14, 'Pork Ribs', 1, 'kg', 58.00, '2025-11-29 16:42:20', '2025-11-27', 'Baby back ribs', 5.00, 100.00, 1, 1, NULL),
(15, 'Tocino Meat', 1, 'kg', 60.00, '2025-11-29 16:42:20', '2025-11-30', 'Pre-marinated', 5.00, 100.00, 1, 1, NULL),
(16, 'Tapa Meat', 1, 'kg', 60.00, '2025-11-29 16:42:20', '2025-11-30', 'Pre-marinated beef', 5.00, 100.00, 1, 1, NULL),
(17, 'Longganisa', 1, 'kg', 58.00, '2025-11-29 16:42:20', '2025-12-05', 'House recipe', 5.00, 100.00, 1, 1, NULL),
(18, 'Hotdog', 1, 'pack', 70.00, '2025-11-29 16:42:20', '2025-12-18', 'Jumbo size', 5.00, 100.00, 1, 1, NULL),
(19, 'Bacon', 1, 'kg', 55.00, '2025-11-29 16:42:20', '2025-12-10', 'Smoked', 5.00, 100.00, 1, 1, NULL),
(20, 'Corned Beef', 1, 'can', 74.00, '2025-11-29 16:42:21', '2026-11-15', 'Canned goods', 5.00, 100.00, 1, 1, NULL),
(21, 'Spam', 1, 'can', 70.00, '2025-11-29 16:42:21', '2026-11-15', 'Canned meat', 5.00, 100.00, 1, 1, NULL),
(22, 'Eggs', 3, 'tray', 60.00, '2025-11-29 16:42:21', '2025-12-05', '30 pcs per tray', 5.00, 100.00, 1, 1, NULL),
(23, 'Dried Fish (Tuyo)', NULL, 'kg', 53.00, '2025-11-29 16:42:21', '2025-12-18', 'Salted dried herring', 5.00, 100.00, 1, 1, NULL),
(24, 'Danggit', NULL, 'kg', 52.50, '2025-11-29 16:42:21', '2025-12-18', 'Dried rabbitfish', 5.00, 100.00, 1, 1, NULL),
(25, 'Rice', 4, 'kg', 150.00, '2025-11-29 16:42:21', '2026-05-19', 'Sinandomeng variety', 5.00, 100.00, 1, 1, NULL),
(26, 'Garlic Rice Mix', 4, 'kg', 60.00, '2025-11-29 16:42:21', '2026-02-19', 'Pre-mixed seasoning', 5.00, 100.00, 1, 1, NULL),
(27, 'Pancit Canton Noodles', 4, 'kg', 58.00, '2025-11-29 16:42:21', '2026-02-15', 'Dried egg noodles', 5.00, 100.00, 1, 1, NULL),
(28, 'Pancit Bihon Noodles', 4, 'kg', 58.00, '2025-11-29 16:42:21', '2026-02-15', 'Rice vermicelli', 5.00, 100.00, 1, 1, NULL),
(29, 'Sotanghon Noodles', 4, 'kg', 55.00, '2025-11-29 16:42:21', '2026-02-15', 'Glass noodles', 5.00, 100.00, 1, 1, NULL),
(30, 'Spaghetti Noodles', 4, 'kg', 0.00, '2025-11-29 16:42:21', '2026-02-15', 'Italian pasta', 5.00, 100.00, 1, 1, NULL),
(31, 'Onion', 2, 'kg', 40.00, '2025-11-29 16:42:21', '2025-12-05', 'Red onion preferred', 5.00, 100.00, 1, 1, NULL),
(32, 'Garlic', 2, 'kg', 58.00, '2025-11-29 16:42:21', '2025-12-15', 'Native garlic', 5.00, 100.00, 1, 1, NULL),
(33, 'Tomato', 2, 'kg', 60.00, '2025-11-29 16:42:21', '2025-11-28', 'Fresh ripe', 5.00, 100.00, 1, 1, NULL),
(34, 'Ginger', 2, 'kg', 55.00, '2025-11-29 16:42:21', '2025-12-10', 'For soups and marinades', 5.00, 100.00, 1, 1, NULL),
(35, 'Cabbage', 2, 'kg', 0.00, '2025-11-29 16:42:21', '2025-11-28', 'For pancit and lumpia', 5.00, 100.00, 1, 1, NULL),
(36, 'Carrots', 2, 'kg', 30.00, '2025-11-29 16:42:21', '2025-12-01', 'For pancit and menudo', 5.00, 100.00, 1, 1, NULL),
(37, 'Sayote (Chayote)', 2, 'kg', 55.00, '2025-11-29 16:42:21', '2025-11-30', 'For tinola', 5.00, 100.00, 1, 1, NULL),
(38, 'Kangkong', 2, 'bundle', 65.00, '2025-11-29 16:42:21', '2025-11-24', 'Water spinach', 5.00, 100.00, 1, 1, NULL),
(39, 'Pechay', 2, 'bundle', 62.00, '2025-11-29 16:42:21', '2025-11-24', 'Bok choy', 5.00, 100.00, 1, 1, NULL),
(40, 'Green Beans (Sitaw)', 2, 'kg', 54.00, '2025-11-29 16:42:21', '2025-11-26', 'String beans', 5.00, 100.00, 1, 1, NULL),
(41, 'Eggplant', 2, 'kg', 56.00, '2025-11-29 16:42:21', '2025-11-27', 'For tortang talong', 5.00, 100.00, 1, 1, NULL),
(42, 'Ampalaya (Bitter Gourd)', 2, 'kg', 50.00, '2025-11-29 16:42:21', '2025-11-27', 'For ginisang ampalaya', 1.00, 100.00, 1, 1, NULL),
(43, 'Malunggay Leaves', 2, 'bundle', 60.00, '2025-11-29 16:42:22', '2025-11-24', 'Moringa leaves', 5.00, 100.00, 1, 1, NULL),
(44, 'Green Papaya', 2, 'kg', 55.00, '2025-11-29 16:42:22', '2025-11-28', 'For tinola', 5.00, 100.00, 1, 1, NULL),
(45, 'Banana Blossom', 2, 'pc', 58.00, '2025-11-29 16:42:22', '2025-11-25', 'For kare-kare', 5.00, 100.00, 1, 1, NULL),
(46, 'Talong (Eggplant)', 2, 'kg', 55.00, '2025-11-29 16:42:22', '2025-11-27', 'Long variety', 5.00, 100.00, 1, 1, NULL),
(47, 'Bell Pepper', 2, 'kg', 53.00, '2025-11-29 16:42:22', '2025-11-28', 'Mixed colors', 5.00, 100.00, 1, 1, NULL),
(48, 'Chili Peppers', 2, 'kg', 52.00, '2025-11-29 16:42:22', '2025-12-01', 'Siling labuyo', 5.00, 100.00, 1, 1, NULL),
(49, 'Calamansi', 2, 'kg', 55.00, '2025-11-29 16:42:22', '2025-11-28', 'Philippine lime', 5.00, 100.00, 1, 1, NULL),
(50, 'Lemon', 2, 'kg', 53.00, '2025-11-29 16:42:22', '2025-11-30', 'For drinks', 5.00, 100.00, 1, 1, NULL),
(51, 'Lettuce', 2, 'kg', 54.00, '2025-11-29 16:42:22', '2025-11-25', 'Iceberg variety', 5.00, 100.00, 1, 1, NULL),
(52, 'Cucumber', 2, 'kg', 54.00, '2025-11-29 16:42:22', '2025-11-27', 'For salads', 5.00, 100.00, 1, 1, NULL),
(53, 'Potato', 2, 'kg', 0.00, '2025-11-29 16:42:22', '2025-12-10', 'For fries and menudo', 5.00, 100.00, 1, 1, NULL),
(54, 'Corn', 2, 'kg', 55.00, '2025-11-29 16:42:22', '2025-11-26', 'Sweet corn', 5.00, 100.00, 1, 1, NULL),
(55, 'Soy Sauce', 5, 'liter', 60.00, '2025-11-29 16:42:22', '2026-05-15', 'Silver Swan brand', 5.00, 100.00, 1, 1, NULL),
(56, 'Vinegar', 5, 'liter', 60.00, '2025-11-29 16:42:22', '2026-05-15', 'Cane vinegar', 5.00, 100.00, 1, 1, NULL),
(57, 'Fish Sauce (Patis)', 5, 'liter', 58.00, '2025-11-29 16:42:22', '2026-05-15', 'Rufina brand', 5.00, 100.00, 1, 1, NULL),
(58, 'Oyster Sauce', 5, 'bottle', 62.00, '2025-11-29 16:42:22', '2026-03-15', 'Lee Kum Kee', 5.00, 100.00, 1, 1, NULL),
(59, 'Banana Ketchup', 5, 'bottle', 65.00, '2025-11-29 16:42:22', '2026-03-15', 'Jufran brand', 5.00, 100.00, 1, 1, NULL),
(60, 'Tomato Sauce', 5, 'can', 0.00, '2025-11-29 16:42:22', '2026-05-15', 'Del Monte', 5.00, 100.00, 1, 1, NULL),
(61, 'Mayonnaise', 5, 'jar', 30.00, '2025-11-29 16:42:22', '2026-02-15', 'Best Foods', 5.00, 100.00, 1, 1, NULL),
(62, 'Chili Garlic Sauce', 5, 'bottle', 58.00, '2025-11-29 16:42:22', '2026-03-15', 'For sisig', 5.00, 100.00, 1, 1, NULL),
(63, 'Bagoong (Shrimp Paste)', 5, 'jar', 56.00, '2025-11-29 16:42:23', '2026-06-15', 'Sauteed', 5.00, 100.00, 1, 1, NULL),
(64, 'Peanut Butter', 5, 'jar', 58.00, '2025-11-29 16:42:23', '2026-04-15', 'For kare-kare', 5.00, 100.00, 1, 1, NULL),
(65, 'Liver Spread', 5, 'can', 0.00, '2025-11-29 16:42:23', '2026-04-15', 'For Filipino spaghetti', 5.00, 100.00, 1, 1, NULL),
(66, 'Achuete (Annatto) Oil', 5, 'boxes', 60.00, '2025-11-29 16:44:57', '2026-06-15', 'For inasal color', 5.00, 100.00, 1, 1, NULL),
(67, 'Worcestershire Sauce', 5, 'bottle', 54.00, '2025-11-29 16:42:23', '2026-06-15', 'Lea & Perrins', 5.00, 100.00, 1, 1, NULL),
(68, 'Hot Sauce', 5, 'bottle', 56.00, '2025-11-29 16:42:23', '2026-06-15', 'Tabasco', 5.00, 100.00, 1, 1, NULL),
(69, 'BBQ Sauce', 5, 'bottle', 56.00, '2025-11-29 16:42:23', '2026-03-15', 'For grilled items', 5.00, 100.00, 1, 1, NULL),
(70, 'Gravy Mix', 5, 'pack', 65.00, '2025-11-29 16:42:23', '2026-06-15', 'Brown gravy', 5.00, 100.00, 1, 1, NULL),
(71, 'Evaporated Milk', 3, 'can', 74.00, '2025-11-29 16:42:23', '2026-06-15', 'For desserts', 5.00, 100.00, 1, 1, NULL),
(72, 'Condensed Milk', 3, 'can', 74.00, '2025-11-29 16:42:23', '2026-06-15', 'For halo-halo', 5.00, 100.00, 1, 1, NULL),
(73, 'Coconut Milk', 3, 'liter', 60.00, '2025-11-29 16:42:23', '2025-12-18', 'For laing and ginataang', 5.00, 100.00, 1, 1, NULL),
(74, 'Coconut Cream', 3, 'can', 62.00, '2025-11-29 16:42:23', '2026-03-15', 'Thick coconut milk', 5.00, 100.00, 1, 1, NULL),
(75, 'Butter', 3, 'kg', 53.00, '2025-11-29 16:42:23', '2026-01-18', 'Salted', 5.00, 100.00, 1, 1, NULL),
(76, 'Cheese', 3, 'kg', 0.00, '2025-11-29 16:42:23', '2025-12-18', 'Quick melt', 5.00, 100.00, 1, 1, NULL),
(77, 'Fresh Milk', 3, 'liter', 58.00, '2025-11-29 16:42:23', '2025-11-28', 'For shakes', 5.00, 100.00, 1, 1, NULL),
(78, 'Coffee', 7, 'kg', 53.00, '2025-11-29 16:42:23', '2026-05-15', 'Ground coffee', 5.00, 100.00, 1, 1, NULL),
(79, 'Tea Bags', 7, 'box', 60.00, '2025-11-29 16:42:23', '2026-08-15', 'Assorted flavors', 5.00, 100.00, 1, 1, NULL),
(80, 'Iced Tea Powder', 7, 'kg', 55.00, '2025-11-29 16:42:23', '2026-06-15', 'Lemon flavor', 5.00, 100.00, 1, 1, NULL),
(81, 'Mango Shake Mix', 7, 'kg', 53.00, '2025-11-29 16:42:23', '2026-06-15', 'Powdered', 5.00, 100.00, 1, 1, NULL),
(82, 'Chocolate Powder', 7, 'kg', 53.00, '2025-11-29 16:42:24', '2026-06-15', 'For drinks', 5.00, 100.00, 1, 1, NULL),
(83, 'Soft Drinks', 7, 'case', 60.00, '2025-11-29 16:42:24', '2026-03-18', 'Assorted 1.5L', 5.00, 100.00, 1, 1, NULL),
(84, 'Mineral Water', 7, 'case', 65.00, '2025-11-29 16:42:24', '2026-06-18', '500ml bottles', 5.00, 100.00, 1, 1, NULL),
(85, 'Buko Juice', 7, 'liter', 58.00, '2025-11-29 16:42:24', '2025-11-25', 'Fresh coconut water', 5.00, 100.00, 1, 1, NULL),
(86, 'Cooking Oil', 5, 'liter', 0.00, '2025-11-29 16:42:24', '2026-06-15', 'Vegetable oil', 5.00, 100.00, 1, 1, NULL),
(87, 'Salt', 6, 'kg', 60.00, '2025-11-29 16:42:24', '2027-11-15', 'Iodized', 5.00, 100.00, 1, 1, NULL),
(88, 'Sugar', 6, 'kg', 65.00, '2025-11-29 16:42:24', '2026-11-15', 'White refined', 5.00, 100.00, 1, 1, NULL),
(89, 'Brown Sugar', 6, 'kg', 58.00, '2025-11-29 16:42:24', '2026-11-15', 'Muscovado', 5.00, 100.00, 1, 1, NULL),
(90, 'Pepper', 6, 'kg', 52.00, '2025-11-29 16:42:24', '2026-11-15', 'Ground black pepper', 5.00, 100.00, 1, 1, NULL),
(91, 'MSG', 6, 'kg', 53.00, '2025-11-29 16:42:24', '2026-11-15', 'Ajinomoto', 5.00, 100.00, 1, 1, NULL),
(92, 'Flour', 4, 'kg', 60.00, '2025-11-29 16:42:24', '2026-05-15', 'All-purpose', 5.00, 100.00, 1, 1, NULL),
(93, 'Cornstarch', 4, 'kg', 0.00, '2025-11-29 16:42:24', '2026-11-15', 'For breading', 5.00, 100.00, 1, 1, NULL),
(94, 'Bread Crumbs', 4, 'kg', 54.00, '2025-11-29 16:42:24', '2026-03-15', 'Japanese panko', 5.00, 100.00, 1, 1, NULL),
(95, 'Lumpia Wrapper', 10, 'pack', 70.00, '2025-11-29 16:42:24', '2025-12-18', '25 sheets per pack', 5.00, 100.00, 1, 1, NULL),
(96, 'Spring Roll Wrapper', 10, 'pack', 46.00, '2025-11-29 16:42:24', '2025-12-18', 'Small size', 5.00, 100.00, 1, 1, NULL),
(97, 'Leche Flan Mix', 10, 'pack', 60.00, '2025-11-29 16:42:24', '2026-06-15', 'Instant mix', 5.00, 100.00, 1, 1, NULL),
(98, 'Gulaman (Agar)', 10, 'pack', 65.00, '2025-11-29 16:42:24', '2026-09-15', 'For halo-halo', 5.00, 100.00, 1, 1, NULL),
(99, 'Sago Pearls', 10, 'kg', 55.00, '2025-11-29 16:42:24', '2026-09-15', 'Tapioca pearls', 5.00, 100.00, 1, 1, NULL),
(100, 'Kaong (Palm Fruit)', 10, 'jar', 60.00, '2025-11-29 16:42:24', '2026-06-15', 'For halo-halo', 5.00, 100.00, 1, 1, NULL),
(101, 'Nata de Coco', 10, 'jar', 60.00, '2025-11-29 16:42:25', '2026-06-15', 'Coconut gel', 5.00, 100.00, 1, 1, NULL),
(102, 'Ube Halaya', 10, 'kg', 54.00, '2025-11-29 16:42:25', '2025-12-18', 'Purple yam jam', 5.00, 100.00, 1, 1, NULL),
(103, 'Langka (Jackfruit)', 10, 'kg', 53.00, '2025-11-29 16:42:25', '2025-12-01', 'Sweetened', 5.00, 100.00, 1, 1, NULL),
(104, 'Macapuno', 10, 'jar', 56.00, '2025-11-29 16:42:25', '2026-06-15', 'Coconut sport', 5.00, 100.00, 1, 1, NULL),
(105, 'Ice Cream', 10, 'liter', 60.00, '2025-11-29 16:42:26', '2026-02-18', 'Assorted flavors', 5.00, 100.00, 1, 1, NULL),
(106, 'Shaved Ice', 10, 'kg', 100.00, '2025-11-29 16:42:26', '2025-11-22', 'Made fresh daily', 5.00, 100.00, 1, 1, NULL),
(107, 'Banana', 10, 'kg', 60.00, '2025-11-29 16:42:26', '2025-11-26', 'Saba variety', 5.00, 100.00, 1, 1, NULL),
(108, 'Turon Wrapper', 10, 'pack', 60.00, '2025-11-29 16:42:26', '2025-12-18', 'Lumpia wrapper for turon', 5.00, 100.00, 1, 1, NULL),
(109, 'Chicken Broth', 10, 'liter', 58.00, '2025-11-29 16:42:26', '2025-12-18', 'Homemade stock', 5.00, 100.00, 1, 1, NULL),
(110, 'Pork Broth', 10, 'liter', 56.00, '2025-11-29 16:42:26', '2025-12-18', 'For sinigang', 5.00, 100.00, 1, 1, NULL),
(111, 'Beef Broth', 10, 'liter', 55.00, '2025-11-29 16:42:26', '2025-12-18', 'For bulalo', 5.00, 100.00, 1, 1, NULL),
(112, 'Tamarind Mix (Sinigang)', 10, 'pack', 70.00, '2025-11-29 16:42:26', '2026-06-15', 'Instant sinigang mix', 5.00, 100.00, 1, 1, NULL),
(113, 'Miso Paste', 10, 'kg', 52.00, '2025-11-29 16:42:26', '2026-03-15', 'For miso soup', 5.00, 100.00, 1, 1, NULL),
(114, 'Lemongrass', 6, 'bundle', 58.00, '2025-11-29 16:42:26', '2025-11-28', 'For inasal marinade', 5.00, 100.00, 1, 1, NULL),
(115, 'Bay Leaves', 6, 'pack', 55.00, '2025-11-29 16:42:26', '2026-11-15', 'Dried', 5.00, 100.00, 1, 1, NULL),
(116, 'Paprika', 6, 'kg', 51.00, '2025-11-29 16:42:26', '2026-11-15', 'Smoked', 5.00, 100.00, 1, 1, NULL),
(117, 'Cumin', 6, 'kg', 50.50, '2025-11-29 16:42:26', '2026-11-15', 'Ground', 5.00, 100.00, 1, 1, NULL),
(118, 'Oregano', 6, 'pack', 53.00, '2025-11-29 16:42:26', '2026-11-15', 'Dried', 5.00, 100.00, 1, 1, NULL),
(119, 'Annatto Seeds', 6, 'kg', 51.00, '2025-11-29 16:42:26', '2026-11-15', 'For atsuete oil', 5.00, 100.00, 1, 1, NULL),
(120, 'Pandan Leaves', 6, 'bundle', 55.00, '2025-11-29 16:42:26', '2025-11-26', 'For rice and desserts', 5.00, 100.00, 1, 1, NULL),
(123, 'ampalaay adad', 1, 'pieces', 0.00, '2025-11-25 16:36:37', NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(133, 'a william', 10, 'kg', 45.00, '2025-11-26 18:07:54', NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(134, 'aaahatdog4564', 1, 'kg', 668.00, '2025-11-27 12:17:03', NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(135, 'aaaa343454', 1, 'kg', 0.00, '2025-11-27 11:59:01', NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(136, 'aaa21121', 1, 'boxes', 0.00, NULL, NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(137, 'a23232', 1, 'liters', 165.00, '2025-11-27 12:19:05', NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(138, 'aaaqa43', 1, 'liters', 0.00, NULL, NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(139, 'aaa4343', 1, 'pieces', 0.00, NULL, NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(141, 'aaaaa344', 1, 'kg', 0.00, '2025-11-27 12:50:49', NULL, NULL, 5.00, 100.00, 0, 1, NULL),
(142, 'Soft Drink (Can)', 7, 'pcs', 50.00, '2025-11-29 16:42:26', NULL, NULL, 5.00, 100.00, 1, 1, NULL),
(143, 'Bottled Water', 7, 'pcs', 50.00, '2025-11-29 16:42:26', NULL, NULL, 5.00, 100.00, 1, 1, NULL),
(144, 'Pineapple Juice (Bottle)', 7, 'pcs', 50.00, '2025-11-29 16:42:26', NULL, NULL, 5.00, 100.00, 1, 1, NULL),
(145, 'SMB Pale Pilsen', 7, 'bottle', 50.00, '2025-11-29 16:42:26', NULL, NULL, 5.00, 100.00, 1, 1, NULL),
(146, 'Red Horse Stallion', 7, 'bottle', 50.00, '2025-11-29 16:42:26', NULL, NULL, 5.00, 100.00, 1, 1, NULL),
(147, 'San Mig Light', 7, 'bottle', 50.00, '2025-11-29 16:42:26', NULL, NULL, 5.00, 100.00, 1, 1, NULL),
(148, 'Beer Bucket (6 Bottles)', 7, 'bucket', 50.00, '2025-11-29 16:42:26', NULL, NULL, 5.00, 100.00, 1, 1, NULL);

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
  `BatchID` int(10) NOT NULL,
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
(415, 1, 'POR-20251129-001', 50.00, 50.00, 'kg', 38.76, '2025-11-29 16:42:19', '2025-12-23', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:19', '2025-11-29 16:42:19'),
(416, 2, 'POR-20251129-001', 50.00, 50.00, 'kg', 40.18, '2025-11-29 16:42:19', '2025-12-14', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:19', '2025-11-29 16:42:19'),
(417, 3, 'CHI-20251129-001', 50.00, 50.00, 'kg', 44.68, '2025-11-29 16:42:20', '2025-12-05', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(418, 4, 'CHI-20251129-001', 50.00, 50.00, 'kg', 37.27, '2025-11-29 16:42:20', '2025-12-09', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(419, 5, 'CHI-20251129-001', 0.00, 50.00, 'kg', 16.08, '2025-11-29 16:42:20', '2025-12-05', '', 'Depleted', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 17:21:26'),
(420, 6, 'POR-20251129-001', 50.00, 50.00, 'kg', 39.99, '2025-11-29 16:42:20', '2025-12-19', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(421, 7, 'BAN-20251129-001', 50.00, 50.00, 'kg', 45.19, '2025-11-29 16:42:20', '2025-12-17', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(422, 8, 'TIL-20251129-001', 50.00, 50.00, 'kg', 48.62, '2025-11-29 16:42:20', '2025-12-10', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(423, 9, 'SHR-20251129-001', 50.00, 50.00, 'kg', 27.12, '2025-11-29 16:42:20', '2025-12-12', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(424, 10, 'SQU-20251129-001', 50.00, 50.00, 'kg', 27.68, '2025-11-29 16:42:20', '2025-12-08', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(425, 11, 'GRO-20251129-001', 0.00, 50.00, 'kg', 31.91, '2025-11-29 16:42:20', '2025-12-09', '', 'Depleted', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-30 22:28:25'),
(426, 12, 'BEE-20251129-001', 50.00, 50.00, 'kg', 27.12, '2025-11-29 16:42:20', '2025-12-16', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(427, 13, 'POR-20251129-001', 50.00, 50.00, 'kg', 18.09, '2025-11-29 16:42:20', '2025-12-16', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(428, 14, 'POR-20251129-001', 50.00, 50.00, 'kg', 49.62, '2025-11-29 16:42:20', '2025-12-13', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(429, 15, 'TOC-20251129-001', 50.00, 50.00, 'kg', 49.89, '2025-11-29 16:42:20', '2025-12-24', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(430, 16, 'TAP-20251129-001', 50.00, 50.00, 'kg', 11.42, '2025-11-29 16:42:20', '2025-12-23', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(431, 17, 'LON-20251129-001', 50.00, 50.00, 'kg', 37.86, '2025-11-29 16:42:20', '2025-12-09', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(432, 18, 'HOT-20251129-001', 50.00, 50.00, 'pack', 46.58, '2025-11-29 16:42:20', '2025-12-28', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(433, 19, 'BAC-20251129-001', 50.00, 50.00, 'kg', 14.30, '2025-11-29 16:42:20', '2025-12-19', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:20', '2025-11-29 16:42:20'),
(434, 20, 'COR-20251129-001', 50.00, 50.00, 'can', 42.41, '2025-11-29 16:42:21', '2025-12-08', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(435, 21, 'SPA-20251129-001', 50.00, 50.00, 'can', 27.05, '2025-11-29 16:42:21', '2025-12-19', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(436, 22, 'EGG-20251129-001', 50.00, 50.00, 'tray', 42.37, '2025-11-29 16:42:21', '2025-12-08', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(437, 23, 'DRI-20251129-001', 50.00, 50.00, 'kg', 31.51, '2025-11-29 16:42:21', '2025-12-06', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(438, 24, 'DAN-20251129-001', 50.00, 50.00, 'kg', 47.29, '2025-11-29 16:42:21', '2025-12-12', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(439, 25, 'RIC-20251129-001', 50.00, 50.00, 'kg', 44.94, '2025-11-29 16:42:21', '2025-12-13', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(440, 26, 'GAR-20251129-001', 50.00, 50.00, 'kg', 18.21, '2025-11-29 16:42:21', '2025-12-27', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(441, 27, 'PAN-20251129-001', 50.00, 50.00, 'kg', 11.52, '2025-11-29 16:42:21', '2025-12-13', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(442, 28, 'PAN-20251129-001', 50.00, 50.00, 'kg', 45.08, '2025-11-29 16:42:21', '2025-12-08', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(443, 29, 'SOT-20251129-001', 50.00, 50.00, 'kg', 22.80, '2025-11-29 16:42:21', '2025-12-04', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(444, 30, 'SPA-20251129-001', 0.00, 50.00, 'kg', 17.44, '2025-11-29 16:42:21', '2025-12-25', '', 'Depleted', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 17:21:26'),
(445, 31, 'ONI-20251129-001', 40.00, 50.00, 'kg', 36.22, '2025-11-29 16:42:21', '2025-12-22', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-30 22:28:25'),
(446, 32, 'GAR-20251129-001', 50.00, 50.00, 'kg', 41.21, '2025-11-29 16:42:21', '2025-12-20', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(447, 33, 'TOM-20251129-001', 50.00, 50.00, 'kg', 46.98, '2025-11-29 16:42:21', '2025-12-20', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(448, 34, 'GIN-20251129-001', 50.00, 50.00, 'kg', 31.70, '2025-11-29 16:42:21', '2025-12-22', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(449, 35, 'CAB-20251129-001', 0.00, 50.00, 'kg', 49.58, '2025-11-29 16:42:21', '2025-12-23', '', 'Depleted', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-30 22:28:25'),
(450, 36, 'CAR-20251129-001', 30.00, 50.00, 'kg', 46.77, '2025-11-29 16:42:21', '2025-12-10', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-30 22:28:25'),
(451, 37, 'SAY-20251129-001', 50.00, 50.00, 'kg', 32.35, '2025-11-29 16:42:21', '2025-12-04', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(452, 38, 'KAN-20251129-001', 50.00, 50.00, 'bundle', 23.82, '2025-11-29 16:42:21', '2025-12-21', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(453, 39, 'PEC-20251129-001', 50.00, 50.00, 'bundle', 31.39, '2025-11-29 16:42:21', '2025-12-17', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(454, 40, 'GRE-20251129-001', 50.00, 50.00, 'kg', 12.06, '2025-11-29 16:42:21', '2025-12-20', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(455, 41, 'EGG-20251129-001', 50.00, 50.00, 'kg', 16.67, '2025-11-29 16:42:21', '2025-12-25', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(456, 42, 'AMP-20251129-001', 50.00, 50.00, 'kg', 38.21, '2025-11-29 16:42:21', '2025-12-04', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:21', '2025-11-29 16:42:21'),
(457, 43, 'MAL-20251129-001', 50.00, 50.00, 'bundle', 45.96, '2025-11-29 16:42:22', '2025-12-16', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(458, 44, 'GRE-20251129-001', 50.00, 50.00, 'kg', 39.32, '2025-11-29 16:42:22', '2025-12-09', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(459, 45, 'BAN-20251129-001', 50.00, 50.00, 'pc', 43.49, '2025-11-29 16:42:22', '2025-12-18', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(460, 46, 'TAL-20251129-001', 50.00, 50.00, 'kg', 22.42, '2025-11-29 16:42:22', '2025-12-25', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(461, 47, 'BEL-20251129-001', 50.00, 50.00, 'kg', 24.53, '2025-11-29 16:42:22', '2025-12-09', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(462, 48, 'CHI-20251129-001', 50.00, 50.00, 'kg', 14.24, '2025-11-29 16:42:22', '2025-12-24', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(463, 49, 'CAL-20251129-001', 50.00, 50.00, 'kg', 39.76, '2025-11-29 16:42:22', '2025-12-11', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(464, 50, 'LEM-20251129-001', 50.00, 50.00, 'kg', 17.34, '2025-11-29 16:42:22', '2025-12-05', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(465, 51, 'LET-20251129-001', 50.00, 50.00, 'kg', 41.69, '2025-11-29 16:42:22', '2025-12-22', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(466, 52, 'CUC-20251129-001', 50.00, 50.00, 'kg', 26.02, '2025-11-29 16:42:22', '2025-12-22', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(467, 53, 'POT-20251129-001', 0.00, 50.00, 'kg', 29.13, '2025-11-29 16:42:22', '2025-12-08', '', 'Depleted', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 17:21:26'),
(468, 54, 'COR-20251129-001', 50.00, 50.00, 'kg', 29.32, '2025-11-29 16:42:22', '2025-12-25', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(469, 55, 'SOY-20251129-001', 50.00, 50.00, 'liter', 44.81, '2025-11-29 16:42:22', '2025-12-23', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(470, 56, 'VIN-20251129-001', 50.00, 50.00, 'liter', 17.64, '2025-11-29 16:42:22', '2025-12-20', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(471, 57, 'FIS-20251129-001', 50.00, 50.00, 'liter', 41.86, '2025-11-29 16:42:22', '2025-12-28', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(472, 58, 'OYS-20251129-001', 50.00, 50.00, 'bottle', 26.63, '2025-11-29 16:42:22', '2025-12-08', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(473, 59, 'BAN-20251129-001', 50.00, 50.00, 'bottle', 39.14, '2025-11-29 16:42:22', '2025-12-05', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(474, 60, 'TOM-20251129-001', 0.00, 50.00, 'can', 14.02, '2025-11-29 16:42:22', '2025-12-12', '', 'Depleted', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 17:21:26'),
(475, 61, 'MAY-20251129-001', 30.00, 50.00, 'jar', 24.20, '2025-11-29 16:42:22', '2025-12-23', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-30 22:28:25'),
(476, 62, 'CHI-20251129-001', 50.00, 50.00, 'bottle', 43.59, '2025-11-29 16:42:22', '2025-12-25', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:22', '2025-11-29 16:42:22'),
(477, 63, 'BAG-20251129-001', 50.00, 50.00, 'jar', 40.49, '2025-11-29 16:42:23', '2025-12-10', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(478, 64, 'PEA-20251129-001', 50.00, 50.00, 'jar', 46.94, '2025-11-29 16:42:23', '2025-12-26', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(479, 65, 'LIV-20251129-001', 0.00, 50.00, 'can', 37.53, '2025-11-29 16:42:23', '2025-12-23', '', 'Depleted', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-30 22:28:25'),
(480, 66, 'ACH-20251129-001', 50.00, 50.00, 'boxes', 40.48, '2025-11-29 16:42:23', '2025-12-16', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(481, 67, 'WOR-20251129-001', 50.00, 50.00, 'bottle', 21.46, '2025-11-29 16:42:23', '2025-12-26', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(482, 68, 'HOT-20251129-001', 50.00, 50.00, 'bottle', 33.39, '2025-11-29 16:42:23', '2025-12-10', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(483, 69, 'BBQ-20251129-001', 50.00, 50.00, 'bottle', 31.26, '2025-11-29 16:42:23', '2025-12-26', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(484, 70, 'GRA-20251129-001', 50.00, 50.00, 'pack', 43.52, '2025-11-29 16:42:23', '2025-12-17', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(485, 71, 'EVA-20251129-001', 50.00, 50.00, 'can', 15.55, '2025-11-29 16:42:23', '2025-12-06', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(486, 72, 'CON-20251129-001', 50.00, 50.00, 'can', 13.69, '2025-11-29 16:42:23', '2025-12-07', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(487, 73, 'COC-20251129-001', 50.00, 50.00, 'liter', 30.20, '2025-11-29 16:42:23', '2025-12-05', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(488, 74, 'COC-20251129-001', 50.00, 50.00, 'can', 40.63, '2025-11-29 16:42:23', '2025-12-20', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(489, 75, 'BUT-20251129-001', 50.00, 50.00, 'kg', 10.06, '2025-11-29 16:42:23', '2025-12-04', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(490, 76, 'CHE-20251129-001', 0.00, 50.00, 'kg', 15.52, '2025-11-29 16:42:23', '2025-12-19', '', 'Depleted', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-30 22:28:25'),
(491, 77, 'FRE-20251129-001', 50.00, 50.00, 'liter', 34.40, '2025-11-29 16:42:23', '2025-12-09', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(492, 78, 'COF-20251129-001', 50.00, 50.00, 'kg', 23.95, '2025-11-29 16:42:23', '2025-12-04', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(493, 79, 'TEA-20251129-001', 50.00, 50.00, 'box', 15.49, '2025-11-29 16:42:23', '2025-12-18', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(494, 80, 'ICE-20251129-001', 50.00, 50.00, 'kg', 28.73, '2025-11-29 16:42:23', '2025-12-19', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(495, 81, 'MAN-20251129-001', 50.00, 50.00, 'kg', 36.47, '2025-11-29 16:42:23', '2025-12-15', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(496, 82, 'CHO-20251129-001', 50.00, 50.00, 'kg', 24.31, '2025-11-29 16:42:23', '2025-12-13', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:23', '2025-11-29 16:42:23'),
(497, 83, 'SOF-20251129-001', 50.00, 50.00, 'case', 43.69, '2025-11-29 16:42:24', '2025-12-05', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(498, 84, 'MIN-20251129-001', 50.00, 50.00, 'case', 41.39, '2025-11-29 16:42:24', '2025-12-22', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(499, 85, 'BUK-20251129-001', 50.00, 50.00, 'liter', 23.19, '2025-11-29 16:42:24', '2025-12-14', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(500, 86, 'COO-20251129-001', 0.00, 50.00, 'liter', 18.18, '2025-11-29 16:42:24', '2025-12-21', '', 'Depleted', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 17:21:26'),
(501, 87, 'SAL-20251129-001', 50.00, 50.00, 'kg', 46.60, '2025-11-29 16:42:24', '2025-12-15', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(502, 88, 'SUG-20251129-001', 50.00, 50.00, 'kg', 31.90, '2025-11-29 16:42:24', '2025-12-13', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(503, 89, 'BRO-20251129-001', 50.00, 50.00, 'kg', 16.59, '2025-11-29 16:42:24', '2025-12-22', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(504, 90, 'PEP-20251129-001', 50.00, 50.00, 'kg', 18.17, '2025-11-29 16:42:24', '2025-12-24', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(505, 91, 'MSG-20251129-001', 50.00, 50.00, 'kg', 25.92, '2025-11-29 16:42:24', '2025-12-18', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(506, 92, 'FLO-20251129-001', 50.00, 50.00, 'kg', 39.00, '2025-11-29 16:42:24', '2025-12-25', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(507, 93, 'COR-20251129-001', 0.00, 50.00, 'kg', 17.71, '2025-11-29 16:42:24', '2025-12-12', '', 'Depleted', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 17:21:26'),
(508, 94, 'BRE-20251129-001', 50.00, 50.00, 'kg', 15.40, '2025-11-29 16:42:24', '2025-12-20', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(509, 95, 'LUM-20251129-001', 50.00, 50.00, 'pack', 43.17, '2025-11-29 16:42:24', '2025-12-09', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(510, 96, 'SPR-20251129-001', 46.00, 50.00, 'pack', 31.73, '2025-11-29 16:42:24', '2025-12-06', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-30 22:28:25'),
(511, 97, 'LEC-20251129-001', 50.00, 50.00, 'pack', 44.37, '2025-11-29 16:42:24', '2025-12-04', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(512, 98, 'GUL-20251129-001', 50.00, 50.00, 'pack', 27.52, '2025-11-29 16:42:24', '2025-12-08', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(513, 99, 'SAG-20251129-001', 50.00, 50.00, 'kg', 33.52, '2025-11-29 16:42:24', '2025-12-13', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(514, 100, 'KAO-20251129-001', 50.00, 50.00, 'jar', 19.13, '2025-11-29 16:42:24', '2025-12-27', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(515, 101, 'NAT-20251129-001', 50.00, 50.00, 'jar', 11.76, '2025-11-29 16:42:24', '2025-12-13', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:24', '2025-11-29 16:42:24'),
(516, 102, 'UBE-20251129-001', 50.00, 50.00, 'kg', 41.30, '2025-11-29 16:42:25', '2025-12-23', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:25', '2025-11-29 16:42:25'),
(517, 103, 'LAN-20251129-001', 50.00, 50.00, 'kg', 28.86, '2025-11-29 16:42:25', '2025-12-05', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:25', '2025-11-29 16:42:25'),
(518, 104, 'MAC-20251129-001', 50.00, 50.00, 'jar', 46.71, '2025-11-29 16:42:25', '2025-12-13', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:25', '2025-11-29 16:42:25'),
(519, 105, 'ICE-20251129-001', 50.00, 50.00, 'liter', 17.73, '2025-11-29 16:42:26', '2025-12-23', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(520, 106, 'SHA-20251129-001', 50.00, 50.00, 'kg', 26.47, '2025-11-29 16:42:26', '2025-12-20', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(521, 107, 'BAN-20251129-001', 50.00, 50.00, 'kg', 13.35, '2025-11-29 16:42:26', '2025-12-14', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(522, 108, 'TUR-20251129-001', 50.00, 50.00, 'pack', 45.46, '2025-11-29 16:42:26', '2025-12-07', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(523, 109, 'CHI-20251129-001', 50.00, 50.00, 'liter', 13.58, '2025-11-29 16:42:26', '2025-12-28', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(524, 110, 'POR-20251129-001', 50.00, 50.00, 'liter', 38.87, '2025-11-29 16:42:26', '2025-12-19', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(525, 111, 'BEE-20251129-001', 50.00, 50.00, 'liter', 46.24, '2025-11-29 16:42:26', '2025-12-21', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(526, 112, 'TAM-20251129-001', 50.00, 50.00, 'pack', 38.70, '2025-11-29 16:42:26', '2025-12-17', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(527, 113, 'MIS-20251129-001', 50.00, 50.00, 'kg', 29.12, '2025-11-29 16:42:26', '2025-12-24', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(528, 114, 'LEM-20251129-001', 50.00, 50.00, 'bundle', 34.93, '2025-11-29 16:42:26', '2025-12-21', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(529, 115, 'BAY-20251129-001', 50.00, 50.00, 'pack', 31.65, '2025-11-29 16:42:26', '2025-12-20', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(530, 116, 'PAP-20251129-001', 50.00, 50.00, 'kg', 36.88, '2025-11-29 16:42:26', '2025-12-13', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(531, 117, 'CUM-20251129-001', 50.00, 50.00, 'kg', 45.85, '2025-11-29 16:42:26', '2025-12-12', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(532, 118, 'ORE-20251129-001', 50.00, 50.00, 'pack', 49.19, '2025-11-29 16:42:26', '2025-12-26', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(533, 119, 'ANN-20251129-001', 50.00, 50.00, 'kg', 31.97, '2025-11-29 16:42:26', '2025-12-05', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(534, 120, 'PAN-20251129-001', 50.00, 50.00, 'bundle', 34.74, '2025-11-29 16:42:26', '2025-12-27', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(535, 142, 'SOF-20251129-001', 50.00, 50.00, 'pcs', 42.41, '2025-11-29 16:42:26', '2025-12-10', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(536, 143, 'BOT-20251129-001', 50.00, 50.00, 'pcs', 43.16, '2025-11-29 16:42:26', '2025-12-13', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(537, 144, 'PIN-20251129-001', 50.00, 50.00, 'pcs', 28.27, '2025-11-29 16:42:26', '2025-12-06', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(538, 145, 'SMB-20251129-001', 50.00, 50.00, 'bottle', 18.75, '2025-11-29 16:42:26', '2025-12-22', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(539, 146, 'RED-20251129-001', 50.00, 50.00, 'bottle', 11.71, '2025-11-29 16:42:26', '2025-12-28', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(540, 147, 'SAN-20251129-001', 50.00, 50.00, 'bottle', 43.85, '2025-11-29 16:42:26', '2025-12-10', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(541, 148, 'BEE-20251129-001', 50.00, 50.00, 'bucket', 37.65, '2025-11-29 16:42:26', '2025-12-21', '', 'Active', 'Auto-generated batch', '2025-11-29 16:42:26', '2025-11-29 16:42:26'),
(542, 66, 'ACH-20251129-002', 10.00, 10.00, 'boxes', 20.00, '2025-11-29 16:44:57', '2025-12-29', 'Freezer-Meat', 'Active', 'Additional batch added on 2025-11-29', '2025-11-29 16:44:57', '2025-11-29 16:44:57');

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
-- Stand-in structure for view `inventory_movement_details`
-- (See below for the actual view)
--
CREATE TABLE `inventory_movement_details` (
`MovementID` int(10)
,`MovementDate` datetime
,`IngredientName` varchar(100)
,`CategoryName` varchar(100)
,`BatchNumber` varchar(50)
,`ChangeType` enum('ADD','DEDUCT','ADJUST','DISCARD','TRANSFER')
,`QuantityChanged` decimal(10,2)
,`UnitType` varchar(50)
,`StockBefore` decimal(10,2)
,`StockAfter` decimal(10,2)
,`Reason` varchar(255)
,`Source` enum('POS','WEBSITE','ADMIN','SYSTEM')
,`SourceName` varchar(100)
,`OrderID` int(10)
,`ReservationID` int(10)
,`ReferenceNumber` varchar(50)
,`Notes` text
,`StorageLocation` enum('Freezer-Meat','Freezer-Seafood','Freezer-Processed','Refrigerator-Dairy','Refrigerator-Vegetables','Refrigerator-Condiments','Pantry-Dry-Goods','Pantry-Canned','Pantry-Condiments','Pantry-Spices','Pantry-Beverages')
,`ExpirationDate` date
,`MovementDirection` varchar(8)
,`AbsoluteChange` decimal(10,2)
);

-- --------------------------------------------------------

--
-- Table structure for table `inventory_movement_log`
--

CREATE TABLE `inventory_movement_log` (
  `MovementID` int(10) NOT NULL,
  `IngredientID` int(10) NOT NULL,
  `BatchID` int(10) NOT NULL,
  `ChangeType` enum('ADD','DEDUCT','ADJUST','DISCARD','TRANSFER') NOT NULL,
  `QuantityChanged` decimal(10,2) NOT NULL,
  `StockBefore` decimal(10,2) NOT NULL,
  `StockAfter` decimal(10,2) NOT NULL,
  `UnitType` varchar(50) NOT NULL,
  `Reason` varchar(255) NOT NULL,
  `Source` enum('POS','WEBSITE','ADMIN','SYSTEM') NOT NULL,
  `SourceID` int(10) DEFAULT NULL,
  `SourceName` varchar(100) DEFAULT NULL,
  `OrderID` int(10) DEFAULT NULL,
  `ReservationID` int(10) DEFAULT NULL,
  `ReferenceNumber` varchar(50) DEFAULT NULL,
  `Notes` text DEFAULT NULL,
  `MovementDate` datetime NOT NULL DEFAULT current_timestamp(),
  `CreatedBy` varchar(100) DEFAULT 'System'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `inventory_movement_log`
--

INSERT INTO `inventory_movement_log` (`MovementID`, `IngredientID`, `BatchID`, `ChangeType`, `QuantityChanged`, `StockBefore`, `StockAfter`, `UnitType`, `Reason`, `Source`, `SourceID`, `SourceName`, `OrderID`, `ReservationID`, `ReferenceNumber`, `Notes`, `MovementDate`, `CreatedBy`) VALUES
(48, 1, 415, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'POR-20251129-001', 'New batch created: POR-20251129-001 | Pork Belly | Qty: 50.00 kg | Cost: ₱38.76 | Notes: Auto-generated batch', '2025-11-29 16:42:19', 'System'),
(49, 2, 416, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'POR-20251129-001', 'New batch created: POR-20251129-001 | Pork Liempo | Qty: 50.00 kg | Cost: ₱40.18 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(50, 3, 417, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CHI-20251129-001', 'New batch created: CHI-20251129-001 | Chicken Whole | Qty: 50.00 kg | Cost: ₱44.68 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(51, 4, 418, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CHI-20251129-001', 'New batch created: CHI-20251129-001 | Chicken Wings | Qty: 50.00 kg | Cost: ₱37.27 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(52, 5, 419, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CHI-20251129-001', 'New batch created: CHI-20251129-001 | Chicken Breast | Qty: 50.00 kg | Cost: ₱16.08 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(53, 6, 420, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'POR-20251129-001', 'New batch created: POR-20251129-001 | Pork Sisig Meat | Qty: 50.00 kg | Cost: ₱39.99 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(54, 7, 421, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BAN-20251129-001', 'New batch created: BAN-20251129-001 | Bangus (Milkfish) | Qty: 50.00 kg | Cost: ₱45.19 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(55, 8, 422, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'TIL-20251129-001', 'New batch created: TIL-20251129-001 | Tilapia | Qty: 50.00 kg | Cost: ₱48.62 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(56, 9, 423, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SHR-20251129-001', 'New batch created: SHR-20251129-001 | Shrimp | Qty: 50.00 kg | Cost: ₱27.12 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(57, 10, 424, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SQU-20251129-001', 'New batch created: SQU-20251129-001 | Squid | Qty: 50.00 kg | Cost: ₱27.68 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(58, 11, 425, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'GRO-20251129-001', 'New batch created: GRO-20251129-001 | Ground Pork | Qty: 50.00 kg | Cost: ₱31.91 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(59, 12, 426, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BEE-20251129-001', 'New batch created: BEE-20251129-001 | Beef | Qty: 50.00 kg | Cost: ₱27.12 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(60, 13, 427, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'POR-20251129-001', 'New batch created: POR-20251129-001 | Pork Knuckle (Pata) | Qty: 50.00 kg | Cost: ₱18.09 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(61, 14, 428, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'POR-20251129-001', 'New batch created: POR-20251129-001 | Pork Ribs | Qty: 50.00 kg | Cost: ₱49.62 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(62, 15, 429, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'TOC-20251129-001', 'New batch created: TOC-20251129-001 | Tocino Meat | Qty: 50.00 kg | Cost: ₱49.89 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(63, 16, 430, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'TAP-20251129-001', 'New batch created: TAP-20251129-001 | Tapa Meat | Qty: 50.00 kg | Cost: ₱11.42 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(64, 17, 431, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'LON-20251129-001', 'New batch created: LON-20251129-001 | Longganisa | Qty: 50.00 kg | Cost: ₱37.86 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(65, 18, 432, 'ADD', 50.00, 0.00, 50.00, 'pack', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'HOT-20251129-001', 'New batch created: HOT-20251129-001 | Hotdog | Qty: 50.00 pack | Cost: ₱46.58 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(66, 19, 433, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BAC-20251129-001', 'New batch created: BAC-20251129-001 | Bacon | Qty: 50.00 kg | Cost: ₱14.30 | Notes: Auto-generated batch', '2025-11-29 16:42:20', 'System'),
(67, 20, 434, 'ADD', 50.00, 0.00, 50.00, 'can', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'COR-20251129-001', 'New batch created: COR-20251129-001 | Corned Beef | Qty: 50.00 can | Cost: ₱42.41 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(68, 21, 435, 'ADD', 50.00, 0.00, 50.00, 'can', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SPA-20251129-001', 'New batch created: SPA-20251129-001 | Spam | Qty: 50.00 can | Cost: ₱27.05 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(69, 22, 436, 'ADD', 50.00, 0.00, 50.00, 'tray', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'EGG-20251129-001', 'New batch created: EGG-20251129-001 | Eggs | Qty: 50.00 tray | Cost: ₱42.37 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(70, 23, 437, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'DRI-20251129-001', 'New batch created: DRI-20251129-001 | Dried Fish (Tuyo) | Qty: 50.00 kg | Cost: ₱31.51 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(71, 24, 438, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'DAN-20251129-001', 'New batch created: DAN-20251129-001 | Danggit | Qty: 50.00 kg | Cost: ₱47.29 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(72, 25, 439, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'RIC-20251129-001', 'New batch created: RIC-20251129-001 | Rice | Qty: 50.00 kg | Cost: ₱44.94 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(73, 26, 440, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'GAR-20251129-001', 'New batch created: GAR-20251129-001 | Garlic Rice Mix | Qty: 50.00 kg | Cost: ₱18.21 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(74, 27, 441, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'PAN-20251129-001', 'New batch created: PAN-20251129-001 | Pancit Canton Noodles | Qty: 50.00 kg | Cost: ₱11.52 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(75, 28, 442, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'PAN-20251129-001', 'New batch created: PAN-20251129-001 | Pancit Bihon Noodles | Qty: 50.00 kg | Cost: ₱45.08 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(76, 29, 443, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SOT-20251129-001', 'New batch created: SOT-20251129-001 | Sotanghon Noodles | Qty: 50.00 kg | Cost: ₱22.80 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(77, 30, 444, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SPA-20251129-001', 'New batch created: SPA-20251129-001 | Spaghetti Noodles | Qty: 50.00 kg | Cost: ₱17.44 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(78, 31, 445, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'ONI-20251129-001', 'New batch created: ONI-20251129-001 | Onion | Qty: 50.00 kg | Cost: ₱36.22 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(79, 32, 446, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'GAR-20251129-001', 'New batch created: GAR-20251129-001 | Garlic | Qty: 50.00 kg | Cost: ₱41.21 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(80, 33, 447, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'TOM-20251129-001', 'New batch created: TOM-20251129-001 | Tomato | Qty: 50.00 kg | Cost: ₱46.98 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(81, 34, 448, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'GIN-20251129-001', 'New batch created: GIN-20251129-001 | Ginger | Qty: 50.00 kg | Cost: ₱31.70 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(82, 35, 449, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CAB-20251129-001', 'New batch created: CAB-20251129-001 | Cabbage | Qty: 50.00 kg | Cost: ₱49.58 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(83, 36, 450, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CAR-20251129-001', 'New batch created: CAR-20251129-001 | Carrots | Qty: 50.00 kg | Cost: ₱46.77 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(84, 37, 451, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SAY-20251129-001', 'New batch created: SAY-20251129-001 | Sayote (Chayote) | Qty: 50.00 kg | Cost: ₱32.35 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(85, 38, 452, 'ADD', 50.00, 0.00, 50.00, 'bundle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'KAN-20251129-001', 'New batch created: KAN-20251129-001 | Kangkong | Qty: 50.00 bundle | Cost: ₱23.82 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(86, 39, 453, 'ADD', 50.00, 0.00, 50.00, 'bundle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'PEC-20251129-001', 'New batch created: PEC-20251129-001 | Pechay | Qty: 50.00 bundle | Cost: ₱31.39 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(87, 40, 454, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'GRE-20251129-001', 'New batch created: GRE-20251129-001 | Green Beans (Sitaw) | Qty: 50.00 kg | Cost: ₱12.06 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(88, 41, 455, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'EGG-20251129-001', 'New batch created: EGG-20251129-001 | Eggplant | Qty: 50.00 kg | Cost: ₱16.67 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(89, 42, 456, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'AMP-20251129-001', 'New batch created: AMP-20251129-001 | Ampalaya (Bitter Gourd) | Qty: 50.00 kg | Cost: ₱38.21 | Notes: Auto-generated batch', '2025-11-29 16:42:21', 'System'),
(90, 43, 457, 'ADD', 50.00, 0.00, 50.00, 'bundle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'MAL-20251129-001', 'New batch created: MAL-20251129-001 | Malunggay Leaves | Qty: 50.00 bundle | Cost: ₱45.96 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(91, 44, 458, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'GRE-20251129-001', 'New batch created: GRE-20251129-001 | Green Papaya | Qty: 50.00 kg | Cost: ₱39.32 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(92, 45, 459, 'ADD', 50.00, 0.00, 50.00, 'pc', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BAN-20251129-001', 'New batch created: BAN-20251129-001 | Banana Blossom | Qty: 50.00 pc | Cost: ₱43.49 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(93, 46, 460, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'TAL-20251129-001', 'New batch created: TAL-20251129-001 | Talong (Eggplant) | Qty: 50.00 kg | Cost: ₱22.42 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(94, 47, 461, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BEL-20251129-001', 'New batch created: BEL-20251129-001 | Bell Pepper | Qty: 50.00 kg | Cost: ₱24.53 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(95, 48, 462, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CHI-20251129-001', 'New batch created: CHI-20251129-001 | Chili Peppers | Qty: 50.00 kg | Cost: ₱14.24 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(96, 49, 463, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CAL-20251129-001', 'New batch created: CAL-20251129-001 | Calamansi | Qty: 50.00 kg | Cost: ₱39.76 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(97, 50, 464, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'LEM-20251129-001', 'New batch created: LEM-20251129-001 | Lemon | Qty: 50.00 kg | Cost: ₱17.34 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(98, 51, 465, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'LET-20251129-001', 'New batch created: LET-20251129-001 | Lettuce | Qty: 50.00 kg | Cost: ₱41.69 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(99, 52, 466, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CUC-20251129-001', 'New batch created: CUC-20251129-001 | Cucumber | Qty: 50.00 kg | Cost: ₱26.02 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(100, 53, 467, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'POT-20251129-001', 'New batch created: POT-20251129-001 | Potato | Qty: 50.00 kg | Cost: ₱29.13 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(101, 54, 468, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'COR-20251129-001', 'New batch created: COR-20251129-001 | Corn | Qty: 50.00 kg | Cost: ₱29.32 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(102, 55, 469, 'ADD', 50.00, 0.00, 50.00, 'liter', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SOY-20251129-001', 'New batch created: SOY-20251129-001 | Soy Sauce | Qty: 50.00 liter | Cost: ₱44.81 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(103, 56, 470, 'ADD', 50.00, 0.00, 50.00, 'liter', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'VIN-20251129-001', 'New batch created: VIN-20251129-001 | Vinegar | Qty: 50.00 liter | Cost: ₱17.64 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(104, 57, 471, 'ADD', 50.00, 0.00, 50.00, 'liter', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'FIS-20251129-001', 'New batch created: FIS-20251129-001 | Fish Sauce (Patis) | Qty: 50.00 liter | Cost: ₱41.86 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(105, 58, 472, 'ADD', 50.00, 0.00, 50.00, 'bottle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'OYS-20251129-001', 'New batch created: OYS-20251129-001 | Oyster Sauce | Qty: 50.00 bottle | Cost: ₱26.63 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(106, 59, 473, 'ADD', 50.00, 0.00, 50.00, 'bottle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BAN-20251129-001', 'New batch created: BAN-20251129-001 | Banana Ketchup | Qty: 50.00 bottle | Cost: ₱39.14 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(107, 60, 474, 'ADD', 50.00, 0.00, 50.00, 'can', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'TOM-20251129-001', 'New batch created: TOM-20251129-001 | Tomato Sauce | Qty: 50.00 can | Cost: ₱14.02 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(108, 61, 475, 'ADD', 50.00, 0.00, 50.00, 'jar', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'MAY-20251129-001', 'New batch created: MAY-20251129-001 | Mayonnaise | Qty: 50.00 jar | Cost: ₱24.20 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(109, 62, 476, 'ADD', 50.00, 0.00, 50.00, 'bottle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CHI-20251129-001', 'New batch created: CHI-20251129-001 | Chili Garlic Sauce | Qty: 50.00 bottle | Cost: ₱43.59 | Notes: Auto-generated batch', '2025-11-29 16:42:22', 'System'),
(110, 63, 477, 'ADD', 50.00, 0.00, 50.00, 'jar', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BAG-20251129-001', 'New batch created: BAG-20251129-001 | Bagoong (Shrimp Paste) | Qty: 50.00 jar | Cost: ₱40.49 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(111, 64, 478, 'ADD', 50.00, 0.00, 50.00, 'jar', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'PEA-20251129-001', 'New batch created: PEA-20251129-001 | Peanut Butter | Qty: 50.00 jar | Cost: ₱46.94 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(112, 65, 479, 'ADD', 50.00, 0.00, 50.00, 'can', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'LIV-20251129-001', 'New batch created: LIV-20251129-001 | Liver Spread | Qty: 50.00 can | Cost: ₱37.53 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(113, 66, 480, 'ADD', 50.00, 0.00, 50.00, 'boxes', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'ACH-20251129-001', 'New batch created: ACH-20251129-001 | Achuete (Annatto) Oil | Qty: 50.00 boxes | Cost: ₱40.48 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(114, 67, 481, 'ADD', 50.00, 0.00, 50.00, 'bottle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'WOR-20251129-001', 'New batch created: WOR-20251129-001 | Worcestershire Sauce | Qty: 50.00 bottle | Cost: ₱21.46 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(115, 68, 482, 'ADD', 50.00, 0.00, 50.00, 'bottle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'HOT-20251129-001', 'New batch created: HOT-20251129-001 | Hot Sauce | Qty: 50.00 bottle | Cost: ₱33.39 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(116, 69, 483, 'ADD', 50.00, 0.00, 50.00, 'bottle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BBQ-20251129-001', 'New batch created: BBQ-20251129-001 | BBQ Sauce | Qty: 50.00 bottle | Cost: ₱31.26 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(117, 70, 484, 'ADD', 50.00, 0.00, 50.00, 'pack', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'GRA-20251129-001', 'New batch created: GRA-20251129-001 | Gravy Mix | Qty: 50.00 pack | Cost: ₱43.52 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(118, 71, 485, 'ADD', 50.00, 0.00, 50.00, 'can', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'EVA-20251129-001', 'New batch created: EVA-20251129-001 | Evaporated Milk | Qty: 50.00 can | Cost: ₱15.55 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(119, 72, 486, 'ADD', 50.00, 0.00, 50.00, 'can', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CON-20251129-001', 'New batch created: CON-20251129-001 | Condensed Milk | Qty: 50.00 can | Cost: ₱13.69 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(120, 73, 487, 'ADD', 50.00, 0.00, 50.00, 'liter', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'COC-20251129-001', 'New batch created: COC-20251129-001 | Coconut Milk | Qty: 50.00 liter | Cost: ₱30.20 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(121, 74, 488, 'ADD', 50.00, 0.00, 50.00, 'can', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'COC-20251129-001', 'New batch created: COC-20251129-001 | Coconut Cream | Qty: 50.00 can | Cost: ₱40.63 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(122, 75, 489, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BUT-20251129-001', 'New batch created: BUT-20251129-001 | Butter | Qty: 50.00 kg | Cost: ₱10.06 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(123, 76, 490, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CHE-20251129-001', 'New batch created: CHE-20251129-001 | Cheese | Qty: 50.00 kg | Cost: ₱15.52 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(124, 77, 491, 'ADD', 50.00, 0.00, 50.00, 'liter', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'FRE-20251129-001', 'New batch created: FRE-20251129-001 | Fresh Milk | Qty: 50.00 liter | Cost: ₱34.40 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(125, 78, 492, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'COF-20251129-001', 'New batch created: COF-20251129-001 | Coffee | Qty: 50.00 kg | Cost: ₱23.95 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(126, 79, 493, 'ADD', 50.00, 0.00, 50.00, 'box', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'TEA-20251129-001', 'New batch created: TEA-20251129-001 | Tea Bags | Qty: 50.00 box | Cost: ₱15.49 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(127, 80, 494, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'ICE-20251129-001', 'New batch created: ICE-20251129-001 | Iced Tea Powder | Qty: 50.00 kg | Cost: ₱28.73 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(128, 81, 495, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'MAN-20251129-001', 'New batch created: MAN-20251129-001 | Mango Shake Mix | Qty: 50.00 kg | Cost: ₱36.47 | Notes: Auto-generated batch', '2025-11-29 16:42:23', 'System'),
(129, 82, 496, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CHO-20251129-001', 'New batch created: CHO-20251129-001 | Chocolate Powder | Qty: 50.00 kg | Cost: ₱24.31 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(130, 83, 497, 'ADD', 50.00, 0.00, 50.00, 'case', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SOF-20251129-001', 'New batch created: SOF-20251129-001 | Soft Drinks | Qty: 50.00 case | Cost: ₱43.69 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(131, 84, 498, 'ADD', 50.00, 0.00, 50.00, 'case', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'MIN-20251129-001', 'New batch created: MIN-20251129-001 | Mineral Water | Qty: 50.00 case | Cost: ₱41.39 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(132, 85, 499, 'ADD', 50.00, 0.00, 50.00, 'liter', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BUK-20251129-001', 'New batch created: BUK-20251129-001 | Buko Juice | Qty: 50.00 liter | Cost: ₱23.19 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(133, 86, 500, 'ADD', 50.00, 0.00, 50.00, 'liter', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'COO-20251129-001', 'New batch created: COO-20251129-001 | Cooking Oil | Qty: 50.00 liter | Cost: ₱18.18 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(134, 87, 501, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SAL-20251129-001', 'New batch created: SAL-20251129-001 | Salt | Qty: 50.00 kg | Cost: ₱46.60 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(135, 88, 502, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SUG-20251129-001', 'New batch created: SUG-20251129-001 | Sugar | Qty: 50.00 kg | Cost: ₱31.90 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(136, 89, 503, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BRO-20251129-001', 'New batch created: BRO-20251129-001 | Brown Sugar | Qty: 50.00 kg | Cost: ₱16.59 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(137, 90, 504, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'PEP-20251129-001', 'New batch created: PEP-20251129-001 | Pepper | Qty: 50.00 kg | Cost: ₱18.17 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(138, 91, 505, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'MSG-20251129-001', 'New batch created: MSG-20251129-001 | MSG | Qty: 50.00 kg | Cost: ₱25.92 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(139, 92, 506, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'FLO-20251129-001', 'New batch created: FLO-20251129-001 | Flour | Qty: 50.00 kg | Cost: ₱39.00 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(140, 93, 507, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'COR-20251129-001', 'New batch created: COR-20251129-001 | Cornstarch | Qty: 50.00 kg | Cost: ₱17.71 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(141, 94, 508, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BRE-20251129-001', 'New batch created: BRE-20251129-001 | Bread Crumbs | Qty: 50.00 kg | Cost: ₱15.40 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(142, 95, 509, 'ADD', 50.00, 0.00, 50.00, 'pack', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'LUM-20251129-001', 'New batch created: LUM-20251129-001 | Lumpia Wrapper | Qty: 50.00 pack | Cost: ₱43.17 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(143, 96, 510, 'ADD', 50.00, 0.00, 50.00, 'pack', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SPR-20251129-001', 'New batch created: SPR-20251129-001 | Spring Roll Wrapper | Qty: 50.00 pack | Cost: ₱31.73 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(144, 97, 511, 'ADD', 50.00, 0.00, 50.00, 'pack', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'LEC-20251129-001', 'New batch created: LEC-20251129-001 | Leche Flan Mix | Qty: 50.00 pack | Cost: ₱44.37 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(145, 98, 512, 'ADD', 50.00, 0.00, 50.00, 'pack', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'GUL-20251129-001', 'New batch created: GUL-20251129-001 | Gulaman (Agar) | Qty: 50.00 pack | Cost: ₱27.52 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(146, 99, 513, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SAG-20251129-001', 'New batch created: SAG-20251129-001 | Sago Pearls | Qty: 50.00 kg | Cost: ₱33.52 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(147, 100, 514, 'ADD', 50.00, 0.00, 50.00, 'jar', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'KAO-20251129-001', 'New batch created: KAO-20251129-001 | Kaong (Palm Fruit) | Qty: 50.00 jar | Cost: ₱19.13 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(148, 101, 515, 'ADD', 50.00, 0.00, 50.00, 'jar', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'NAT-20251129-001', 'New batch created: NAT-20251129-001 | Nata de Coco | Qty: 50.00 jar | Cost: ₱11.76 | Notes: Auto-generated batch', '2025-11-29 16:42:24', 'System'),
(149, 102, 516, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'UBE-20251129-001', 'New batch created: UBE-20251129-001 | Ube Halaya | Qty: 50.00 kg | Cost: ₱41.30 | Notes: Auto-generated batch', '2025-11-29 16:42:25', 'System'),
(150, 103, 517, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'LAN-20251129-001', 'New batch created: LAN-20251129-001 | Langka (Jackfruit) | Qty: 50.00 kg | Cost: ₱28.86 | Notes: Auto-generated batch', '2025-11-29 16:42:25', 'System'),
(151, 104, 518, 'ADD', 50.00, 0.00, 50.00, 'jar', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'MAC-20251129-001', 'New batch created: MAC-20251129-001 | Macapuno | Qty: 50.00 jar | Cost: ₱46.71 | Notes: Auto-generated batch', '2025-11-29 16:42:25', 'System'),
(152, 105, 519, 'ADD', 50.00, 0.00, 50.00, 'liter', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'ICE-20251129-001', 'New batch created: ICE-20251129-001 | Ice Cream | Qty: 50.00 liter | Cost: ₱17.73 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(153, 106, 520, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SHA-20251129-001', 'New batch created: SHA-20251129-001 | Shaved Ice | Qty: 50.00 kg | Cost: ₱26.47 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(154, 107, 521, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BAN-20251129-001', 'New batch created: BAN-20251129-001 | Banana | Qty: 50.00 kg | Cost: ₱13.35 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(155, 108, 522, 'ADD', 50.00, 0.00, 50.00, 'pack', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'TUR-20251129-001', 'New batch created: TUR-20251129-001 | Turon Wrapper | Qty: 50.00 pack | Cost: ₱45.46 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(156, 109, 523, 'ADD', 50.00, 0.00, 50.00, 'liter', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CHI-20251129-001', 'New batch created: CHI-20251129-001 | Chicken Broth | Qty: 50.00 liter | Cost: ₱13.58 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(157, 110, 524, 'ADD', 50.00, 0.00, 50.00, 'liter', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'POR-20251129-001', 'New batch created: POR-20251129-001 | Pork Broth | Qty: 50.00 liter | Cost: ₱38.87 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(158, 111, 525, 'ADD', 50.00, 0.00, 50.00, 'liter', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BEE-20251129-001', 'New batch created: BEE-20251129-001 | Beef Broth | Qty: 50.00 liter | Cost: ₱46.24 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(159, 112, 526, 'ADD', 50.00, 0.00, 50.00, 'pack', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'TAM-20251129-001', 'New batch created: TAM-20251129-001 | Tamarind Mix (Sinigang) | Qty: 50.00 pack | Cost: ₱38.70 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(160, 113, 527, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'MIS-20251129-001', 'New batch created: MIS-20251129-001 | Miso Paste | Qty: 50.00 kg | Cost: ₱29.12 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(161, 114, 528, 'ADD', 50.00, 0.00, 50.00, 'bundle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'LEM-20251129-001', 'New batch created: LEM-20251129-001 | Lemongrass | Qty: 50.00 bundle | Cost: ₱34.93 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(162, 115, 529, 'ADD', 50.00, 0.00, 50.00, 'pack', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BAY-20251129-001', 'New batch created: BAY-20251129-001 | Bay Leaves | Qty: 50.00 pack | Cost: ₱31.65 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(163, 116, 530, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'PAP-20251129-001', 'New batch created: PAP-20251129-001 | Paprika | Qty: 50.00 kg | Cost: ₱36.88 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(164, 117, 531, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'CUM-20251129-001', 'New batch created: CUM-20251129-001 | Cumin | Qty: 50.00 kg | Cost: ₱45.85 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(165, 118, 532, 'ADD', 50.00, 0.00, 50.00, 'pack', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'ORE-20251129-001', 'New batch created: ORE-20251129-001 | Oregano | Qty: 50.00 pack | Cost: ₱49.19 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(166, 119, 533, 'ADD', 50.00, 0.00, 50.00, 'kg', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'ANN-20251129-001', 'New batch created: ANN-20251129-001 | Annatto Seeds | Qty: 50.00 kg | Cost: ₱31.97 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(167, 120, 534, 'ADD', 50.00, 0.00, 50.00, 'bundle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'PAN-20251129-001', 'New batch created: PAN-20251129-001 | Pandan Leaves | Qty: 50.00 bundle | Cost: ₱34.74 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(168, 142, 535, 'ADD', 50.00, 0.00, 50.00, 'pcs', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SOF-20251129-001', 'New batch created: SOF-20251129-001 | Soft Drink (Can) | Qty: 50.00 pcs | Cost: ₱42.41 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(169, 143, 536, 'ADD', 50.00, 0.00, 50.00, 'pcs', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BOT-20251129-001', 'New batch created: BOT-20251129-001 | Bottled Water | Qty: 50.00 pcs | Cost: ₱43.16 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(170, 144, 537, 'ADD', 50.00, 0.00, 50.00, 'pcs', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'PIN-20251129-001', 'New batch created: PIN-20251129-001 | Pineapple Juice (Bottle) | Qty: 50.00 pcs | Cost: ₱28.27 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(171, 145, 538, 'ADD', 50.00, 0.00, 50.00, 'bottle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SMB-20251129-001', 'New batch created: SMB-20251129-001 | SMB Pale Pilsen | Qty: 50.00 bottle | Cost: ₱18.75 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(172, 146, 539, 'ADD', 50.00, 0.00, 50.00, 'bottle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'RED-20251129-001', 'New batch created: RED-20251129-001 | Red Horse Stallion | Qty: 50.00 bottle | Cost: ₱11.71 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(173, 147, 540, 'ADD', 50.00, 0.00, 50.00, 'bottle', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'SAN-20251129-001', 'New batch created: SAN-20251129-001 | San Mig Light | Qty: 50.00 bottle | Cost: ₱43.85 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(174, 148, 541, 'ADD', 50.00, 0.00, 50.00, 'bucket', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'BEE-20251129-001', 'New batch created: BEE-20251129-001 | Beer Bucket (6 Bottles) | Qty: 50.00 bucket | Cost: ₱37.65 | Notes: Auto-generated batch', '2025-11-29 16:42:26', 'System'),
(175, 66, 542, 'ADD', 10.00, 50.00, 60.00, 'boxes', 'New Batch Purchase', 'ADMIN', NULL, 'Admin User', NULL, NULL, 'ACH-20251129-002', 'New batch created: ACH-20251129-002 | Achuete (Annatto) Oil | Qty: 10.00 boxes | Cost: ₱20.00 | Notes: Additional batch added on 2025-11-29', '2025-11-29 16:44:57', 'System'),
(176, 30, 444, 'DEDUCT', -50.00, 50.00, 0.00, 'g', 'Website Reservation Confirmed - S-E (w/ Chicken & Fries)', 'WEBSITE', 8, 'Ronal Sevill', NULL, 6, 'RES-6', 'Batch: SPA-20251129-001 | Product: S-E (w/ Chicken & Fries) (Qty: 1) | Ingredient: Spaghetti Noodles', '2025-11-29 17:21:26', 'System'),
(177, 60, 474, 'DEDUCT', -50.00, 50.00, 0.00, 'g', 'Website Reservation Confirmed - S-E (w/ Chicken & Fries)', 'WEBSITE', 8, 'Ronal Sevill', NULL, 6, 'RES-6', 'Batch: TOM-20251129-001 | Product: S-E (w/ Chicken & Fries) (Qty: 1) | Ingredient: Tomato Sauce', '2025-11-29 17:21:26', 'System'),
(178, 65, 479, 'DEDUCT', -20.00, 50.00, 30.00, 'g', 'Website Reservation Confirmed - S-E (w/ Chicken & Fries)', 'WEBSITE', 8, 'Ronal Sevill', NULL, 6, 'RES-6', 'Batch: LIV-20251129-001 | Product: S-E (w/ Chicken & Fries) (Qty: 1) | Ingredient: Liver Spread', '2025-11-29 17:21:26', 'System'),
(179, 5, 419, 'DEDUCT', -50.00, 50.00, 0.00, 'g', 'Website Reservation Confirmed - S-E (w/ Chicken & Fries)', 'WEBSITE', 8, 'Ronal Sevill', NULL, 6, 'RES-6', 'Batch: CHI-20251129-001 | Product: S-E (w/ Chicken & Fries) (Qty: 1) | Ingredient: Chicken Breast', '2025-11-29 17:21:26', 'System'),
(180, 53, 467, 'DEDUCT', -50.00, 50.00, 0.00, 'g', 'Website Reservation Confirmed - S-E (w/ Chicken & Fries)', 'WEBSITE', 8, 'Ronal Sevill', NULL, 6, 'RES-6', 'Batch: POT-20251129-001 | Product: S-E (w/ Chicken & Fries) (Qty: 1) | Ingredient: Potato', '2025-11-29 17:21:26', 'System'),
(181, 93, 507, 'DEDUCT', -30.00, 50.00, 20.00, 'g', 'Website Reservation Confirmed - S-E (w/ Chicken & Fries)', 'WEBSITE', 8, 'Ronal Sevill', NULL, 6, 'RES-6', 'Batch: COR-20251129-001 | Product: S-E (w/ Chicken & Fries) (Qty: 1) | Ingredient: Cornstarch', '2025-11-29 17:21:26', 'System'),
(182, 86, 500, 'DEDUCT', -50.00, 50.00, 0.00, 'ml', 'Website Reservation Confirmed - S-E (w/ Chicken & Fries)', 'WEBSITE', 8, 'Ronal Sevill', NULL, 6, 'RES-6', 'Batch: COO-20251129-001 | Product: S-E (w/ Chicken & Fries) (Qty: 1) | Ingredient: Cooking Oil', '2025-11-29 17:21:26', 'System'),
(183, 65, 479, 'DEDUCT', -20.00, 30.00, 10.00, 'g', 'Website Reservation Confirmed - S-H (Chicken, Pizza Roll & Fries)', 'WEBSITE', 8, 'Ronal Sevill', NULL, 6, 'RES-6', 'Batch: LIV-20251129-001 | Product: S-H (Chicken, Pizza Roll & Fries) (Qty: 1) | Ingredient: Liver Spread', '2025-11-29 17:21:26', 'System'),
(184, 76, 490, 'DEDUCT', -20.00, 50.00, 30.00, 'g', 'Website Reservation Confirmed - S-H (Chicken, Pizza Roll & Fries)', 'WEBSITE', 8, 'Ronal Sevill', NULL, 6, 'RES-6', 'Batch: CHE-20251129-001 | Product: S-H (Chicken, Pizza Roll & Fries) (Qty: 1) | Ingredient: Cheese', '2025-11-29 17:21:26', 'System'),
(185, 93, 507, 'DEDUCT', -20.00, 20.00, 0.00, 'g', 'Website Reservation Confirmed - S-H (Chicken, Pizza Roll & Fries)', 'WEBSITE', 8, 'Ronal Sevill', NULL, 6, 'RES-6', 'Batch: COR-20251129-001 | Product: S-H (Chicken, Pizza Roll & Fries) (Qty: 1) | Ingredient: Cornstarch', '2025-11-29 17:21:26', 'System'),
(186, 65, 479, 'DEDUCT', -10.00, 10.00, 0.00, 'g', 'POS Order - S-C (w/ Shanghai, Ham & Cheese Sandwich)', 'POS', NULL, 'POS User', 1000, NULL, 'ORD-1000', 'Batch: LIV-20251129-001 | Product: S-C (w/ Shanghai, Ham & Cheese Sandwich) (Qty: 1) | Ingredient: Liver Spread | Receipt: ORD-1000', '2025-11-30 22:28:25', 'System'),
(187, 11, 425, 'DEDUCT', -50.00, 50.00, 0.00, 'g', 'POS Order - S-C (w/ Shanghai, Ham & Cheese Sandwich)', 'POS', NULL, 'POS User', 1000, NULL, 'ORD-1000', 'Batch: GRO-20251129-001 | Product: S-C (w/ Shanghai, Ham & Cheese Sandwich) (Qty: 1) | Ingredient: Ground Pork | Receipt: ORD-1000', '2025-11-30 22:28:25', 'System'),
(188, 35, 449, 'DEDUCT', -30.00, 50.00, 20.00, 'g', 'POS Order - S-C (w/ Shanghai, Ham & Cheese Sandwich)', 'POS', NULL, 'POS User', 1000, NULL, 'ORD-1000', 'Batch: CAB-20251129-001 | Product: S-C (w/ Shanghai, Ham & Cheese Sandwich) (Qty: 1) | Ingredient: Cabbage | Receipt: ORD-1000', '2025-11-30 22:28:25', 'System'),
(189, 96, 510, 'DEDUCT', -2.00, 50.00, 48.00, 'pc', 'POS Order - S-C (w/ Shanghai, Ham & Cheese Sandwich)', 'POS', NULL, 'POS User', 1000, NULL, 'ORD-1000', 'Batch: SPR-20251129-001 | Product: S-C (w/ Shanghai, Ham & Cheese Sandwich) (Qty: 1) | Ingredient: Spring Roll Wrapper | Receipt: ORD-1000', '2025-11-30 22:28:25', 'System'),
(190, 76, 490, 'DEDUCT', -30.00, 30.00, 0.00, 'g', 'POS Order - S-C (w/ Shanghai, Ham & Cheese Sandwich)', 'POS', NULL, 'POS User', 1000, NULL, 'ORD-1000', 'Batch: CHE-20251129-001 | Product: S-C (w/ Shanghai, Ham & Cheese Sandwich) (Qty: 1) | Ingredient: Cheese | Receipt: ORD-1000', '2025-11-30 22:28:25', 'System'),
(191, 61, 475, 'DEDUCT', -20.00, 50.00, 30.00, 'g', 'POS Order - S-C (w/ Shanghai, Ham & Cheese Sandwich)', 'POS', NULL, 'POS User', 1000, NULL, 'ORD-1000', 'Batch: MAY-20251129-001 | Product: S-C (w/ Shanghai, Ham & Cheese Sandwich) (Qty: 1) | Ingredient: Mayonnaise | Receipt: ORD-1000', '2025-11-30 22:28:25', 'System'),
(192, 35, 449, 'DEDUCT', -20.00, 20.00, 0.00, 'g', 'POS Order - S-B (w/ Shanghai & Empanada)', 'POS', NULL, 'POS User', 1000, NULL, 'ORD-1000', 'Batch: CAB-20251129-001 | Product: S-B (w/ Shanghai & Empanada) (Qty: 1) | Ingredient: Cabbage | Receipt: ORD-1000', '2025-11-30 22:28:25', 'System'),
(193, 36, 450, 'DEDUCT', -20.00, 50.00, 30.00, 'g', 'POS Order - S-B (w/ Shanghai & Empanada)', 'POS', NULL, 'POS User', 1000, NULL, 'ORD-1000', 'Batch: CAR-20251129-001 | Product: S-B (w/ Shanghai & Empanada) (Qty: 1) | Ingredient: Carrots | Receipt: ORD-1000', '2025-11-30 22:28:25', 'System'),
(194, 96, 510, 'DEDUCT', -2.00, 48.00, 46.00, 'pc', 'POS Order - S-B (w/ Shanghai & Empanada)', 'POS', NULL, 'POS User', 1000, NULL, 'ORD-1000', 'Batch: SPR-20251129-001 | Product: S-B (w/ Shanghai & Empanada) (Qty: 1) | Ingredient: Spring Roll Wrapper | Receipt: ORD-1000', '2025-11-30 22:28:25', 'System'),
(195, 31, 445, 'DEDUCT', -10.00, 50.00, 40.00, 'g', 'POS Order - S-B (w/ Shanghai & Empanada)', 'POS', NULL, 'POS User', 1000, NULL, 'ORD-1000', 'Batch: ONI-20251129-001 | Product: S-B (w/ Shanghai & Empanada) (Qty: 1) | Ingredient: Onion | Receipt: ORD-1000', '2025-11-30 22:28:25', 'System');

-- --------------------------------------------------------

--
-- Stand-in structure for view `inventory_movement_summary`
-- (See below for the actual view)
--
CREATE TABLE `inventory_movement_summary` (
`MovementDay` date
,`Source` enum('POS','WEBSITE','ADMIN','SYSTEM')
,`ChangeType` enum('ADD','DEDUCT','ADJUST','DISCARD','TRANSFER')
,`TotalMovements` bigint(21)
,`TotalQuantity` decimal(32,2)
,`UniqueIngredients` bigint(21)
,`UniqueBatches` bigint(21)
);

-- --------------------------------------------------------

--
-- Table structure for table `inventory_status`
--

CREATE TABLE `inventory_status` (
  `InventoryID` int(10) DEFAULT NULL,
  `IngredientID` int(10) DEFAULT NULL,
  `IngredientName` varchar(100) DEFAULT NULL,
  `StockQuantity` decimal(10,2) DEFAULT NULL,
  `UnitType` varchar(50) DEFAULT NULL,
  `ExpirationDate` date DEFAULT NULL,
  `Status` varchar(22) DEFAULT NULL,
  `DaysUntilExpiration` int(7) DEFAULT NULL,
  `LastRestockedDate` datetime DEFAULT NULL,
  `Remarks` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
-- Table structure for table `inventory_transaction_history`
--

CREATE TABLE `inventory_transaction_history` (
  `TransactionID` int(10) DEFAULT NULL,
  `InventoryID` int(10) DEFAULT NULL,
  `IngredientName` varchar(100) DEFAULT NULL,
  `TransactionType` enum('Restock','Usage','Adjustment') DEFAULT NULL,
  `QuantityChanged` decimal(10,2) DEFAULT NULL,
  `StockBefore` decimal(10,2) DEFAULT NULL,
  `StockAfter` decimal(10,2) DEFAULT NULL,
  `UnitType` varchar(50) DEFAULT NULL,
  `Notes` text DEFAULT NULL,
  `TransactionDate` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
(105, '2025-11-27 13:16:01', 4, 'Login', 'Admin logged in'),
(0, '2025-11-28 23:33:40', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 00:50:22', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 02:05:30', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 02:13:14', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 02:15:46', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 02:26:02', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 02:30:21', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 02:33:13', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 02:36:38', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 02:49:03', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 02:54:47', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 03:05:57', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 11:01:57', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 11:53:26', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 12:17:27', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 12:24:53', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 12:55:12', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 13:22:20', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 13:30:47', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 14:32:23', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 16:30:59', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 17:03:29', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 17:04:14', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 17:11:45', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 18:47:59', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 18:56:03', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 19:05:20', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 19:08:57', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 19:11:57', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 19:15:49', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 21:53:58', 4, 'Login', 'Admin logged in'),
(0, '2025-11-29 23:41:10', 4, 'Login', 'Admin logged in'),
(0, '2025-11-30 15:04:16', 4, 'Login', 'Admin logged in'),
(0, '2025-12-01 00:44:54', 4, 'Login', 'Admin logged in');

-- --------------------------------------------------------

--
-- Table structure for table `low_stock_items`
--

CREATE TABLE `low_stock_items` (
  `InventoryID` int(10) DEFAULT NULL,
  `IngredientName` varchar(100) DEFAULT NULL,
  `StockQuantity` decimal(10,2) DEFAULT NULL,
  `UnitType` varchar(50) DEFAULT NULL,
  `LastRestockedDate` datetime DEFAULT NULL,
  `DaysSinceLastRestock` int(7) DEFAULT NULL,
  `Remarks` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
(1001, 8, NULL, 'Online', 'Website', NULL, NULL, '2025-11-23', '12:46:03', 2, 345.00, 'Completed', NULL, 'Normal', NULL, 0, '2025-11-23 12:46:03', '2025-11-30 00:28:54'),
(1002, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-29', '22:29:11', 1, 45.00, '', NULL, 'Normal', 0, 0, '2025-11-29 22:29:11', '2025-11-30 00:06:16'),
(1003, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-29', '22:53:24', 1, 45.00, '', NULL, 'Normal', 0, 0, '2025-11-29 22:53:24', '2025-11-30 00:06:16'),
(1004, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-29', '23:04:17', 1, 45.00, '', NULL, 'Normal', 0, 0, '2025-11-29 23:04:17', '2025-11-30 00:06:16'),
(1005, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-29', '23:08:37', 1, 45.00, 'Completed', NULL, 'Normal', 0, 0, '2025-11-29 23:08:37', '2025-11-30 00:46:18'),
(1006, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-29', '23:12:03', 1, 45.00, 'Completed', NULL, 'Normal', 0, 0, '2025-11-29 23:12:03', '2025-11-30 00:46:18'),
(1007, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-30', '00:46:41', 1, 360.00, '', NULL, 'Normal', 0, 0, '2025-11-30 00:46:41', '2025-11-30 00:46:45'),
(1008, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-30', '13:53:33', 2, 275.00, 'Cancelled', NULL, 'Normal', 18, 0, '2025-11-30 13:53:33', '2025-11-30 13:53:55'),
(1009, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-30', '14:48:08', 2, 290.00, 'Cancelled', NULL, 'Normal', 22, 0, '2025-11-30 14:48:08', '2025-11-30 14:48:27');

--
-- Triggers `orders`
--
DELIMITER $$
CREATE TRIGGER `tr_order_completed` AFTER UPDATE ON `orders` FOR EACH ROW BEGIN
    -- Only trigger when order status changes to 'Completed'
    IF NEW.OrderStatus = 'Completed' AND OLD.OrderStatus != 'Completed' THEN
        CALL DeductIngredientsForPOSOrder(NEW.OrderID);
    END IF;
END
$$
DELIMITER ;

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
(1, 0, 'Canned Soft Drink (Coke | Royal | Sprite | Mt. Dew)', 1, 45.00, NULL, 'Pending'),
(2, 0, 'Canned Soft Drink (Coke | Royal | Sprite | Mt. Dew)', 1, 45.00, NULL, 'Pending'),
(3, 0, 'Canned Soft Drink (Coke | Royal | Sprite | Mt. Dew)', 1, 45.00, NULL, 'Pending'),
(4, 1000, 'S-C (w/ Shanghai, Ham & Cheese Sandwich)', 1, 180.00, NULL, 'Pending'),
(5, 1000, 'S-B (w/ Shanghai & Empanada)', 1, 165.00, NULL, 'Pending'),
(6, 1007, 'Bucket of Six (Beers)', 1, 360.00, NULL, 'Pending'),
(7, 1008, 'Bottled Water', 1, 25.00, NULL, 'Pending'),
(8, 1008, 'Lumpiang Shanghai (Platter)', 1, 250.00, NULL, 'Pending'),
(9, 1009, 'Bottled Water', 1, 25.00, NULL, 'Pending'),
(10, 1009, 'Crispy Pork Sisig w/ Egg (Platter)', 1, 265.00, NULL, 'Pending');

-- --------------------------------------------------------

--
-- Table structure for table `order_item_price_snapshot`
--

CREATE TABLE `order_item_price_snapshot` (
  `snapshot_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `price_at_order` decimal(10,2) NOT NULL,
  `quantity` int(11) NOT NULL,
  `date_recorded` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
-- Table structure for table `payroll`
--

CREATE TABLE `payroll` (
  `PayrollID` int(11) NOT NULL,
  `EmployeeID` int(11) NOT NULL,
  `PayPeriodStart` date NOT NULL,
  `PayPeriodEnd` date NOT NULL,
  `HoursWorked` decimal(5,2) DEFAULT 0.00,
  `HourlyRate` decimal(10,2) DEFAULT 0.00,
  `BasicSalary` decimal(10,2) NOT NULL,
  `Overtime` decimal(10,2) DEFAULT 0.00,
  `Deductions` decimal(10,2) DEFAULT 0.00,
  `Bonuses` decimal(10,2) DEFAULT 0.00,
  `NetPay` decimal(10,2) GENERATED ALWAYS AS (`BasicSalary` + `Overtime` + `Bonuses` - `Deductions`) STORED,
  `Status` enum('Pending','Approved','Paid') DEFAULT 'Pending',
  `ProcessedBy` int(11) DEFAULT NULL,
  `ProcessedDate` datetime DEFAULT NULL,
  `Notes` text DEFAULT NULL,
  `CreatedDate` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payroll`
--

INSERT INTO `payroll` (`PayrollID`, `EmployeeID`, `PayPeriodStart`, `PayPeriodEnd`, `HoursWorked`, `HourlyRate`, `BasicSalary`, `Overtime`, `Deductions`, `Bonuses`, `Status`, `ProcessedBy`, `ProcessedDate`, `Notes`, `CreatedDate`) VALUES
(1, 2, '2025-11-01', '2025-11-15', 8.00, 100.00, 800.00, 150.00, 0.00, 0.00, 'Pending', NULL, NULL, NULL, '2025-11-29 19:09:07');

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
(487, 69, 86, 40.00, 'ml', '2025-11-22 09:49:06', '2025-11-22 09:49:06'),
(0, 21, 142, 1.00, 'pcs', '2025-11-29 16:15:13', '2025-11-29 16:15:13'),
(0, 22, 143, 1.00, 'pcs', '2025-11-29 16:15:13', '2025-11-29 16:15:13'),
(0, 23, 144, 1.00, 'pcs', '2025-11-29 16:15:13', '2025-11-29 16:15:13'),
(0, 28, 145, 1.00, 'bottle', '2025-11-29 16:15:13', '2025-11-29 16:15:13'),
(0, 29, 146, 1.00, 'bottle', '2025-11-29 16:15:13', '2025-11-29 16:15:13'),
(0, 30, 147, 1.00, 'bottle', '2025-11-29 16:15:13', '2025-11-29 16:15:13'),
(0, 31, 148, 1.00, 'bucket', '2025-11-29 16:15:13', '2025-11-29 16:15:13');

-- --------------------------------------------------------

--
-- Table structure for table `reservations`
--

CREATE TABLE `reservations` (
  `ReservationID` int(10) NOT NULL,
  `CustomerID` int(10) NOT NULL,
  `FullName` varchar(255) DEFAULT NULL,
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

INSERT INTO `reservations` (`ReservationID`, `CustomerID`, `FullName`, `AssignedStaffID`, `ReservationType`, `EventType`, `EventDate`, `EventTime`, `NumberOfGuests`, `ProductSelection`, `SpecialRequests`, `ReservationStatus`, `ReservationDate`, `DeliveryAddress`, `DeliveryOption`, `ContactNumber`, `UpdatedDate`) VALUES
(2, 7, NULL, NULL, 'Online', 'wedding', '2025-11-22', '18:00:00', 1, 'Lumpiang Shanghai (Platter) x1, Bicol Express (Platter) x1', 'awdwdad', 'Pending', '2025-11-22 15:32:36', 'p0wncacsad', 'Delivery', '09512994765', '2025-11-22 15:32:36'),
(3, 7, NULL, NULL, 'Online', 'anniversary', '2025-11-22', '16:00:00', 65, 'Lumpiang Shanghai (Platter) x1, Buttered Chicken (Platter) x1, Bicol Express (Platter) x1', 'wfafewafeafa', 'Pending', '2025-11-22 15:42:47', 'p0wncacsad', 'Delivery', '09512994765', '2025-11-22 15:42:47'),
(4, 7, NULL, NULL, 'Online', 'anniversary', '2025-11-22', '19:00:00', 45, 'Buttered Chicken (Platter) x1, Pork Adobo (Platter) x1', 'wdada', 'Pending', '2025-11-22 15:53:14', 'wdawdwa', 'Delivery', '09512994765', '2025-11-22 15:53:14'),
(5, 8, NULL, NULL, 'Online', 'anniversary', '2025-11-22', '19:00:00', 50, 'Shrimp & Squid Kare Kare (Platter) x1', 'no more sugar', 'Pending', '2025-11-22 22:37:24', '', 'Pickup', '09511299476', '2025-11-22 22:37:24'),
(6, 8, NULL, NULL, 'Online', 'anniversary', '2025-11-22', '16:00:00', 50, 'S-E (w/ Chicken & Fries) x1, S-H (Chicken, Pizza Roll & Fries) x1', '', 'Confirmed', '2025-11-23 00:17:36', '', 'Pickup', '09511299476', '2025-11-29 17:21:26'),
(7, 8, NULL, NULL, 'Online', 'anniversary', '2025-11-23', '18:00:00', 50, 'Bicol Express (Platter) x1', '', 'Confirmed', '2025-11-23 12:32:49', '', 'Pickup', '09511299476', '2025-11-29 17:20:59'),
(0, 2, NULL, NULL, 'Online', 'birthday', '2025-11-28', '16:00:00', 50, 'Pork Tocino w/ Egg (Rice Meal) x26', '', 'Confirmed', '2025-11-28 23:32:29', '', 'Pickup', '09511299476', '2025-11-28 23:34:52'),
(0, 2, NULL, NULL, 'Online', 'birthday', '2025-11-30', '15:00:00', 50, 'Sizzling Spicy Squid (Platter) x1, Chopsuey (Platter) x1', '', 'Pending', '2025-12-01 00:11:01', '', 'Pickup', '09511299476', '2025-12-01 00:11:01'),
(0, 2, NULL, NULL, 'Online', 'birthday', '2025-11-30', '14:00:00', 50, 'Lumpiang Shanghai (Platter) x1, Buttered Chicken (Platter) x1', '', 'Pending', '2025-12-01 00:21:32', '', 'Pickup', '09511299476', '2025-12-01 00:21:32');

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
DELIMITER $$
CREATE TRIGGER `tr_reservation_confirmed` AFTER UPDATE ON `reservations` FOR EACH ROW BEGIN
    -- Only trigger when status changes to 'Confirmed'
    IF NEW.ReservationStatus = 'Confirmed' AND OLD.ReservationStatus != 'Confirmed' THEN
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
(1, 0, 'Pork Tocino w/ Egg (Rice Meal)', 26, 105.00, 2730.00),
(2, 2, 'Lumpiang Shanghai (Platter)', 1, 250.00, 250.00),
(3, 2, 'Bicol Express (Platter)', 1, 260.00, 260.00),
(4, 3, 'Lumpiang Shanghai (Platter)', 1, 250.00, 250.00),
(5, 3, 'Buttered Chicken (Platter)', 1, 250.00, 250.00),
(6, 3, 'Bicol Express (Platter)', 1, 260.00, 260.00),
(7, 4, 'Buttered Chicken (Platter)', 1, 250.00, 250.00),
(8, 4, 'Pork Adobo (Platter)', 1, 250.00, 250.00),
(9, 5, 'Shrimp & Squid Kare Kare (Platter)', 1, 480.00, 480.00),
(10, 6, 'S-E (w/ Chicken & Fries)', 1, 170.00, 170.00),
(11, 6, 'S-H (Chicken, Pizza Roll & Fries)', 1, 185.00, 185.00),
(12, 7, 'Bicol Express (Platter)', 1, 260.00, 260.00),
(13, 0, 'Lumpiang Shanghai (Platter)', 1, 250.00, 250.00),
(14, 0, 'Buttered Chicken (Platter)', 1, 250.00, 250.00);

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
(7, 7, '2025-11-23 12:32:49', 'GCash', 'Pending', 260.00, 'Website', 'uploads/gcash_receipts/2025/11/receipt_8_1763872369_2130.jpg', 'receipt_8_1763872369_2130.jpg', NULL, '2025-11-23 12:32:49'),
(0, 0, '2025-11-28 23:32:29', 'GCash', 'Pending', 2730.00, 'Website', 'uploads/gcash_receipts/2025/11/receipt_2_1764343949_4937.jpg', 'receipt_2_1764343949_4937.jpg', NULL, '2025-11-28 23:32:29'),
(0, 0, '2025-12-01 00:11:01', 'GCash', 'Pending', 610.00, 'Website', 'uploads/gcash_receipts/2025/11/receipt_2_1764519061_4699.jpg', 'receipt_2_1764519061_4699.jpg', NULL, '2025-12-01 00:11:01'),
(0, 0, '2025-12-01 00:21:33', 'GCash', 'Pending', 500.00, 'Website', 'uploads/gcash_receipts/2025/11/receipt_2_1764519692_5081.jpg', 'receipt_2_1764519692_5081.jpg', NULL, '2025-12-01 00:21:33');

-- --------------------------------------------------------

--
-- Table structure for table `review_statistics`
--

CREATE TABLE `review_statistics` (
  `total_reviews` bigint(21) DEFAULT NULL,
  `approved_reviews` bigint(21) DEFAULT NULL,
  `pending_reviews` bigint(21) DEFAULT NULL,
  `rejected_reviews` bigint(21) DEFAULT NULL,
  `avg_overall_rating` decimal(4,2) DEFAULT NULL,
  `avg_food_taste` decimal(13,2) DEFAULT NULL,
  `avg_portion_size` decimal(13,2) DEFAULT NULL,
  `avg_customer_service` decimal(13,2) DEFAULT NULL,
  `avg_ambience` decimal(13,2) DEFAULT NULL,
  `avg_cleanliness` decimal(13,2) DEFAULT NULL,
  `five_star_count` bigint(21) DEFAULT NULL,
  `four_star_count` bigint(21) DEFAULT NULL,
  `three_star_count` bigint(21) DEFAULT NULL,
  `two_star_count` bigint(21) DEFAULT NULL,
  `one_star_count` bigint(21) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
-- Structure for view `inventory_movement_details`
--
DROP TABLE IF EXISTS `inventory_movement_details`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inventory_movement_details`  AS SELECT `iml`.`MovementID` AS `MovementID`, `iml`.`MovementDate` AS `MovementDate`, `i`.`IngredientName` AS `IngredientName`, `ic`.`CategoryName` AS `CategoryName`, `ib`.`BatchNumber` AS `BatchNumber`, `iml`.`ChangeType` AS `ChangeType`, `iml`.`QuantityChanged` AS `QuantityChanged`, `iml`.`UnitType` AS `UnitType`, `iml`.`StockBefore` AS `StockBefore`, `iml`.`StockAfter` AS `StockAfter`, `iml`.`Reason` AS `Reason`, `iml`.`Source` AS `Source`, `iml`.`SourceName` AS `SourceName`, `iml`.`OrderID` AS `OrderID`, `iml`.`ReservationID` AS `ReservationID`, `iml`.`ReferenceNumber` AS `ReferenceNumber`, `iml`.`Notes` AS `Notes`, `ib`.`StorageLocation` AS `StorageLocation`, `ib`.`ExpirationDate` AS `ExpirationDate`, CASE WHEN `iml`.`ChangeType` in ('ADD','ADJUST') AND `iml`.`QuantityChanged` > 0 THEN 'INCREASE' WHEN `iml`.`ChangeType` in ('DEDUCT','DISCARD') THEN 'DECREASE' WHEN `iml`.`ChangeType` = 'ADJUST' AND `iml`.`QuantityChanged` < 0 THEN 'DECREASE' ELSE 'NEUTRAL' END AS `MovementDirection`, abs(`iml`.`QuantityChanged`) AS `AbsoluteChange` FROM (((`inventory_movement_log` `iml` join `ingredients` `i` on(`iml`.`IngredientID` = `i`.`IngredientID`)) left join `ingredient_categories` `ic` on(`i`.`CategoryID` = `ic`.`CategoryID`)) join `inventory_batches` `ib` on(`iml`.`BatchID` = `ib`.`BatchID`)) ORDER BY `iml`.`MovementDate` DESC ;

-- --------------------------------------------------------

--
-- Structure for view `inventory_movement_summary`
--
DROP TABLE IF EXISTS `inventory_movement_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inventory_movement_summary`  AS SELECT cast(`inventory_movement_log`.`MovementDate` as date) AS `MovementDay`, `inventory_movement_log`.`Source` AS `Source`, `inventory_movement_log`.`ChangeType` AS `ChangeType`, count(0) AS `TotalMovements`, sum(abs(`inventory_movement_log`.`QuantityChanged`)) AS `TotalQuantity`, count(distinct `inventory_movement_log`.`IngredientID`) AS `UniqueIngredients`, count(distinct `inventory_movement_log`.`BatchID`) AS `UniqueBatches` FROM `inventory_movement_log` GROUP BY cast(`inventory_movement_log`.`MovementDate` as date), `inventory_movement_log`.`Source`, `inventory_movement_log`.`ChangeType` ORDER BY cast(`inventory_movement_log`.`MovementDate` as date) DESC, `inventory_movement_log`.`Source` ASC, `inventory_movement_log`.`ChangeType` ASC ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `ingredients`
--
ALTER TABLE `ingredients`
  ADD PRIMARY KEY (`IngredientID`);

--
-- Indexes for table `inventory_batches`
--
ALTER TABLE `inventory_batches`
  ADD PRIMARY KEY (`BatchID`);

--
-- Indexes for table `inventory_movement_log`
--
ALTER TABLE `inventory_movement_log`
  ADD PRIMARY KEY (`MovementID`),
  ADD KEY `IngredientID` (`IngredientID`),
  ADD KEY `BatchID` (`BatchID`),
  ADD KEY `idx_movement_ingredient_date` (`IngredientID`,`MovementDate`),
  ADD KEY `idx_movement_batch_date` (`BatchID`,`MovementDate`),
  ADD KEY `idx_movement_source_date` (`Source`,`MovementDate`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`OrderID`);

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`OrderItemID`);

--
-- Indexes for table `order_item_price_snapshot`
--
ALTER TABLE `order_item_price_snapshot`
  ADD PRIMARY KEY (`snapshot_id`);

--
-- Indexes for table `payroll`
--
ALTER TABLE `payroll`
  ADD PRIMARY KEY (`PayrollID`),
  ADD KEY `idx_employee` (`EmployeeID`),
  ADD KEY `idx_status` (`Status`),
  ADD KEY `idx_period` (`PayPeriodStart`,`PayPeriodEnd`);

--
-- Indexes for table `reservation_items`
--
ALTER TABLE `reservation_items`
  ADD PRIMARY KEY (`ReservationItemID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `inventory_batches`
--
ALTER TABLE `inventory_batches`
  MODIFY `BatchID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=543;

--
-- AUTO_INCREMENT for table `inventory_movement_log`
--
ALTER TABLE `inventory_movement_log`
  MODIFY `MovementID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=196;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `OrderID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1010;

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `OrderItemID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `order_item_price_snapshot`
--
ALTER TABLE `order_item_price_snapshot`
  MODIFY `snapshot_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payroll`
--
ALTER TABLE `payroll`
  MODIFY `PayrollID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `reservation_items`
--
ALTER TABLE `reservation_items`
  MODIFY `ReservationItemID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `inventory_movement_log`
--
ALTER TABLE `inventory_movement_log`
  ADD CONSTRAINT `inventory_movement_log_ibfk_1` FOREIGN KEY (`IngredientID`) REFERENCES `ingredients` (`IngredientID`),
  ADD CONSTRAINT `inventory_movement_log_ibfk_2` FOREIGN KEY (`BatchID`) REFERENCES `inventory_batches` (`BatchID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
