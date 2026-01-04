-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 10, 2025 at 12:28 AM
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

INSERT INTO `orders` (`OrderID`, `CustomerID`, `EmployeeID`, `OrderType`, `OrderSource`, `ReceiptNumber`, `NumberOfDiners`, `OrderDate`, `OrderTime`, `ItemsOrderedCount`, `TotalAmount`, `OrderStatus`, `Remarks`, `DeliveryAddress`, `SpecialRequests`, `PreparationTimeEstimate`, `SpecialRequestFlag`, `CreatedDate`, `UpdatedDate`) VALUES
(1001, 8, NULL, 'Online', 'Website', NULL, NULL, '2025-11-23', '12:46:03', 2, 345.00, 'Completed', NULL, NULL, NULL, NULL, 0, '2025-11-23 12:46:03', '2025-11-30 00:28:54'),
(1003, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-29', '22:53:24', 1, 45.00, '', NULL, NULL, NULL, 0, 0, '2025-11-29 22:53:24', '2025-11-30 00:06:16'),
(1004, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-29', '23:04:17', 1, 45.00, '', NULL, NULL, NULL, 0, 0, '2025-11-29 23:04:17', '2025-11-30 00:06:16'),
(1005, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-29', '23:08:37', 1, 45.00, 'Completed', NULL, NULL, NULL, 0, 0, '2025-11-29 23:08:37', '2025-11-30 00:46:18'),
(1006, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-29', '23:12:03', 1, 45.00, 'Completed', NULL, NULL, NULL, 0, 0, '2025-11-29 23:12:03', '2025-11-30 00:46:18'),
(1007, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-30', '00:46:41', 1, 360.00, 'Completed', NULL, NULL, NULL, 0, 0, '2025-11-30 00:46:41', '2025-12-06 01:50:58'),
(1008, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-30', '13:53:33', 2, 275.00, 'Cancelled', NULL, NULL, NULL, 18, 0, '2025-11-30 13:53:33', '2025-11-30 13:53:55'),
(1009, NULL, NULL, 'Dine-in', 'POS', NULL, NULL, '2025-11-30', '14:48:08', 2, 290.00, 'Cancelled', NULL, NULL, NULL, 22, 0, '2025-11-30 14:48:08', '2025-11-30 14:48:27'),
(1010, 2, NULL, 'Online', 'Website', NULL, NULL, '2025-12-07', '00:42:11', 1, 250.00, 'Completed', NULL, NULL, NULL, NULL, 0, '2025-12-07 00:42:11', '2025-12-07 00:45:45'),
(1011, 2, NULL, 'Online', 'Website', NULL, NULL, '2025-12-08', '11:27:39', 1, 265.00, 'Completed', NULL, NULL, NULL, NULL, 0, '2025-12-08 11:27:39', '2025-12-08 11:32:28'),
(1012, 2, NULL, 'Online', 'Website', NULL, NULL, '2025-12-08', '11:40:46', 2, 515.00, 'Cancelled', NULL, NULL, NULL, NULL, 0, '2025-12-08 11:40:46', '2025-12-08 11:44:20'),
(1013, 2, NULL, 'Online', 'Website', NULL, NULL, '2025-12-08', '12:16:06', 2, 570.00, 'Completed', NULL, NULL, NULL, NULL, 0, '2025-12-08 12:16:06', '2025-12-10 07:04:20'),
(1014, 7, NULL, 'Online', 'Website', NULL, NULL, '2025-12-08', '14:13:28', 2, 515.00, 'Completed', NULL, NULL, NULL, NULL, 0, '2025-12-08 14:13:28', '2025-12-10 07:04:20'),
(1015, 7, NULL, 'Online', 'Website', NULL, NULL, '2025-12-08', '14:34:43', 2, 600.00, 'Completed', 'Pickup Order', NULL, '', NULL, 0, '2025-12-08 14:34:43', '2025-12-10 07:04:20'),
(1016, 7, NULL, 'Online', 'Website', NULL, NULL, '2025-12-08', '14:43:55', 2, 570.00, 'Completed', 'Pickup Order', NULL, '', NULL, 0, '2025-12-08 14:43:55', '2025-12-08 15:47:31'),
(1017, 7, NULL, 'Online', 'Website', NULL, NULL, '2025-12-08', '14:48:41', 2, 515.00, 'Completed', 'Pickup Order', NULL, '', NULL, 0, '2025-12-08 14:48:41', '2025-12-08 15:46:32'),
(1018, 2, NULL, 'Online', 'Website', NULL, NULL, '2025-12-08', '16:28:48', 1, 250.00, 'Completed', 'Pickup Order', NULL, '', NULL, 0, '2025-12-08 16:28:48', '2025-12-10 07:04:20');

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
  ADD PRIMARY KEY (`OrderID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `OrderID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=1019;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
