-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 10, 2025 at 12:30 AM
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
-- Table structure for table `customers`
--

CREATE TABLE `customers` (
  `CustomerID` int(10) NOT NULL,
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
(2, 'Ronald', 'Sevillaaaaee', 'sevillaronald32@gmail.com', '$2y$12$YUalmxXNTAnYHqE4YuE9f.OvHg/.rAfqFFE38JQa4idQeP7mvdWvO', '09511299476', 'Online', 6, 4, 7, '2025-12-09 17:55:31', '2025-12-09 17:55:31', '2025-11-06 23:34:05', 'Active', 4.00),
(5, 'Test', 'User', 'test_1762492324@example.com', '$2y$10$oICfw2SwBITYnSkGtyduZubnjRCktRLv0Uraut8a3YxiRO.JpO8kG', '09123456789', 'Online', 0, 0, 0, NULL, NULL, '2025-11-07 13:12:04', 'Active', 0.00),
(6, 'TestJS', 'UserJS', 'testjs@example.com', '$2y$10$7vpPF.mup7IeLZ1Rv6XYHOfR1bov3BR5jKsERDKgyQ7mKrWVluDpy', '09123456789', 'Online', 0, 0, 0, NULL, NULL, '2025-11-07 13:35:28', 'Active', 0.00),
(7, 'Ronald', 'Sevilla', 'sevillaronald@gmail.com', '$2y$12$de0QIvl638SHw4FryePZeOJfkkJK0uhpo6/ynmbn1MjSrKQf6HM9C', '09512994765', 'Online', 3, 4, 4, '2025-12-08 14:48:41', '2025-11-07 14:51:08', '2025-11-07 13:40:13', 'Active', 4.50),
(8, 'Ronal', 'Sevill', 'sevillaronald9@gmail.com', '$2y$12$NvAqawV6IsJSEXIGObqOR.h1p2FJcozHohRB1Xk5RAUFt2id6WRL.', '09511299476', 'Online', 2, 1, 3, '2025-11-23 12:46:04', NULL, '2025-11-22 17:18:23', 'Active', 4.00);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`CustomerID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `customers`
--
ALTER TABLE `customers`
  MODIFY `CustomerID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
