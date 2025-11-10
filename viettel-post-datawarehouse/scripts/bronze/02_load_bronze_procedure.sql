-- =====================================================
-- Viettel Post Data Warehouse - BRONZE Layer Load
-- =====================================================
-- Purpose: Load raw data from CSV files into Bronze tables
-- Method: Full Load (Truncate & Insert)
-- =====================================================

USE viettel_post_dwh;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
    DECLARE @start_time DATETIME = GETDATE();
    DECLARE @row_count INT;
    
    BEGIN TRY
        PRINT '=====================================================';
        PRINT 'BRONZE LAYER LOAD STARTED';
        PRINT '=====================================================';
        PRINT 'Start Time: ' + CAST(@start_time AS NVARCHAR);
        PRINT '';
        
        -- ================================================
        -- Load bronze.viettel_customers
        -- ================================================
        PRINT '[1/4] Loading bronze.viettel_customers...';
        TRUNCATE TABLE bronze.viettel_customers;
        
        BULK INSERT bronze.viettel_customers
        FROM 'D:\New folder\viettel_post_prep\viettel_customers.csv'
        WITH (
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            FIRSTROW = 2,  -- Skip header row
            CODEPAGE = '65001',  -- UTF-8 encoding
            TABLOCK
        );
        
        SET @row_count = @@ROWCOUNT;
        PRINT '  ✓ Loaded ' + CAST(@row_count AS NVARCHAR) + ' rows';
        PRINT '';
        
        -- ================================================
        -- Load bronze.viettel_locations
        -- ================================================
        PRINT '[2/4] Loading bronze.viettel_locations...';
        TRUNCATE TABLE bronze.viettel_locations;
        
      BULK INSERT bronze.viettel_locations
	FROM 'D:\New folder\viettel_post_prep\viettel_locations.csv'
	WITH (
		FIELDTERMINATOR = ',',
		ROWTERMINATOR = '0x0a',
		FIRSTROW = 2,
		CODEPAGE = '65001',
		TABLOCK,
		FIELDQUOTE = '"',  -- This helps handle quoted fields with embedded newlines
		FORMAT = 'CSV'      -- Use CSV format which handles quotes better
	);
        
        SET @row_count = @@ROWCOUNT;
        PRINT '  ✓ Loaded ' + CAST(@row_count AS NVARCHAR) + ' rows';
        PRINT '';
        
        -- ================================================
        -- Load bronze.viettel_routes
        -- ================================================
        PRINT '[3/4] Loading bronze.viettel_routes...';
        TRUNCATE TABLE bronze.viettel_routes;
        
        BULK INSERT bronze.viettel_routes
        FROM 'D:\New folder\viettel_post_prep\viettel_routes.csv'
        WITH (
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            FIRSTROW = 2,
            CODEPAGE = '65001',
            TABLOCK
        );
        
        SET @row_count = @@ROWCOUNT;
        PRINT '  ✓ Loaded ' + CAST(@row_count AS NVARCHAR) + ' rows';
        PRINT '';
        
        -- ================================================
        -- Load bronze.viettel_shipments
        -- ================================================
        PRINT '[4/4] Loading bronze.viettel_shipments...';
        TRUNCATE TABLE bronze.viettel_shipments;
        
        BULK INSERT bronze.viettel_shipments
        FROM 'D:\New folder\viettel_post_prep\viettel_shipments.csv'
        WITH (
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '0x0a',
            FIRSTROW = 2,
            CODEPAGE = '65001',
            TABLOCK
        );
        
        SET @row_count = @@ROWCOUNT;
        PRINT '  ✓ Loaded ' + CAST(@row_count AS NVARCHAR) + ' rows';
        PRINT '';
        
        -- ================================================
        -- Summary
        -- ================================================
        DECLARE @end_time DATETIME = GETDATE();
        DECLARE @duration INT = DATEDIFF(SECOND, @start_time, @end_time);
        
        PRINT '=====================================================';
        PRINT 'BRONZE LAYER LOAD COMPLETED SUCCESSFULLY';
        PRINT '=====================================================';
        PRINT 'End Time: ' + CAST(@end_time AS NVARCHAR);
        PRINT 'Duration: ' + CAST(@duration AS NVARCHAR) + ' seconds';
        PRINT '=====================================================';
        
    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT '❌ ERROR OCCURRED';
        PRINT '=====================================================';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT 'Error Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
        PRINT '=====================================================';
        THROW;
    END CATCH
END;
GO

-- Grant execute permission
GRANT EXECUTE ON bronze.load_bronze TO PUBLIC;
GO

PRINT 'Bronze layer load procedure created successfully';
PRINT 'Execute with: EXEC bronze.load_bronze';
GO
