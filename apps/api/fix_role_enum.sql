-- ============================================
-- Fix role column to include all roles
-- ============================================
-- This script updates the role column ENUM to include all valid roles
-- Run this in phpMyAdmin SQL tab
-- ============================================

-- Change the role column from ENUM('CLIENT','ADMIN') to ENUM('CLIENT','ADMIN','ACCOUNTANT','CA')
ALTER TABLE `users` 
MODIFY COLUMN `role` ENUM('CLIENT', 'ADMIN', 'ACCOUNTANT', 'CA') DEFAULT 'CLIENT';

-- Verification: Check the updated column
DESCRIBE users;

-- Show current users and their roles
SELECT UserId, FirstName, LastName, Email, role, IsActive FROM users ORDER BY UserId;
