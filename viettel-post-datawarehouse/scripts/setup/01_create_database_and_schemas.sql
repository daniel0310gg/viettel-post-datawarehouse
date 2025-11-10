-- =====================================================
-- Viettel Post Data Warehouse - Database Setup
-- =====================================================
-- Purpose: Create database and schemas following Medallion Architecture
-- Author: AI Agent
-- Date: 2025-11-09
-- =====================================================

-- Create database
CREATE DATABASE viettel_post_dwh;
GO

-- Use the database
USE viettel_post_dwh;
GO

-- Create schemas for Medallion Architecture layers
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO

-- Display confirmation
PRINT '==============================================';
PRINT 'Database and Schemas Created Successfully';
PRINT '==============================================';
PRINT 'Database: viettel_post_dwh';
PRINT 'Schemas:';
PRINT '  - bronze (Raw data layer)';
PRINT '  - silver (Cleansed data layer)';
PRINT '  - gold (Business-ready data layer)';
PRINT '==============================================';
GO
