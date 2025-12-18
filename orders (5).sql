-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 16, 2025 at 03:24 PM
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
  `WebsiteStatus` enum('Pending','Confirmed','Cancelled') DEFAULT NULL,
  `ReceiptNumber` varchar(20) DEFAULT NULL,
  `NumberOfDiners` int(3) DEFAULT NULL,
  `OrderDate` date NOT NULL,
  `OrderTime` time NOT NULL,
  `ItemsOrderedCount` int(4) NOT NULL,
  `TotalAmount` decimal(10,2) NOT NULL,
  `OrderStatus` enum('Preparing','Served','Completed','Cancelled') DEFAULT 'Preparing',
  `Remarks` text DEFAULT NULL,
  `DeliveryAddress` text DEFAULT NULL COMMENT 'Delivery address for delivery orders',
  `SpecialRequests` text DEFAULT NULL COMMENT 'Special requests or notes from customer',
  `PreparationTimeEstimate` int(4) DEFAULT NULL,
  `SpecialRequestFlag` tinyint(1) DEFAULT 0,
  `CreatedDate` datetime DEFAULT current_timestamp(),
  `UpdatedDate` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`OrderID`, `CustomerID`, `EmployeeID`, `OrderType`, `OrderSource`, `WebsiteStatus`, `ReceiptNumber`, `NumberOfDiners`, `OrderDate`, `OrderTime`, `ItemsOrderedCount`, `TotalAmount`, `OrderStatus`, `Remarks`, `DeliveryAddress`, `SpecialRequests`, `PreparationTimeEstimate`, `SpecialRequestFlag`, `CreatedDate`, `UpdatedDate`) VALUES
(11002, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, NULL, '2025-12-16', '22:18:51', 1, 270.00, 'Preparing', NULL, NULL, NULL, NULL, 0, '2025-12-16 22:18:51', '2025-12-16 22:18:51');

--
-- Triggers `orders`
--
DELIMITER $$
CREATE TRIGGER `tr_order_completed` AFTER UPDATE ON `orders` FOR EACH ROW BEGIN
    IF NEW.OrderStatus = 'Completed' AND OLD.OrderStatus != 'Completed' THEN
        CALL DeductIngredientsForPOSOrder(NEW.OrderID);
    END IF;
END
$$
DELIMITER ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`OrderID`),
  ADD KEY `idx_orders_status` (`OrderStatus`),
  ADD KEY `idx_orders_datetime` (`OrderDate`,`OrderTime`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `OrderID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11003;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
