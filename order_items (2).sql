-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 16, 2025 at 04:24 PM
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
-- Table structure for table `order_items`
--

CREATE TABLE `order_items` (
  `OrderItemID` int(10) NOT NULL,
  `OrderID` int(10) NOT NULL,
  `ProductName` varchar(100) NOT NULL,
  `Quantity` int(4) NOT NULL,
  `UnitPrice` decimal(10,2) NOT NULL,
  `SpecialInstructions` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `order_items`
--

INSERT INTO `order_items` (`OrderItemID`, `OrderID`, `ProductName`, `Quantity`, `UnitPrice`, `SpecialInstructions`) VALUES
(1, 0, 'Canned Soft Drink (Coke | Royal | Sprite | Mt. Dew)', 1, 45.00, NULL),
(2, 0, 'Canned Soft Drink (Coke | Royal | Sprite | Mt. Dew)', 1, 45.00, NULL),
(3, 0, 'Canned Soft Drink (Coke | Royal | Sprite | Mt. Dew)', 1, 45.00, NULL),
(4, 1000, 'S-C (w/ Shanghai, Ham & Cheese Sandwich)', 1, 180.00, NULL),
(5, 1000, 'S-B (w/ Shanghai & Empanada)', 1, 165.00, NULL),
(6, 1007, 'Bucket of Six (Beers)', 1, 360.00, NULL),
(7, 1008, 'Bottled Water', 1, 25.00, NULL),
(8, 1008, 'Lumpiang Shanghai (Platter)', 1, 250.00, NULL),
(9, 1009, 'Bottled Water', 1, 25.00, NULL),
(10, 1009, 'Crispy Pork Sisig w/ Egg (Platter)', 1, 265.00, NULL),
(11, 1010, 'Buttered Chicken (Platter)', 1, 250.00, NULL),
(12, 1011, 'Crispy Pork Sisig w/ Egg (Platter)', 1, 265.00, NULL),
(13, 1012, 'Crispy Pork Sisig w/ Egg (Platter)', 1, 265.00, NULL),
(14, 1012, 'Crispy Pork Sisig (Platter 3-4 pax)', 1, 250.00, NULL),
(15, 1013, 'Calamares (Platter)', 1, 320.00, NULL),
(16, 1013, 'Lumpiang Shanghai (Platter)', 1, 250.00, NULL),
(17, 1014, 'Crispy Pork Sisig w/ Egg (Platter)', 1, 265.00, NULL),
(18, 1014, 'Crispy Pork Sisig (Platter 3-4 pax)', 1, 250.00, NULL),
(19, 1015, 'Crispy Pork Sisig (Platter 3-4 pax)', 1, 250.00, ''),
(20, 1015, 'Lechon Kawali (Platter)', 1, 350.00, ''),
(21, 1016, 'Crispy Pork Sisig (Platter 3-4 pax)', 1, 250.00, ''),
(22, 1016, 'Calamares (Platter)', 1, 320.00, ''),
(23, 1017, 'Crispy Pork Sisig w/ Egg (Platter)', 1, 265.00, ''),
(24, 1017, 'Buttered Chicken (Platter)', 1, 250.00, ''),
(25, 1018, 'Lumpiang Shanghai (Platter)', 1, 250.00, ''),
(26, 1019, '6 pcs Pork BBQ w/ Butter Veg. (Platter)', 1, 270.00, NULL),
(27, 1019, 'Bottled Water', 1, 25.00, NULL),
(28, 11020, 'Bagnet Kare Kare (Platter)', 1, 450.00, NULL),
(29, 11021, 'Coffee', 1, 40.00, NULL),
(30, 11022, 'Coffee', 1, 40.00, NULL),
(31, 11023, 'Bagnet Kare Kare (Platter)', 1, 450.00, NULL),
(32, 11024, 'Coffee', 1, 40.00, NULL),
(33, 11025, 'Coffee', 1, 40.00, NULL),
(34, 11002, '6 pcs Pork BBQ w/ Butter Veg. (Platter)', 1, 270.00, NULL),
(35, 11003, 'Canned Soft Drink (Coke | Royal | Sprite | Mt. Dew)', 1, 45.00, NULL),
(36, 11004, 'Iced Tea (Glass)', 1, 40.00, NULL),
(37, 11005, 'Iced Tea (Glass)', 1, 40.00, NULL),
(38, 11006, 'Iced Tea (Glass)', 1, 40.00, NULL),
(39, 11007, 'Iced Tea (Glass)', 1, 40.00, NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `order_items`
--
ALTER TABLE `order_items`
  ADD PRIMARY KEY (`OrderItemID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `order_items`
--
ALTER TABLE `order_items`
  MODIFY `OrderItemID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
