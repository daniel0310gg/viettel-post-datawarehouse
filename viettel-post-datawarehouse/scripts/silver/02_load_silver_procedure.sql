-- =====================================================
-- Viettel Post Data Warehouse - SILVER Layer Load Script
-- =====================================================
-- Purpose: Load and transform data from Bronze to Silver layer
-- Layer: Silver (Cleansed Data)
-- Load Method: Full Load (Truncate & Insert)
-- =====================================================

USE viettel_post_dwh;
GO

-- =====================================================
-- Stored Procedure: load_silver
-- Purpose: Orchestrate Silver layer ETL process
-- =====================================================
IF OBJECT_ID('silver.load_silver', 'P') IS NOT NULL
    DROP PROCEDURE silver.load_silver;
GO

CREATE PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @start_time DATETIME = GETDATE();
    DECLARE @end_time DATETIME;
    DECLARE @duration_seconds INT;
    DECLARE @row_count INT;
    DECLARE @error_message NVARCHAR(4000);
    
    BEGIN TRY
        PRINT '=====================================================';
        PRINT 'SILVER LAYER LOAD STARTED';
        PRINT '=====================================================';
        PRINT 'Start Time: ' + CONVERT(NVARCHAR(30), @start_time, 120);
        PRINT '';
        
        -- ================================================
        -- Load silver.viettel_customers
        -- ================================================
        PRINT '[1/4] Transforming and loading silver.viettel_customers...';
        TRUNCATE TABLE silver.viettel_customers;
        
        INSERT INTO silver.viettel_customers (
            customer_id,
            customer_name,
            customer_type,
            registration_date,
            email,
            phone,
            province,
            is_active,
            customer_segment
        )
        SELECT DISTINCT
            LTRIM(RTRIM(customer_id)) AS customer_id,
            LTRIM(RTRIM(customer_name)) AS customer_name,
            CASE 
                WHEN LTRIM(RTRIM(customer_type)) IN ('Individual', 'Business', 'E-commerce') 
                THEN LTRIM(RTRIM(customer_type))
                ELSE 'Unknown'
            END AS customer_type,
            TRY_CAST(registration_date AS DATE) AS registration_date,
            LOWER(LTRIM(RTRIM(email))) AS email,
            LTRIM(RTRIM(phone)) AS phone,
            UPPER(LTRIM(RTRIM(province))) AS province,
            CASE 
                WHEN LOWER(LTRIM(RTRIM(CAST(is_active AS NVARCHAR(50))))) = 'true' THEN 1
                WHEN LOWER(LTRIM(RTRIM(CAST(is_active AS NVARCHAR(50))))) = 'false' THEN 0
                WHEN CAST(is_active AS NVARCHAR(50)) = '1' THEN 1
                WHEN CAST(is_active AS NVARCHAR(50)) = '0' THEN 0
                ELSE 0
            END AS is_active,
            CASE 
                WHEN LTRIM(RTRIM(customer_segment)) IN ('Regular', 'VIP', 'New', 'At Risk') 
                THEN LTRIM(RTRIM(customer_segment))
                ELSE 'Regular'
            END AS customer_segment
        FROM bronze.viettel_customers
        WHERE customer_id IS NOT NULL
          AND LTRIM(RTRIM(CAST(customer_id AS NVARCHAR(50)))) <> '';
        
        SET @row_count = @@ROWCOUNT;
        PRINT '  -> Transformed and loaded ' + CAST(@row_count AS NVARCHAR(20)) + ' rows';
        PRINT '';

        -- ================================================
        -- Load silver.viettel_locations
        -- ================================================
        PRINT '[2/4] Transforming and loading silver.viettel_locations...';
        TRUNCATE TABLE silver.viettel_locations;
        
        INSERT INTO silver.viettel_locations (
            location_id,
            location_name,
            location_type,
            province,
            district,
            address,
            latitude,
            longitude,
            capacity_sqm,
            has_sorting_system,
            is_active
        )
        SELECT DISTINCT
            LTRIM(RTRIM(location_id)) AS location_id,
            LTRIM(RTRIM(location_name)) AS location_name,
            CASE 
                WHEN LTRIM(RTRIM(location_type)) IN ('Hub', 'Warehouse', 'Post Office', 'Collection Point') 
                THEN LTRIM(RTRIM(location_type))
                ELSE 'Unknown'
            END AS location_type,
            UPPER(LTRIM(RTRIM(province))) AS province,
            UPPER(LTRIM(RTRIM(district))) AS district,
            LTRIM(RTRIM(address)) AS address,
            TRY_CAST(latitude AS DECIMAL(10,8)) AS latitude,
            TRY_CAST(longitude AS DECIMAL(11,8)) AS longitude,
            TRY_CAST(capacity_sqm AS INT) AS capacity_sqm,
            CASE 
                WHEN LOWER(LTRIM(RTRIM(CAST(has_sorting_system AS NVARCHAR(50))))) = 'true' THEN 1
                WHEN LOWER(LTRIM(RTRIM(CAST(has_sorting_system AS NVARCHAR(50))))) = 'false' THEN 0
                WHEN CAST(has_sorting_system AS NVARCHAR(50)) = '1' THEN 1
                WHEN CAST(has_sorting_system AS NVARCHAR(50)) = '0' THEN 0
                ELSE 0
            END AS has_sorting_system,
            CASE 
                WHEN LOWER(LTRIM(RTRIM(CAST(is_active AS NVARCHAR(50))))) = 'true' THEN 1
                WHEN LOWER(LTRIM(RTRIM(CAST(is_active AS NVARCHAR(50))))) = 'false' THEN 0
                WHEN CAST(is_active AS NVARCHAR(50)) = '1' THEN 1
                WHEN CAST(is_active AS NVARCHAR(50)) = '0' THEN 0
                ELSE 1
            END AS is_active
        FROM bronze.viettel_locations
        WHERE location_id IS NOT NULL
          AND LTRIM(RTRIM(CAST(location_id AS NVARCHAR(50)))) <> '';
        
        SET @row_count = @@ROWCOUNT;
        PRINT '  -> Transformed and loaded ' + CAST(@row_count AS NVARCHAR(20)) + ' rows';
        PRINT '';

        -- ================================================
        -- Load silver.viettel_routes
        -- ================================================
        PRINT '[3/4] Transforming and loading silver.viettel_routes...';
        TRUNCATE TABLE silver.viettel_routes;
        
        INSERT INTO silver.viettel_routes (
            route_id,
            route_name,
            origin_province,
            destination_province,
            distance_km,
            estimated_duration_hours,
            route_type,
            transport_mode,
            is_express_route
        )
        SELECT DISTINCT
            LTRIM(RTRIM(route_id)) AS route_id,
            LTRIM(RTRIM(route_name)) AS route_name,
            UPPER(LTRIM(RTRIM(origin_province))) AS origin_province,
            UPPER(LTRIM(RTRIM(destination_province))) AS destination_province,
            TRY_CAST(distance_km AS DECIMAL(10,2)) AS distance_km,
            TRY_CAST(estimated_duration_hours AS DECIMAL(6,2)) AS estimated_duration_hours,
            CASE 
                WHEN LTRIM(RTRIM(route_type)) IN ('Standard', 'Express', 'Economy') 
                THEN LTRIM(RTRIM(route_type))
                ELSE 'Standard'
            END AS route_type,
            CASE 
                WHEN LTRIM(RTRIM(transport_mode)) IN ('Road', 'Air', 'Rail', 'Sea') 
                THEN LTRIM(RTRIM(transport_mode))
                ELSE 'Road'
            END AS transport_mode,
            CASE 
                WHEN LOWER(LTRIM(RTRIM(CAST(is_express_route AS NVARCHAR(50))))) = 'true' THEN 1
                WHEN LOWER(LTRIM(RTRIM(CAST(is_express_route AS NVARCHAR(50))))) = 'false' THEN 0
                WHEN CAST(is_express_route AS NVARCHAR(50)) = '1' THEN 1
                WHEN CAST(is_express_route AS NVARCHAR(50)) = '0' THEN 0
                ELSE 0
            END AS is_express_route
        FROM bronze.viettel_routes
        WHERE route_id IS NOT NULL
          AND LTRIM(RTRIM(CAST(route_id AS NVARCHAR(50)))) <> '';
        
        SET @row_count = @@ROWCOUNT;
        PRINT '  -> Transformed and loaded ' + CAST(@row_count AS NVARCHAR(20)) + ' rows';
        PRINT '';

        -- ================================================
        -- Load silver.viettel_shipments
        -- ================================================
        PRINT '[4/4] Transforming and loading silver.viettel_shipments...';
        TRUNCATE TABLE silver.viettel_shipments;
        
        INSERT INTO silver.viettel_shipments (
            shipment_id,
            customer_id,
            pickup_datetime,
            delivery_datetime,
            origin_province,
            destination_province,
            route_id,
            service_type,
            package_type,
            weight_kg,
            volume_cbm,
            declared_value,
            shipping_fee,
            insurance_fee,
            cod_amount,
            cod_fee,
            total_revenue,
            actual_delivery_hours,
            promised_delivery_hours,
            is_delivered,
            is_on_time,
            is_cod,
            is_damaged,
            is_returned,
            customer_rating,
            current_status
        )
        SELECT DISTINCT
            LTRIM(RTRIM(shipment_id)) AS shipment_id,
            LTRIM(RTRIM(customer_id)) AS customer_id,
            TRY_CAST(pickup_datetime AS DATETIME) AS pickup_datetime,
            TRY_CAST(delivery_datetime AS DATETIME) AS delivery_datetime,
            UPPER(LTRIM(RTRIM(origin_province))) AS origin_province,
            UPPER(LTRIM(RTRIM(destination_province))) AS destination_province,
            LTRIM(RTRIM(route_id)) AS route_id,
            CASE 
                WHEN LTRIM(RTRIM(service_type)) IN ('Standard', 'Express', 'Economy', 'Premium') 
                THEN LTRIM(RTRIM(service_type))
                ELSE 'Standard'
            END AS service_type,
            CASE 
                WHEN LTRIM(RTRIM(package_type)) IN ('Document', 'Parcel', 'Bulk', 'Fragile') 
                THEN LTRIM(RTRIM(package_type))
                ELSE 'Parcel'
            END AS package_type,
            TRY_CAST(weight_kg AS DECIMAL(10,2)) AS weight_kg,
            TRY_CAST(volume_cbm AS DECIMAL(10,4)) AS volume_cbm,
            TRY_CAST(declared_value AS DECIMAL(18,2)) AS declared_value,
            TRY_CAST(shipping_fee AS DECIMAL(18,2)) AS shipping_fee,
            TRY_CAST(insurance_fee AS DECIMAL(18,2)) AS insurance_fee,
            TRY_CAST(cod_amount AS DECIMAL(18,2)) AS cod_amount,
            TRY_CAST(cod_fee AS DECIMAL(18,2)) AS cod_fee,
            TRY_CAST(total_revenue AS DECIMAL(18,2)) AS total_revenue,
            TRY_CAST(actual_delivery_hours AS DECIMAL(10,2)) AS actual_delivery_hours,
            TRY_CAST(promised_delivery_hours AS DECIMAL(10,2)) AS promised_delivery_hours,
            CASE 
                WHEN LOWER(LTRIM(RTRIM(CAST(is_delivered AS NVARCHAR(50))))) = 'true' THEN 1
                WHEN LOWER(LTRIM(RTRIM(CAST(is_delivered AS NVARCHAR(50))))) = 'false' THEN 0
                WHEN CAST(is_delivered AS NVARCHAR(50)) = '1' THEN 1
                WHEN CAST(is_delivered AS NVARCHAR(50)) = '0' THEN 0
                ELSE 0
            END AS is_delivered,
            CASE 
                WHEN LOWER(LTRIM(RTRIM(CAST(is_on_time AS NVARCHAR(50))))) = 'true' THEN 1
                WHEN LOWER(LTRIM(RTRIM(CAST(is_on_time AS NVARCHAR(50))))) = 'false' THEN 0
                WHEN CAST(is_on_time AS NVARCHAR(50)) = '1' THEN 1
                WHEN CAST(is_on_time AS NVARCHAR(50)) = '0' THEN 0
                ELSE 0
            END AS is_on_time,
            CASE 
                WHEN LOWER(LTRIM(RTRIM(CAST(is_cod AS NVARCHAR(50))))) = 'true' THEN 1
                WHEN LOWER(LTRIM(RTRIM(CAST(is_cod AS NVARCHAR(50))))) = 'false' THEN 0
                WHEN CAST(is_cod AS NVARCHAR(50)) = '1' THEN 1
                WHEN CAST(is_cod AS NVARCHAR(50)) = '0' THEN 0
                ELSE 0
            END AS is_cod,
            CASE 
                WHEN LOWER(LTRIM(RTRIM(CAST(is_damaged AS NVARCHAR(50))))) = 'true' THEN 1
                WHEN LOWER(LTRIM(RTRIM(CAST(is_damaged AS NVARCHAR(50))))) = 'false' THEN 0
                WHEN CAST(is_damaged AS NVARCHAR(50)) = '1' THEN 1
                WHEN CAST(is_damaged AS NVARCHAR(50)) = '0' THEN 0
                ELSE 0
            END AS is_damaged,
            CASE 
                WHEN LOWER(LTRIM(RTRIM(CAST(is_returned AS NVARCHAR(50))))) = 'true' THEN 1
                WHEN LOWER(LTRIM(RTRIM(CAST(is_returned AS NVARCHAR(50))))) = 'false' THEN 0
                WHEN CAST(is_returned AS NVARCHAR(50)) = '1' THEN 1
                WHEN CAST(is_returned AS NVARCHAR(50)) = '0' THEN 0
                ELSE 0
            END AS is_returned,
            TRY_CAST(customer_rating AS DECIMAL(3,1)) AS customer_rating,
            CASE 
                WHEN LTRIM(RTRIM(current_status)) IN ('Pending', 'In Transit', 'Delivered', 'Cancelled', 'Returned', 'On Hold') 
                THEN LTRIM(RTRIM(current_status))
                ELSE 'Pending'
            END AS current_status
        FROM bronze.viettel_shipments
        WHERE shipment_id IS NOT NULL
          AND LTRIM(RTRIM(CAST(shipment_id AS NVARCHAR(50)))) <> '';
        
        SET @row_count = @@ROWCOUNT;
        PRINT '  -> Transformed and loaded ' + CAST(@row_count AS NVARCHAR(20)) + ' rows';
        PRINT '';

        -- ================================================
        -- Summary
        -- ================================================
        SET @end_time = GETDATE();
        SET @duration_seconds = DATEDIFF(SECOND, @start_time, @end_time);
        
        PRINT '=====================================================';
        PRINT 'SILVER LAYER LOAD COMPLETED SUCCESSFULLY';
        PRINT '=====================================================';
        PRINT 'End Time: ' + CONVERT(NVARCHAR(30), @end_time, 120);
        PRINT 'Duration: ' + CAST(@duration_seconds AS NVARCHAR(20)) + ' seconds';
        PRINT '';
        PRINT 'Summary:';
        PRINT '  - silver.viettel_customers: Loaded';
        PRINT '  - silver.viettel_locations: Loaded';
        PRINT '  - silver.viettel_routes: Loaded';
        PRINT '  - silver.viettel_shipments: Loaded';
        PRINT '=====================================================';
        
    END TRY
    BEGIN CATCH
        SET @error_message = ERROR_MESSAGE();
        
        PRINT '';
        PRINT '=====================================================';
        PRINT 'ERROR: SILVER LAYER LOAD FAILED';
        PRINT '=====================================================';
        PRINT 'Error Message: ' + @error_message;
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR(20));
        PRINT 'Error Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
        PRINT '=====================================================';
        
        -- Re-throw the error
        THROW;
    END CATCH
END;
GO

PRINT '=====================================================';
PRINT 'Stored Procedure Created: silver.load_silver';
PRINT '=====================================================';
PRINT '';
PRINT 'To execute the Silver layer load, run:';
PRINT 'EXEC silver.load_silver;';
PRINT '';
GO