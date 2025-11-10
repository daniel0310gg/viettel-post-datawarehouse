-- =====================================================
-- Viettel Post Data Warehouse - Master Load Procedure
-- =====================================================
-- Purpose: Orchestrate end-to-end data warehouse load
-- =====================================================

USE viettel_post_dwh;
GO

CREATE OR ALTER PROCEDURE load_data_warehouse
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @start_time DATETIME = GETDATE();
    DECLARE @end_time DATETIME;
    DECLARE @bronze_start DATETIME;
    DECLARE @silver_start DATETIME;
    DECLARE @bronze_duration INT;
    DECLARE @silver_duration INT;
    DECLARE @total_duration INT;
    
    -- Variables for row counts
    DECLARE @customers_count INT;
    DECLARE @locations_count INT;
    DECLARE @routes_count INT;
    DECLARE @shipments_count INT;
    
    BEGIN TRY
        PRINT '========================================================';
        PRINT '     VIETTEL POST DATA WAREHOUSE - MASTER LOAD';
        PRINT '========================================================';
        PRINT 'Load Started: ' + CONVERT(NVARCHAR(30), @start_time, 120);
        PRINT '========================================================';
        PRINT '';
        
        -- ================================================
        -- BRONZE LAYER LOAD
        -- ================================================
        SET @bronze_start = GETDATE();
        PRINT '+--------------------------------------------------+';
        PRINT '|           BRONZE LAYER (Raw Data)                |';
        PRINT '+--------------------------------------------------+';
        PRINT '';
        
        EXEC bronze.load_bronze;
        
        SET @bronze_duration = DATEDIFF(SECOND, @bronze_start, GETDATE());
        PRINT '';
        PRINT '-> Bronze layer completed in ' + CAST(@bronze_duration AS NVARCHAR(20)) + ' seconds';
        PRINT '';
        PRINT '';
        
        -- ================================================
        -- SILVER LAYER LOAD
        -- ================================================
        SET @silver_start = GETDATE();
        PRINT '+--------------------------------------------------+';
        PRINT '|      SILVER LAYER (Cleansed Data)                |';
        PRINT '+--------------------------------------------------+';
        PRINT '';
        
        EXEC silver.load_silver;
        
        SET @silver_duration = DATEDIFF(SECOND, @silver_start, GETDATE());
        PRINT '';
        PRINT '-> Silver layer completed in ' + CAST(@silver_duration AS NVARCHAR(20)) + ' seconds';
        PRINT '';
        PRINT '';
        
        -- ================================================
        -- GOLD LAYER (Views - No Load Needed)
        -- ================================================
        PRINT '+--------------------------------------------------+';
        PRINT '|      GOLD LAYER (Business-Ready Data)            |';
        PRINT '+--------------------------------------------------+';
        PRINT '';
        PRINT 'Gold layer uses views - no data load required.';
        PRINT 'Views will automatically reflect latest Silver data.';
        PRINT '';
        
        -- ================================================
        -- SUMMARY STATISTICS
        -- ================================================
        SET @end_time = GETDATE();
        SET @total_duration = DATEDIFF(SECOND, @start_time, @end_time);
        
        -- Get row counts into variables
        SELECT @customers_count = COUNT(*) FROM silver.viettel_customers;
        SELECT @locations_count = COUNT(*) FROM silver.viettel_locations;
        SELECT @routes_count = COUNT(*) FROM silver.viettel_routes;
        SELECT @shipments_count = COUNT(*) FROM silver.viettel_shipments;
        
        PRINT '========================================================';
        PRINT '                  LOAD COMPLETED SUCCESSFULLY';
        PRINT '========================================================';
        PRINT 'Summary Statistics:';
        PRINT '--------------------------------------------------------';
        PRINT 'Customers Loaded     : ' + CAST(@customers_count AS NVARCHAR(20));
        PRINT 'Locations Loaded     : ' + CAST(@locations_count AS NVARCHAR(20));
        PRINT 'Routes Loaded        : ' + CAST(@routes_count AS NVARCHAR(20));
        PRINT 'Shipments Loaded     : ' + CAST(@shipments_count AS NVARCHAR(20));
        PRINT '--------------------------------------------------------';
        PRINT 'Bronze Layer Time    : ' + CAST(@bronze_duration AS NVARCHAR(20)) + ' seconds';
        PRINT 'Silver Layer Time    : ' + CAST(@silver_duration AS NVARCHAR(20)) + ' seconds';
        PRINT 'Total Duration       : ' + CAST(@total_duration AS NVARCHAR(20)) + ' seconds';
        PRINT '--------------------------------------------------------';
        PRINT 'Load Completed       : ' + CONVERT(NVARCHAR(30), @end_time, 120);
        PRINT '========================================================';
        PRINT '';
        PRINT 'Data warehouse is ready for analytics!';
        PRINT 'Access business-ready data through Gold layer views:';
        PRINT '  - gold.dim_customers';
        PRINT '  - gold.dim_locations';
        PRINT '  - gold.dim_routes';
        PRINT '  - gold.dim_date';
        PRINT '  - gold.fact_shipments';
        PRINT '  - gold.report_*  (analytics views)';
        PRINT '';
        
    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT '========================================================';
        PRINT '                    ERROR OCCURRED';
        PRINT '========================================================';
        PRINT 'Error Message  : ' + ERROR_MESSAGE();
        PRINT 'Error Number   : ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error Line     : ' + CAST(ERROR_LINE() AS NVARCHAR(20));
        PRINT 'Error Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
        PRINT 'Time of Error  : ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
        PRINT '========================================================';
        THROW;
    END CATCH
END;
GO

PRINT '========================================================';
PRINT 'Master load procedure created successfully!';
PRINT '';
PRINT 'To load the entire data warehouse, execute:';
PRINT '  EXEC load_data_warehouse;';
PRINT '';
PRINT 'This will:';
PRINT '  1. Load Bronze layer (raw data from CSV files)';
PRINT '  2. Transform and load Silver layer (cleansed data)';
PRINT '  3. Make Gold layer available (business views)';
PRINT '========================================================';
GO