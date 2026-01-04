DELIMITER $$

-- =============================================================================
-- PERFORMANCE OPTIMIZATION PROCEDURES
-- =============================================================================
-- Purpose: Provide a unified, high-performance mechanism for paging and counting
--          records across the entire system (Orders, Products, Inventory, etc.).
-- Features:
--   - Dynamic SQL to support any table or JOIN optimization.
--   - Strict pagination (LIMIT/OFFSET) to reduce memory usage.
--   - Avoids "SELECT *" by requiring explicit column selection.
--   - Supports complex filtering and sorting.
--   - separating Count from Data fetch for efficient UI logic.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Global Paged Data Loader
-- -----------------------------------------------------------------------------
-- Fetches a specific page of data based on provided criteria.
-- Parameters:
--   p_select_columns : Comma-separated list of columns to retrieve. (e.g. "id, name, date")
--   p_table_clause   : Table name or Join clause. (e.g. "users u JOIN orders o ON u.id=o.uid")
--   p_where_clause   : Filter operations. (e.g. "o.status='Active' AND o.total > 100")
--   p_order_by       : Column to sort by. (e.g. "o.date DESC")
--   p_limit          : Max rows to return.
--   p_offset         : Rows to skip.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `GetPagedData`$$

CREATE PROCEDURE `GetPagedData`(
    IN `p_select_columns` TEXT,
    IN `p_table_clause` TEXT,
    IN `p_where_clause` TEXT,
    IN `p_order_by` TEXT,
    IN `p_limit` INT,
    IN `p_offset` INT
)
BEGIN
    -- Validate inputs to prevent basic syntax errors
    IF p_select_columns IS NULL OR p_select_columns = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Select columns cannot be empty';
    END IF;

    IF p_table_clause IS NULL OR p_table_clause = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Table clause cannot be empty';
    END IF;

    -- Construct the Dynamic Query
    -- Note: Ensure p_where_clause uses Indexed Columns for performance.
    SET @sql = CONCAT(
        'SELECT ', p_select_columns, 
        ' FROM ', p_table_clause, 
        ' WHERE ', COALESCE(NULLIF(p_where_clause, ''), '1=1'), 
        ' ORDER BY ', COALESCE(NULLIF(p_order_by, ''), '1'), 
        ' LIMIT ', p_limit, 
        ' OFFSET ', p_offset
    );

    -- Prepare and Execute
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

-- -----------------------------------------------------------------------------
-- 2. Global Record Counter
-- -----------------------------------------------------------------------------
-- Returns the total number of records matching the filter criteria.
-- Essential for calculating "Total Pages" in the UI without fetching all rows.
-- Parameters:
--   p_table_clause : Table name or Join clause.
--   p_where_clause : Filter operations (must match GetPagedData filter).
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS `GetRecordCount`$$

CREATE PROCEDURE `GetRecordCount`(
    IN `p_table_clause` TEXT,
    IN `p_where_clause` TEXT
)
BEGIN
    SET @sql = CONCAT(
        'SELECT COUNT(*) AS TotalCount FROM ', p_table_clause, 
        ' WHERE ', COALESCE(NULLIF(p_where_clause, ''), '1=1')
    );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

-- -----------------------------------------------------------------------------
-- 3. SPECIFIC OPTIMIZED WRAPPERS (Optional Examples)
-- -----------------------------------------------------------------------------
-- While generic procedures work for everything, these wrappers ensure
-- type safety and enforce using correct Indexes for critical modules.
-- -----------------------------------------------------------------------------

-- Example: Optimized Product Loader (Used by Place Order)
DROP PROCEDURE IF EXISTS `GetProductsPaged`$$

CREATE PROCEDURE `GetProductsPaged`(
    IN `p_limit` INT,
    IN `p_offset` INT,
    IN `p_category` VARCHAR(50),
    IN `p_search` VARCHAR(100)
)
BEGIN
    DECLARE v_where TEXT DEFAULT '1=1';
    
    -- Build optimized filter
    IF p_category IS NOT NULL AND p_category <> '' AND p_category <> 'All' THEN
        SET v_where = CONCAT(v_where, ' AND Category = ', QUOTE(p_category));
    END IF;

    IF p_search IS NOT NULL AND p_search <> '' THEN
        SET v_where = CONCAT(v_where, ' AND ProductName LIKE ', QUOTE(CONCAT('%', p_search, '%')));
    END IF;

    -- Call generic loader with specific columns
    -- Only selecting what is needed for POS grid
    CALL GetPagedData(
        'ProductID, ProductName, Price, Category, Availability, Image, PrepTime',
        'products',
        v_where,
        'ProductName ASC',
        p_limit,
        p_offset
    );
END$$

-- Example: Optimized Orders Loader (Used by View Orders)
DROP PROCEDURE IF EXISTS `GetOrdersPaged`$$

CREATE PROCEDURE `GetOrdersPaged`(
    IN `p_limit` INT,
    IN `p_offset` INT,
    IN `p_status` VARCHAR(50),
    IN `p_date` DATE
)
BEGIN
    DECLARE v_where TEXT DEFAULT '1=1';
    
    IF p_status IS NOT NULL AND p_status <> '' AND p_status <> 'All Orders' THEN
        SET v_where = CONCAT(v_where, ' AND OrderStatus = ', QUOTE(p_status));
    END IF;

    IF p_date IS NOT NULL THEN
        SET v_where = CONCAT(v_where, ' AND DATE(OrderDate) = ', QUOTE(p_date));
    END IF;

    CALL GetPagedData(
        'o.OrderID, o.CustomerID, CONCAT(c.FirstName, " ", c.LastName) AS CustomerName, o.OrderType, o.OrderStatus, o.TotalAmount, o.OrderDate, o.OrderTime',
        'orders o LEFT JOIN customers c ON o.CustomerID = c.CustomerID',
        v_where,
        'o.OrderDate DESC, o.OrderTime DESC',
        p_limit,
        p_offset
    );
END$$

-- Example: Optimized Reservations Loader
DROP PROCEDURE IF EXISTS `GetReservationsPaged`$$

CREATE PROCEDURE `GetReservationsPaged`(
    IN `p_limit` INT,
    IN `p_offset` INT,
    IN `p_status` VARCHAR(50),
    IN `p_date` DATE
)
BEGIN
    DECLARE v_where TEXT DEFAULT '1=1';
    
    IF p_status IS NOT NULL AND p_status <> '' AND p_status <> 'All' THEN
        SET v_where = CONCAT(v_where, ' AND ReservationStatus = ', QUOTE(p_status));
    END IF;

    IF p_date IS NOT NULL THEN
        SET v_where = CONCAT(v_where, ' AND EventDate = ', QUOTE(p_date));
    END IF;

    CALL GetPagedData(
        'r.ReservationID, CONCAT(c.FirstName, " ", c.LastName) AS CustomerName, r.EventDate, r.EventTime, r.NumberOfGuests, r.ReservationStatus',
        'reservations r JOIN customers c ON r.CustomerID = c.CustomerID',
        v_where,
        'r.EventDate DESC, r.EventTime DESC',
        p_limit,
        p_offset
    );
END$$

DELIMITER ;
