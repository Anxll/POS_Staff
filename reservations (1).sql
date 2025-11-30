-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 30, 2025 at 08:38 AM
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
(1, 7, 's', NULL, 'Online', 'wedding', '2025-11-22', '18:00:00', 1, 'Lumpiang Shanghai (Platter) x1, Bicol Express (Platter) x1', 'awdwdad', 'Pending', '2025-11-22 15:32:36', 'p0wncacsad', 'Delivery', '09512994765', '2025-11-30 15:30:51'),
(2, 7, NULL, NULL, 'Online', 'anniversary', '2025-11-22', '16:00:00', 65, 'Lumpiang Shanghai (Platter) x1, Buttered Chicken (Platter) x1, Bicol Express (Platter) x1', 'wfafewafeafa', 'Pending', '2025-11-22 15:42:47', 'p0wncacsad', 'Delivery', '09512994765', '2025-11-30 00:31:36'),
(3, 7, NULL, NULL, 'Online', 'anniversary', '2025-11-22', '19:00:00', 45, 'Buttered Chicken (Platter) x1, Pork Adobo (Platter) x1', 'wdada', 'Pending', '2025-11-22 15:53:14', 'wdawdwa', 'Delivery', '09512994765', '2025-11-30 00:31:36'),
(4, 8, NULL, NULL, 'Online', 'anniversary', '2025-11-22', '19:00:00', 50, 'Shrimp & Squid Kare Kare (Platter) x1', 'no more sugar', 'Pending', '2025-11-22 22:37:24', '', 'Pickup', '09511299476', '2025-11-30 00:31:36'),
(5, 8, NULL, NULL, 'Online', 'anniversary', '2025-11-22', '16:00:00', 50, 'S-E (w/ Chicken & Fries) x1, S-H (Chicken, Pizza Roll & Fries) x1', '', 'Confirmed', '2025-11-23 00:17:36', '', 'Pickup', '09511299476', '2025-11-30 00:31:36'),
(6, 8, NULL, NULL, 'Online', 'anniversary', '2025-11-23', '18:00:00', 50, 'Bicol Express (Platter) x1', '', 'Confirmed', '2025-11-23 12:32:49', '', 'Pickup', '09511299476', '2025-11-30 00:31:36'),
(7, 2, NULL, NULL, 'Online', 'birthday', '2025-11-28', '16:00:00', 50, 'Pork Tocino w/ Egg (Rice Meal) x26', '', 'Confirmed', '2025-11-28 23:32:29', '', 'Pickup', '09511299476', '2025-11-30 00:31:36');

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

--
-- Indexes for dumped tables
--

--
-- Indexes for table `reservations`
--
ALTER TABLE `reservations`
  ADD PRIMARY KEY (`ReservationID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `reservations`
--
ALTER TABLE `reservations`
  MODIFY `ReservationID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
