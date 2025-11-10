-- =====================================================
-- Viettel Post Data Warehouse - Validation Script
-- =====================================================
-- Purpose: Validate data quality and completeness
-- Run after: load_data_warehouse
-- =====================================================

USE viettel_post_dwh;
GO

PRINT '========================================================';
PRINT '     VIETTEL POST DATA WAREHOUSE - VALIDATION';
PRINT '========================================================';
PRINT '';

-- =====================================================
-- 1. ROW COUNT VALIDATION
-- =====================================================
PRINT '1. ROW COUNT VALIDATION';
PRINT '--------------------------------------------------------';

SELECT 
    'Bronze Layer' AS layer,
    'viettel_customers' AS table_name,
    COUNT(*) AS row_count
FROM bronze.viettel_customers
UNION ALL
SELECT 'Bronze Layer', 'viettel_locations', COUNT(*) FROM bronze.viettel_locations
UNION ALL
SELECT 'Bronze Layer', 'viettel_routes', COUNT(*) FROM bronze.viettel_routes
UNION ALL
SELECT 'Bronze Layer', 'viettel_shipments', COUNT(*) FROM bronze.viettel_shipments
UNION ALL
SELECT 'Silver Layer', 'viettel_customers', COUNT(*) FROM silver.viettel_customers
UNION ALL
SELECT 'Silver Layer', 'viettel_locations', COUNT(*) FROM silver.viettel_locations
UNION ALL
SELECT 'Silver Layer', 'viettel_routes', COUNT(*) FROM silver.viettel_routes
UNION ALL
SELECT 'Silver Layer', 'viettel_shipments', COUNT(*) FROM silver.viettel_shipments
UNION ALL
SELECT 'Gold Layer', 'dim_customers', COUNT(*) FROM gold.dim_customers
UNION ALL
SELECT 'Gold Layer', 'dim_locations', COUNT(*) FROM gold.dim_locations
UNION ALL
SELECT 'Gold Layer', 'dim_routes', COUNT(*) FROM gold.dim_routes
UNION ALL
SELECT 'Gold Layer', 'dim_date', COUNT(*) FROM gold.dim_date
UNION ALL
SELECT 'Gold Layer', 'dim_service_types', COUNT(*) FROM gold.dim_service_types
UNION ALL
SELECT 'Gold Layer', 'fact_shipments', COUNT(*) FROM gold.fact_shipments
ORDER BY layer, table_name;

PRINT '';
PRINT '';

-- =====================================================
-- 2. PRIMARY KEY UNIQUENESS
-- =====================================================
PRINT '2. PRIMARY KEY UNIQUENESS VALIDATION';
PRINT '--------------------------------------------------------';

-- Check for duplicate customer IDs
SELECT 
    'silver.viettel_customers' AS table_name,
    'customer_id' AS key_field,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_count
FROM silver.viettel_customers
UNION ALL
SELECT 
    'silver.viettel_locations',
    'location_id',
    COUNT(*) - COUNT(DISTINCT location_id)
FROM silver.viettel_locations
UNION ALL
SELECT 
    'silver.viettel_routes',
    'route_id',
    COUNT(*) - COUNT(DISTINCT route_id)
FROM silver.viettel_routes
UNION ALL
SELECT 
    'silver.viettel_shipments',
    'shipment_id',
    COUNT(*) - COUNT(DISTINCT shipment_id)
FROM silver.viettel_shipments;

PRINT '';
PRINT 'Expected Result: All duplicate_count should be 0';
PRINT '';
PRINT '';

-- =====================================================
-- 3. NULL CHECK IN REQUIRED FIELDS
-- =====================================================
PRINT '3. NULL CHECK IN REQUIRED FIELDS';
PRINT '--------------------------------------------------------';

SELECT 
    'silver.viettel_customers' AS table_name,
    'customer_id' AS field_name,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_count
FROM silver.viettel_customers
UNION ALL
SELECT 
    'silver.viettel_shipments',
    'shipment_id',
    SUM(CASE WHEN shipment_id IS NULL THEN 1 ELSE 0 END)
FROM silver.viettel_shipments
UNION ALL
SELECT 
    'silver.viettel_shipments',
    'customer_id',
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)
FROM silver.viettel_shipments
UNION ALL
SELECT 
    'silver.viettel_shipments',
    'pickup_datetime',
    SUM(CASE WHEN pickup_datetime IS NULL THEN 1 ELSE 0 END)
FROM silver.viettel_shipments;

PRINT '';
PRINT 'Expected Result: All null_count should be 0';
PRINT '';
PRINT '';

-- =====================================================
-- 4. REFERENTIAL INTEGRITY
-- =====================================================
PRINT '4. REFERENTIAL INTEGRITY VALIDATION';
PRINT '--------------------------------------------------------';

-- Check for orphan customer references
SELECT 
    'Orphan Customers in Shipments' AS check_name,
    COUNT(*) AS orphan_count
FROM silver.viettel_shipments s
LEFT JOIN silver.viettel_customers c ON s.customer_id = c.customer_id
WHERE s.customer_id IS NOT NULL AND c.customer_id IS NULL

UNION ALL

-- Check for orphan route references
SELECT 
    'Orphan Routes in Shipments',
    COUNT(*)
FROM silver.viettel_shipments s
LEFT JOIN silver.viettel_routes r ON s.route_id = r.route_id
WHERE s.route_id IS NOT NULL AND r.route_id IS NULL;

PRINT '';
PRINT 'Expected Result: All orphan_count should be 0';
PRINT '';
PRINT '';

-- =====================================================
-- 5. DATA TYPE VALIDATION
-- =====================================================
PRINT '5. DATA TYPE VALIDATION';
PRINT '--------------------------------------------------------';

-- Check for invalid boolean conversions
SELECT 
    'Invalid is_active values' AS check_name,
    COUNT(*) AS invalid_count
FROM silver.viettel_customers
WHERE is_active NOT IN (0, 1)

UNION ALL

SELECT 
    'Invalid is_on_time values',
    COUNT(*)
FROM silver.viettel_shipments
WHERE is_on_time NOT IN (0, 1)

UNION ALL

SELECT 
    'Invalid customer_rating values',
    COUNT(*)
FROM silver.viettel_shipments
WHERE customer_rating IS NOT NULL AND (customer_rating < 1.0 OR customer_rating > 5.0);

PRINT '';
PRINT 'Expected Result: All invalid_count should be 0';
PRINT '';
PRINT '';

-- =====================================================
-- 6. BUSINESS RULE VALIDATION
-- =====================================================
PRINT '6. BUSINESS RULE VALIDATION';
PRINT '--------------------------------------------------------';

-- Check delivery date >= pickup date
SELECT 
    'Delivery before Pickup' AS check_name,
    COUNT(*) AS violation_count
FROM silver.viettel_shipments
WHERE delivery_datetime < pickup_datetime

UNION ALL

-- Check negative amounts
SELECT 
    'Negative Revenue',
    COUNT(*)
FROM silver.viettel_shipments
WHERE total_revenue < 0

UNION ALL

SELECT 
    'Negative Weight',
    COUNT(*)
FROM silver.viettel_shipments
WHERE weight_kg < 0;

PRINT '';
PRINT 'Expected Result: All violation_count should be 0';
PRINT '';
PRINT '';

-- =====================================================
-- 7. GOLD LAYER VALIDATION
-- =====================================================
PRINT '7. GOLD LAYER (STAR SCHEMA) VALIDATION';
PRINT '--------------------------------------------------------';

-- Check fact table joins to dimensions
SELECT 
    'Fact records with all dimension keys' AS check_name,
    COUNT(*) AS valid_count
FROM gold.fact_shipments f
WHERE f.customer_key IS NOT NULL
  AND f.route_key IS NOT NULL
  AND f.pickup_date_key IS NOT NULL
  AND f.service_type_key IS NOT NULL;

PRINT '';
PRINT '';

-- =====================================================
-- 8. SUMMARY STATISTICS
-- =====================================================
PRINT '8. SUMMARY STATISTICS';
PRINT '--------------------------------------------------------';

SELECT 
    'Total Customers' AS metric,
    COUNT(DISTINCT customer_id) AS value
FROM silver.viettel_customers
UNION ALL
SELECT 'Active Customers', COUNT(*) FROM silver.viettel_customers WHERE is_active = 1
UNION ALL
SELECT 'Total Locations', COUNT(*) FROM silver.viettel_locations
UNION ALL
SELECT 'Active Locations', COUNT(*) FROM silver.viettel_locations WHERE is_active = 1
UNION ALL
SELECT 'Total Routes', COUNT(*) FROM silver.viettel_routes
UNION ALL
SELECT 'Total Shipments', COUNT(*) FROM silver.viettel_shipments
UNION ALL
SELECT 'Delivered Shipments', COUNT(*) FROM silver.viettel_shipments WHERE is_delivered = 1
UNION ALL
SELECT 'On-Time Shipments', COUNT(*) FROM silver.viettel_shipments WHERE is_on_time = 1
UNION ALL
SELECT 'COD Shipments', COUNT(*) FROM silver.viettel_shipments WHERE is_cod = 1
UNION ALL
SELECT 'Damaged Shipments', COUNT(*) FROM silver.viettel_shipments WHERE is_damaged = 1
UNION ALL
SELECT 'Returned Shipments', COUNT(*) FROM silver.viettel_shipments WHERE is_returned = 1;

PRINT '';
PRINT '';

-- =====================================================
-- 9. KEY PERFORMANCE INDICATORS
-- =====================================================
PRINT '9. KEY PERFORMANCE INDICATORS (KPIs)';
PRINT '--------------------------------------------------------';

SELECT 
    'On-Time Delivery Rate (%)' AS kpi,
    CAST(SUM(CAST(is_on_time AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS value
FROM silver.viettel_shipments
WHERE is_delivered = 1

UNION ALL

SELECT 
    'Perfect Delivery Rate (%)',
    CAST(SUM(CASE WHEN is_on_time = 1 AND is_damaged = 0 AND is_returned = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2))
FROM silver.viettel_shipments
WHERE is_delivered = 1

UNION ALL

SELECT 
    'Damage Rate (%)',
    CAST(SUM(CAST(is_damaged AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2))
FROM silver.viettel_shipments

UNION ALL

SELECT 
    'Return Rate (%)',
    CAST(SUM(CAST(is_returned AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2))
FROM silver.viettel_shipments

UNION ALL

SELECT 
    'Average Customer Rating',
    CAST(AVG(CAST(customer_rating AS FLOAT)) AS DECIMAL(3,2))
FROM silver.viettel_shipments
WHERE customer_rating IS NOT NULL

UNION ALL

SELECT 
    'Average Delivery Hours',
    CAST(AVG(actual_delivery_hours) AS DECIMAL(6,2))
FROM silver.viettel_shipments
WHERE actual_delivery_hours IS NOT NULL

UNION ALL

SELECT 
    'Average Delay Hours',
    CAST(AVG(delivery_delay_hours) AS DECIMAL(6,2))
FROM silver.viettel_shipments
WHERE delivery_delay_hours > 0;

PRINT '';
PRINT '';

-- =====================================================
-- 10. TOP METRICS
-- =====================================================
PRINT '10. TOP PERFORMERS';
PRINT '--------------------------------------------------------';

PRINT 'Top 5 Customers by Revenue:';
SELECT TOP 5
    c.customer_name,
    c.customer_segment,
    COUNT(f.shipment_id) AS shipments,
    SUM(f.total_revenue) AS total_revenue
FROM gold.dim_customers c
JOIN gold.fact_shipments f ON c.customer_key = f.customer_key
GROUP BY c.customer_name, c.customer_segment
ORDER BY total_revenue DESC;

PRINT '';
PRINT 'Top 5 Routes by Volume:';
SELECT TOP 5
    r.route_name,
    r.transport_mode,
    COUNT(f.shipment_id) AS shipments,
    AVG(f.actual_delivery_hours) AS avg_delivery_hours
FROM gold.dim_routes r
JOIN gold.fact_shipments f ON r.route_key = f.route_key
GROUP BY r.route_name, r.transport_mode
ORDER BY shipments DESC;

PRINT '';
PRINT '';

-- =====================================================
-- VALIDATION COMPLETE
-- =====================================================
PRINT '========================================================';
PRINT '              VALIDATION COMPLETED';
PRINT '========================================================';
PRINT '';
PRINT 'Review the results above:';
PRINT '  ✓ All row counts should be > 0';
PRINT '  ✓ All duplicate counts should be 0';
PRINT '  ✓ All null counts should be 0';
PRINT '  ✓ All orphan counts should be 0';
PRINT '  ✓ All violation counts should be 0';
PRINT '';
PRINT 'If all checks pass, the data warehouse is ready for use!';
PRINT '========================================================';
GO
