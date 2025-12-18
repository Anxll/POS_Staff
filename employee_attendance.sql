-- ========================================================
-- EMPLOYEE ATTENDANCE TRACKING TABLE
-- ========================================================

--
-- Table structure for table `employee_attendance`
--

CREATE TABLE `employee_attendance` (
  `AttendanceID` INT(10) NOT NULL AUTO_INCREMENT COMMENT 'Unique attendance record identifier',
  `EmployeeID` INT(10) NOT NULL COMMENT 'Reference to employee table',
  `AttendanceDate` DATE NOT NULL COMMENT 'Date of attendance',
  `TimeIn` DATETIME DEFAULT NULL COMMENT 'Time when employee clocked in',
  `TimeOut` DATETIME DEFAULT NULL COMMENT 'Time when employee clocked out',
  `Status` ENUM('Present','Late','Absent','On Leave') DEFAULT 'Present' COMMENT 'Attendance status',
  `WorkHours` DECIMAL(5,2) DEFAULT NULL COMMENT 'Total work hours (calculated)',
  `Notes` TEXT DEFAULT NULL COMMENT 'Additional notes or remarks',
  `CreatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
  `UpdatedAt` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp',
  
  PRIMARY KEY (`AttendanceID`),
  KEY `IDX_EmployeeID` (`EmployeeID`),
  KEY `IDX_AttendanceDate` (`AttendanceDate`),
  KEY `IDX_EmployeeDate` (`EmployeeID`, `AttendanceDate`),
  
  CONSTRAINT `FK_Attendance_Employee` FOREIGN KEY (`EmployeeID`) 
    REFERENCES `employee` (`EmployeeID`) ON DELETE CASCADE ON UPDATE CASCADE
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Employee attendance and time tracking records';

-- ========================================================
-- HELPFUL VIEWS
-- ========================================================

--
-- View: Today's Attendance Summary
--
CREATE OR REPLACE VIEW `v_today_attendance` AS
SELECT 
  ea.AttendanceID,
  ea.EmployeeID,
  CONCAT(e.FirstName, ' ', e.LastName) AS FullName,
  e.Position,
  ea.TimeIn,
  ea.TimeOut,
  ea.Status,
  CASE 
    WHEN ea.TimeOut IS NULL THEN 'Clocked In'
    ELSE 'Clocked Out'
  END AS CurrentStatus,
  CASE 
    WHEN ea.TimeOut IS NOT NULL THEN 
      TIMESTAMPDIFF(MINUTE, ea.TimeIn, ea.TimeOut) / 60.0
    ELSE NULL
  END AS HoursWorked
FROM employee_attendance ea
INNER JOIN employee e ON ea.EmployeeID = e.EmployeeID
WHERE DATE(ea.AttendanceDate) = CURDATE()
ORDER BY ea.TimeIn DESC;

--
-- View: Monthly Attendance Summary
--
CREATE OR REPLACE VIEW `v_monthly_attendance` AS
SELECT 
  e.EmployeeID,
  CONCAT(e.FirstName, ' ', e.LastName) AS FullName,
  YEAR(ea.AttendanceDate) AS Year,
  MONTH(ea.AttendanceDate) AS Month,
  COUNT(*) AS DaysPresent,
  SUM(CASE WHEN ea.Status = 'Late' THEN 1 ELSE 0 END) AS DaysLate,
  SUM(CASE WHEN ea.Status = 'Absent' THEN 1 ELSE 0 END) AS DaysAbsent,
  SUM(CASE WHEN ea.TimeOut IS NOT NULL THEN 
    TIMESTAMPDIFF(MINUTE, ea.TimeIn, ea.TimeOut) / 60.0 
    ELSE 0 
  END) AS TotalHoursWorked
FROM employee e
LEFT JOIN employee_attendance ea ON e.EmployeeID = ea.EmployeeID
WHERE e.EmploymentStatus = 'Active'
GROUP BY e.EmployeeID, YEAR(ea.AttendanceDate), MONTH(ea.AttendanceDate)
ORDER BY Year DESC, Month DESC, FullName;

-- ========================================================
-- SAMPLE QUERIES (COMMENTED OUT)
-- ========================================================

/*
-- Check today's attendance
SELECT * FROM v_today_attendance;

-- Get attendance for specific employee
SELECT * FROM employee_attendance 
WHERE EmployeeID = 1 
ORDER BY AttendanceDate DESC 
LIMIT 10;

-- Check if employee already clocked in today
SELECT * FROM employee_attendance
WHERE EmployeeID = 1 AND DATE(AttendanceDate) = CURDATE();

-- Monthly summary for current month
SELECT * FROM v_monthly_attendance
WHERE Year = YEAR(CURDATE()) AND Month = MONTH(CURDATE());
*/
