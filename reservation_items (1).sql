-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 01, 2025 at 04:44 AM
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
(14, 0, 'Buttered Chicken (Platter)', 1, 250.00, 250.00),
(15, 0, '2 pcs Breaded Chicken (Rice Meal)', 1, 145.00, 145.00),
(16, 15, '2 pcs Breaded Chicken (Rice Meal)', 1, 145.00, 145.00);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `reservation_items`
--
ALTER TABLE `reservation_items`
  ADD PRIMARY KEY (`ReservationItemID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `reservation_items`
--
ALTER TABLE `reservation_items`
  MODIFY `ReservationItemID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
