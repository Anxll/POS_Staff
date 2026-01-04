-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Dec 16, 2025 at 03:27 PM
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
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `ProductID` int(10) NOT NULL,
  `ProductName` varchar(100) NOT NULL,
  `Category` enum('SPAGHETTI MEAL','DESSERT','DRINKS & BEVERAGES','PLATTER','RICE MEAL','RICE','Bilao','SNACKS','NOODLES & PASTA') NOT NULL,
  `Description` text DEFAULT NULL,
  `Price` decimal(10,2) NOT NULL,
  `Availability` enum('Available','Not Available') DEFAULT 'Available',
  `ServingSize` enum('REGULAR','SMALL','MEDIUM','LARGE') DEFAULT NULL,
  `DateAdded` datetime DEFAULT current_timestamp(),
  `LastUpdated` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `ProductCode` varchar(20) DEFAULT NULL,
  `PopularityTag` enum('Best Seller','Regular') DEFAULT 'Regular',
  `MealTime` enum('Breakfast','Lunch','Dinner','All Day') DEFAULT NULL,
  `OrderCount` int(10) DEFAULT 0,
  `Image` varchar(255) DEFAULT NULL,
  `PrepTime` int(3) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`ProductID`, `ProductName`, `Category`, `Description`, `Price`, `Availability`, `ServingSize`, `DateAdded`, `LastUpdated`, `ProductCode`, `PopularityTag`, `MealTime`, `OrderCount`, `Image`, `PrepTime`) VALUES
(1, 'S-A (w/ Butter Bread)', 'SPAGHETTI MEAL', 'Sweet-style spaghetti served with toasted buttered bread.', 105.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:42', 'S-A', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870039518.jpg', 10),
(2, 'S-B (w/ Shanghai & Empanada)', 'SPAGHETTI MEAL', 'Spaghetti served with shanghai rolls and an empanada.', 165.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:42', 'S-B', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870028508.jpg', 12),
(3, 'S-C (w/ Shanghai, Ham & Cheese Sandwich)', 'SPAGHETTI MEAL', 'Spaghetti with shanghai and ham & cheese sandwich.', 180.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:42', 'S-C', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870037291.jpg', 13),
(4, 'S-D (w/ Empanada & Chicken)', 'SPAGHETTI MEAL', 'Spaghetti paired with empanada and fried chicken.', 165.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', 'S-D', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870027024.jpg', 13),
(5, 'S-E (w/ Chicken & Fries)', 'SPAGHETTI MEAL', 'Spaghetti with crispy chicken and fries.', 170.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', 'S-E', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870035752.jpg', 12),
(6, 'S-F (w/ Shanghai & Chicken)', 'SPAGHETTI MEAL', 'Spaghetti served with shanghai rolls and chicken.', 180.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', 'S-F', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870025216.jpg', 13),
(7, 'S-G (Ham & Cheese Sandwich w/ Fries)', 'SPAGHETTI MEAL', 'Spaghetti with ham & cheese sandwich and fries.', 170.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', 'S-G', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870030435.jpg', 12),
(8, 'S-H (Chicken, Pizza Roll & Fries)', 'SPAGHETTI MEAL', 'Spaghetti with chicken, pizza roll, and fries.', 185.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', 'S-H', 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870023506.jpg', 14),
(9, 'Club Sandwich', 'SNACKS', 'Triple-layer sandwich with ham, egg, veggies and sauce.', 130.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (23).jpeg', 8),
(10, 'Ham & Cheese Sandwich', 'SNACKS', 'Toasted ham and cheese sandwich.', 55.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (24).jpeg', 5),
(11, 'Lomi Solo', 'SNACKS', 'Thick noodle soup with egg and toppings.', 105.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/LOMI.jpg', 12),
(12, 'Salo Salo', 'SNACKS', 'Assorted snacks plate for sharing.', 240.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/LOMI.jpg', 10),
(13, 'Fried Lumpia (6 PCS)', 'SNACKS', 'Crispy vegetable/meat rolls (6 pcs).', 75.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (25).jpeg', 7),
(14, 'Pizza Roll', 'SNACKS', 'Crispy roll filled with pizza-style cheese and sauce.', 58.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/pizza-bread-roll-recipe.jpg', 6),
(15, 'Empanada', 'SNACKS', 'Golden-fried empanada stuffed with savory filling.', 30.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (26).jpeg', 6),
(16, 'Potato Fries', 'SNACKS', 'Crispy seasoned fries served hot.', 90.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (27).jpeg', 8),
(17, 'Halo Halo', 'DESSERT', 'Shaved ice dessert with milk, beans and toppings.', 125.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/gallery3.jpg', 8),
(18, 'Maiz con Leche', 'DESSERT', 'Sweet corn in creamy milk, chilled.', 90.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870084790.jpg', 6),
(19, 'Leche Flan 1/4', 'DESSERT', 'Quarter portion of traditional caramel custard.', 40.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/filipino-leche-flan-cover-1.jpg', 5),
(20, 'Leche Flan Whole', 'DESSERT', 'Whole serving of rich caramel custard.', 145.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/filipino-leche-flan-cover-1.jpg', 8),
(21, 'Canned Soft Drink (Coke | Royal | Sprite | Mt. Dew)', 'DRINKS & BEVERAGES', 'Assorted canned sodas, 330ml.', 45.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:43', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (14).jpeg', 0),
(22, 'Bottled Water', 'DRINKS & BEVERAGES', 'Still bottled mineral water, 500ml.', 25.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-12-14 22:14:29', NULL, 'Regular', 'All Day', 1, 'uploads/products/bottled_water.jpeg', 0),
(23, 'Pineapple Juice', 'DRINKS & BEVERAGES', 'Fresh pineapple juice, chilled.', 50.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (15).jpeg', 2),
(24, 'Mango Juice', 'DRINKS & BEVERAGES', 'Sweet mango juice, chilled.', 50.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (16).jpeg', 2),
(25, 'Iced Tea (Glass)', 'DRINKS & BEVERAGES', 'Fresh iced tea, served chilled.', 40.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (17).jpeg', 1),
(26, 'Iced Tea (Pitcher)', 'DRINKS & BEVERAGES', 'Pitcher of iced tea for sharing.', 85.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (17).jpeg', 2),
(27, 'Coffee', 'DRINKS & BEVERAGES', 'Hot brewed coffee, single cup.', 40.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-12-16 21:06:15', NULL, 'Regular', 'All Day', 2, 'uploads/products/images (18).jpeg', 5),
(28, 'SMB Pale Pilsen', 'DRINKS & BEVERAGES', 'Bottle of local pale pilsen beer.', 65.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (19).jpeg', 0),
(29, 'Red Horse Stallion', 'DRINKS & BEVERAGES', 'Strong beer bottle, local brand.', 65.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (20).jpeg', 0),
(30, 'San Mig Light', 'DRINKS & BEVERAGES', 'Light beer bottle.', 65.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (21).jpeg', 0),
(31, 'Bucket of Six (Beers)', 'DRINKS & BEVERAGES', 'Six bottles of assorted beers in a bucket.', 360.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (21).jpeg', 0),
(32, 'Crispy Pork Sisig (Platter 3-4 pax)', 'PLATTER', 'Crispy sisig platter good for 3-4 persons.', 250.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-12-10 07:04:20', NULL, 'Regular', 'All Day', 3, 'uploads/products/images (34).jpeg', 20),
(33, 'Crispy Pork Sisig w/ Egg (Platter)', 'PLATTER', 'Crispy sisig with sunny-side-up egg.', 265.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-12-10 07:04:20', NULL, 'Regular', 'All Day', 2, 'uploads/products/images (34).jpeg', 22),
(34, 'Lechon Kawali (Platter)', 'PLATTER', 'Crispy lechon kawali platter for sharing.', 350.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-12-10 07:04:20', NULL, 'Regular', 'All Day', 1, 'uploads/products/images (35).jpeg', 25),
(35, 'Lumpiang Shanghai (Platter)', 'PLATTER', 'Platter of lumpiang shanghai (many pcs).', 250.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-12-10 07:04:20', NULL, 'Regular', 'All Day', 2, 'uploads/products/FB_IMG_1763870008092.jpg', 18),
(36, 'Buttered Chicken (Platter)', 'PLATTER', 'Savory buttered chicken served family-style.', 250.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-12-08 15:46:32', NULL, 'Regular', 'All Day', 2, 'uploads/products/images (36).jpeg', 25),
(37, 'Calamares (Platter)', 'PLATTER', 'Crispy battered calamari platter.', 320.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-12-10 07:04:20', NULL, 'Regular', 'All Day', 2, 'uploads/products/images (36).jpeg', 20),
(38, 'Fried Lumpia Veg. (12 PCS) (Platter)', 'PLATTER', 'Vegetable fried lumpia, 12 pcs.', 145.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/download.jpg', 15),
(39, 'Tokwa\'t Baboy (Platter)', 'PLATTER', 'Fried tokwa and pork with sauce.', 260.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (38).jpeg', 18),
(40, 'Beef Steak Tagalog (Platter)', 'PLATTER', 'Beef steak in savory sauce, platter size.', 340.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (39).jpeg', 25),
(41, 'Sizzling Spicy Squid (Platter)', 'PLATTER', 'Spicy squid served on a sizzling plate.', 360.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (40).jpeg', 20),
(42, 'Sizzling Tofu (Platter)', 'PLATTER', 'Sizzling tofu with savory sauce.', 180.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/Tofu-Sisig-with-Egg-scaled-1.jpg', 15),
(43, 'Bicol Express (Platter)', 'PLATTER', 'Spicy pork in coconut milk, platter share.', 260.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:44', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (41).jpeg', 20),
(44, 'Pork Adobo (Platter)', 'PLATTER', 'Classic pork adobo served family-style.', 250.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (42).jpeg', 22),
(45, '6 pcs Pork BBQ w/ Butter Veg. (Platter)', 'PLATTER', 'Six pork BBQ skewers with buttered vegetables.', 270.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-12-14 22:14:29', NULL, 'Regular', 'All Day', 1, 'uploads/products/images (44).jpeg', 18),
(46, 'Chopsuey (Platter)', 'PLATTER', 'Mixed vegetables in light stir-fry sauce.', 250.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763869994665.jpg', 18),
(47, 'Chicken w/ Mixed Veg (Platter)', 'PLATTER', 'Chicken with mixed vegetables, platter.', 480.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (43).jpeg', 30),
(48, 'Garlic Butter Shrimp (Platter)', 'PLATTER', 'Shrimp tossed in garlic butter, for sharing.', 260.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (33).jpeg', 20),
(49, 'Shrimp & Squid Kare Kare (Platter)', 'PLATTER', 'Seafood kare-kare served with peanut sauce.', 480.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (32).jpeg', 35),
(50, 'Bagnet Kare Kare (Platter)', 'PLATTER', 'Crispy bagnet in kare-kare sauce, platter.', 450.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-12-16 20:27:27', NULL, 'Regular', 'All Day', 2, 'uploads/products/download (1).jpg', 35),
(51, 'Shrimp Sinigang (Platter)', 'PLATTER', 'Sour tamarind soup with shrimp, family-size.', 350.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (31).jpeg', 30),
(52, 'Pork Sinigang (Platter)', 'PLATTER', 'Sinigang with pork, served family-style.', 380.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/Killer-Pork-Sinigang-jpg.webp', 30),
(53, 'Hototay Soup (Platter)', 'PLATTER', 'Mixed vegetable and seafood soup for sharing.', 260.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/hototay-scaled.jpg', 20),
(54, 'Pork Sisig Solo w/ Egg (Rice Meal)', 'RICE MEAL', 'Solo pork sisig served with garlic yellow rice and egg.', 135.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870457190.jpg', 12),
(55, 'Pork Adobo w/ Egg (Rice Meal)', 'RICE MEAL', 'Classic pork adobo with rice and fried egg.', 125.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (5).jpeg', 10),
(56, 'Pork Tocino w/ Egg (Rice Meal)', 'RICE MEAL', 'Sweet cured pork (tocino) with rice and egg.', 105.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (2).jpg', 10),
(57, 'Beef Tapa w/ Egg (Rice Meal)', 'RICE MEAL', 'Marinated beef tapa with rice and egg.', 110.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (6).jpeg', 12),
(58, 'Beef Teriyaki w/ Egg (Rice Meal)', 'RICE MEAL', 'Teriyaki-style beef served with rice and egg.', 125.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/teriyaki.jpg', 12),
(59, 'Breaded Porkchop w/ Egg (Rice Meal)', 'RICE MEAL', 'Crispy breaded porkchop with rice and egg.', 125.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (3).jpg', 15),
(60, 'Sizzling Tofu w/ Egg (Rice Meal)', 'RICE MEAL', 'Sizzling tofu with vegetables, rice and egg.', 100.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (8).jpeg', 12),
(61, 'Spam w/ Egg (Rice Meal)', 'RICE MEAL', 'Fried spam with garlic rice and egg.', 125.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (9).jpeg', 8),
(62, 'Breaded Chicken w/ Egg (Rice Meal)', 'RICE MEAL', 'Crispy breaded chicken with rice and egg.', 100.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (10).jpeg', 15),
(63, '2 pcs Pork BBQ w/ Butter Veg. (Rice Meal)', 'RICE MEAL', 'Two pork BBQ skewers with rice and veggies.', 130.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870519059.jpg', 12),
(64, '2 pcs Breaded Chicken (Rice Meal)', 'RICE MEAL', 'Two pieces of breaded chicken with rice.', 145.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:45', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (11).jpeg', 18),
(65, 'BBQ w/ Shanghai (Rice Meal)', 'RICE MEAL', 'Pork BBQ with shanghai and rice.', 135.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870517646.jpg', 14),
(66, 'BBQ & Chicken Meal (Rice Meal)', 'RICE MEAL', 'Combo of BBQ and chicken with rice.', 145.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870519059.jpg', 16),
(67, 'Bicol Express w/ Shanghai (Rice Meal)', 'RICE MEAL', 'Spicy Bicol Express with shanghai and rice.', 165.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (12).jpeg', 18),
(68, 'Bicol Express w/ Fried Chicken (Rice Meal)', 'RICE MEAL', 'Bicol Express paired with fried chicken and rice.', 165.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/bicolep.jpeg', 20),
(69, 'BBQ w/ Bicol Express (Rice Meal)', 'RICE MEAL', 'Pork BBQ served with Bicol Express and rice.', 140.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/FB_IMG_1763870519059.jpg', 18),
(70, 'Garlic Yellow Rice (Cup)', 'RICE', 'Single cup of garlic turmeric yellow rice.', 27.00, 'Available', 'REGULAR', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (22).jpeg', 1),
(71, 'Garlic Yellow Rice (Small - 3-4 persons)', 'RICE', 'Small tray of garlic yellow rice suitable for 3-4 persons.', 85.00, 'Available', 'SMALL', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (22).jpeg', 5),
(72, 'Garlic Yellow Rice (Medium - 5-6 persons)', 'RICE', 'Medium tray of garlic yellow rice for 5-6 persons.', 140.00, 'Available', 'MEDIUM', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (22).jpeg', 8),
(73, 'Garlic Yellow Rice (Large - 7-8 persons)', 'RICE', 'Large tray of garlic yellow rice for 7-8 persons.', 185.00, 'Available', 'LARGE', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (22).jpeg', 12),
(74, 'Plain Rice (Cup)', 'RICE', 'Single cup of steamed plain rice.', 18.00, 'Available', 'REGULAR', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/how-to-cook-rice.jpg', 1),
(75, 'Plain Rice (Small - 3-4 persons)', 'RICE', 'Small tray of plain steamed rice for 3-4 persons.', 65.00, 'Available', 'SMALL', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/how-to-cook-rice.jpg', 5),
(76, 'Plain Rice (Medium - 5-6 persons)', 'RICE', 'Medium tray of plain rice for 5-6 persons.', 95.00, 'Available', 'MEDIUM', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/how-to-cook-rice.jpg', 8),
(77, 'Plain Rice (Large - 7-8 persons)', 'RICE', 'Large tray of plain rice for 7-8 persons.', 130.00, 'Available', 'LARGE', '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/how-to-cook-rice.jpg', 12),
(78, 'Pancit Canton Guisado (Good for 3-4 persons)', 'NOODLES & PASTA', 'Stir-fried pancit canton good for small group.', 200.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (4).jpg', 18),
(79, 'Pancit Canton Guisado (Small 8-10 persons)', 'NOODLES & PASTA', 'Small pancit canton for 8-10 persons.', 585.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (4).jpg', 30),
(80, 'Pancit Canton Guisado (Medium 12-15 persons)', 'NOODLES & PASTA', 'Medium pancit canton for 12-15 persons.', 880.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (4).jpg', 45),
(81, 'Pancit Canton Guisado (Large 17-20 persons)', 'NOODLES & PASTA', 'Large pancit canton for 17-20 persons.', 1150.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (4).jpg', 60),
(82, 'Bihon Miki Bihon (Good for 3-4 persons)', 'NOODLES & PASTA', 'Light bihon noodles suitable for 3-4 persons.', 200.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (28).jpeg', 18),
(83, 'Bihon Miki Bihon (Small 8-10 persons)', 'NOODLES & PASTA', 'Small bihon tray for 8-10 persons.', 585.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (28).jpeg', 30),
(84, 'Bihon Miki Bihon (Medium 12-15 persons)', 'NOODLES & PASTA', 'Medium bihon tray for 12-15 persons.', 880.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (28).jpeg', 45),
(85, 'Bihon Miki Bihon (Large 17-20 persons)', 'NOODLES & PASTA', 'Large bihon tray for 17-20 persons.', 1150.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:46', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (28).jpeg', 60),
(86, 'Sotanghon (Good for 3-4 persons)', 'NOODLES & PASTA', 'Glass noodle (sotanghon) dish for 3-4 persons.', 240.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (29).jpeg', 20),
(87, 'Sotanghon (Small 8-10 persons)', 'NOODLES & PASTA', 'Small sotanghon tray for 8-10 persons.', 690.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (29).jpeg', 35),
(88, 'Sotanghon (Medium 12-15 persons)', 'NOODLES & PASTA', 'Medium sotanghon tray for 12-15 persons.', 1050.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (29).jpeg', 50),
(89, 'Sotanghon (Large 17-20 persons)', 'NOODLES & PASTA', 'Large sotanghon tray for 17-20 persons.', 1390.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/images (29).jpeg', 70),
(90, 'Spaghetti Carbonara (Good for 3-4 persons)', 'NOODLES & PASTA', 'Creamy carbonara spaghetti for 3-4 people.', 255.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-12-08 20:24:06', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (5).jpg', 25),
(91, 'Spaghetti Carbonara (Small 8-10 persons)', 'NOODLES & PASTA', 'Small carbonara tray for 8-10 persons.', 730.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (5).jpg', 40),
(92, 'Spaghetti Carbonara (Medium 12-15 persons)', 'NOODLES & PASTA', 'Medium carbonara tray for 12-15 persons.', 1080.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (5).jpg', 60),
(93, 'Spaghetti Carbonara (Large 17-20 persons)', 'NOODLES & PASTA', 'Large carbonara tray for 17-20 persons.', 1495.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (5).jpg', 80),
(94, 'Palabok (Good for 3-4 persons)', 'NOODLES & PASTA', 'Traditional palabok for 3-4 persons.', 255.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (6).jpg', 25),
(95, 'Palabok (Small 8-10 persons)', 'NOODLES & PASTA', 'Small palabok tray for 8-10 persons.', 730.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (6).jpg', 40),
(96, 'Palabok (Medium 12-15 persons)', 'NOODLES & PASTA', 'Medium palabok tray for 12-15 persons.', 1080.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (6).jpg', 60),
(97, 'Palabok (Large 17-20 persons)', 'NOODLES & PASTA', 'Large palabok tray for 17-20 persons.', 1495.00, 'Available', NULL, '2025-11-21 23:38:14', '2025-11-23 21:33:47', NULL, 'Regular', 'All Day', 0, 'uploads/products/download (6).jpg', 80);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD KEY `idx_products_category` (`Category`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
