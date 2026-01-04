-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 01, 2025 at 05:06 AM
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
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
