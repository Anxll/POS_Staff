-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 04, 2025 at 03:12 PM
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
  `Position` enum('Staff') DEFAULT NULL,
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
(1, 'Maria', 'Santos', 'Female', '1992-08-20', '09987654321', 'maria.santos@example.com', '456 Mabini St., Cebu City', '2023-03-15', '', 'Married', 'Active', 'Full-time', 'Pedro Santos - 09999888777', 'Morning', 25000.00),
(2, 'Robert', 'Lim', 'Male', '1988-02-14', '09175553344', 'robert.lim@example.com', '789 Rizal Ave., Makati', '2022-07-01', '', 'Single', 'Active', 'Contract', 'Ana Lim - 09176667788', 'Evening', 32000.00),
(3, 'Angela', 'Reyes', 'Female', '1999-11-05', '09223334455', 'angela.reyes@example.com', 'Lot 12 Phase 2, Caloocan City', '2024-01-10', '', 'Single', 'Active', 'Part-time', 'Ramon Reyes - 09225556677', 'Split', 12000.00),
(5, 'Angelo', 'Malaluan', 'Male', '2025-12-04', '0987654212', 'angelo@gmail.com', 'zsdzf', '2025-12-04', 'Staff', 'Single', 'Active', 'Part-time', '098764351213', 'Morning', 10000.00);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `employee`
--
ALTER TABLE `employee`
  ADD PRIMARY KEY (`EmployeeID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `employee`
--
ALTER TABLE `employee`
  MODIFY `EmployeeID` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
