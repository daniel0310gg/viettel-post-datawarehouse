-- =====================================================
-- Viettel Post Data Warehouse - GOLD Layer
-- =====================================================
-- Purpose: Create business-ready data models (Star Schema)
-- Layer: Gold (Business-Ready Data)
-- Object Type: Views (for flexibility)
-- Data Model: Star Schema (Dimensions + Facts)
-- =====================================================

USE viettel_post_dwh;
GO

-- =====================================================
-- DIMENSION: dim_customers
-- Purpose: Customer master dimension
-- =====================================================
CREATE OR ALTER VIEW gold.dim_customers AS
SELECT
    -- Surrogate key
    ROW_NUMBER() OVER (ORDER BY c.customer_id) AS customer_key,
    
    -- Natural key
    c.customer_id,
    
    -- Customer attributes
    c.customer_name,
    c.customer_type,
    c.customer_segment,
    c.registration_date,
    c.email,
    c.phone,
    c.province,
    c.is_active,
    
    -- Derived attributes
    c.customer_tenure_days,
    CASE 
        WHEN c.customer_tenure_days < 90 THEN 'New Customer'
        WHEN c.customer_tenure_days < 365 THEN 'Growing Customer'
        ELSE 'Loyal Customer'
    END AS customer_lifecycle_stage,
    
    -- Metadata
    c.dwh_create_date,
    c.dwh_update_date
FROM silver.viettel_customers c
WHERE c.customer_id IS NOT NULL;
GO

-- =====================================================
-- DIMENSION: dim_locations
-- Purpose: Location/facility dimension
-- =====================================================
CREATE OR ALTER VIEW gold.dim_locations AS
SELECT
    -- Surrogate key
    ROW_NUMBER() OVER (ORDER BY l.location_id) AS location_key,
    
    -- Natural key
    l.location_id,
    
    -- Location attributes
    l.location_name,
    l.location_type,
    l.province,
    l.district,
    l.address,
    l.latitude,
    l.longitude,
    l.capacity_sqm,
    l.has_sorting_system,
    l.is_active,
    
    -- Derived attributes
    CASE 
        WHEN l.capacity_sqm < 1000 THEN 'Small'
        WHEN l.capacity_sqm < 5000 THEN 'Medium'
        WHEN l.capacity_sqm < 10000 THEN 'Large'
        ELSE 'Extra Large'
    END AS facility_size_category,
    
    -- Metadata
    l.dwh_create_date,
    l.dwh_update_date
FROM silver.viettel_locations l
WHERE l.location_id IS NOT NULL;
GO

-- =====================================================
-- DIMENSION: dim_routes
-- Purpose: Delivery route dimension
-- =====================================================
CREATE OR ALTER VIEW gold.dim_routes AS
SELECT
    -- Surrogate key
    ROW_NUMBER() OVER (ORDER BY r.route_id) AS route_key,
    
    -- Natural key
    r.route_id,
    
    -- Route attributes
    r.route_name,
    r.origin_province,
    r.destination_province,
    r.distance_km,
    r.estimated_duration_hours,
    r.route_type,
    r.transport_mode,
    r.is_express_route,
    
    -- Derived attributes
    r.avg_speed_kmh,
    CASE 
        WHEN r.distance_km < 100 THEN 'Short Distance'
        WHEN r.distance_km < 500 THEN 'Medium Distance'
        WHEN r.distance_km < 1000 THEN 'Long Distance'
        ELSE 'Extra Long Distance'
    END AS distance_category,
    CASE 
        WHEN r.transport_mode = 'Air' THEN 'Express'
        WHEN r.transport_mode = 'Truck' THEN 'Standard'
        WHEN r.transport_mode = 'Motorbike' THEN 'Economy'
        ELSE 'Other'
    END AS service_tier,
    
    -- Metadata
    r.dwh_create_date,
    r.dwh_update_date
FROM silver.viettel_routes r
WHERE r.route_id IS NOT NULL;
GO

-- =====================================================
-- DIMENSION: dim_date
-- Purpose: Date dimension for time intelligence
-- =====================================================
CREATE OR ALTER VIEW gold.dim_date AS
WITH date_spine AS (
    SELECT DISTINCT pickup_date AS date_value
    FROM silver.viettel_shipments
    WHERE pickup_date IS NOT NULL
    
    UNION
    
    SELECT DISTINCT delivery_date AS date_value
    FROM silver.viettel_shipments
    WHERE delivery_date IS NOT NULL
)
SELECT
    -- Surrogate key
    ROW_NUMBER() OVER (ORDER BY date_value) AS date_key,
    
    -- Natural key
    date_value AS full_date,
    
    -- Date components
    YEAR(date_value) AS year,
    MONTH(date_value) AS month,
    DAY(date_value) AS day,
    DATEPART(QUARTER, date_value) AS quarter,
    DATEPART(WEEK, date_value) AS week_of_year,
    DATEPART(WEEKDAY, date_value) AS day_of_week,
    
    -- Date labels
    FORMAT(date_value, 'MMMM') AS month_name,
    FORMAT(date_value, 'MMM') AS month_short_name,
    FORMAT(date_value, 'dddd') AS day_name,
    FORMAT(date_value, 'ddd') AS day_short_name,
    FORMAT(date_value, 'yyyy-MM') AS year_month,
    FORMAT(date_value, 'yyyy-Q') + CAST(DATEPART(QUARTER, date_value) AS NVARCHAR) AS year_quarter,
    
    -- Flags
    CASE WHEN DATEPART(WEEKDAY, date_value) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend,
    CASE WHEN DATEPART(WEEKDAY, date_value) BETWEEN 2 AND 6 THEN 1 ELSE 0 END AS is_weekday
FROM date_spine;
GO

-- =====================================================
-- DIMENSION: dim_service_types
-- Purpose: Service type dimension
-- =====================================================
CREATE OR ALTER VIEW gold.dim_service_types AS
SELECT
    ROW_NUMBER() OVER (ORDER BY service_type) AS service_type_key,
    service_type AS service_type_code,
    CASE service_type
        WHEN 'VHT' THEN 'Viettel Post Hỏa Tốc (Express 24h)'
        WHEN 'VCN' THEN 'Viettel Post Chuyển Nhanh (Fast Delivery)'
        WHEN 'VTK' THEN 'Viettel Post Tiết Kiệm (Economy)'
        ELSE 'Unknown Service'
    END AS service_type_name,
    CASE service_type
        WHEN 'VHT' THEN 'Premium'
        WHEN 'VCN' THEN 'Standard'
        WHEN 'VTK' THEN 'Economy'
        ELSE 'Other'
    END AS service_tier
FROM (SELECT DISTINCT service_type FROM silver.viettel_shipments) AS src;
GO

-- =====================================================
-- FACT TABLE: fact_shipments
-- Purpose: Shipment transaction fact table
-- Grain: One row per shipment
-- =====================================================
CREATE OR ALTER VIEW gold.fact_shipments AS
SELECT
    -- Transaction identifier
    s.shipment_id,
    
    -- Foreign keys (surrogate keys from dimensions)
    c.customer_key,
    r.route_key,
    pd.date_key AS pickup_date_key,
    dd.date_key AS delivery_date_key,
    st.service_type_key,
    
    -- Degenerate dimensions (attributes without separate dimension table)
    s.origin_province,
    s.destination_province,
    s.package_type,
    s.current_status,
    
    -- Date/Time attributes
    s.pickup_datetime,
    s.delivery_datetime,
    s.pickup_date,
    s.delivery_date,
    s.pickup_year,
    s.pickup_month,
    s.pickup_quarter,
    
    -- Measures - Package characteristics
    s.weight_kg,
    s.volume_cbm,
    s.declared_value,
    
    -- Measures - Revenue components
    s.shipping_fee,
    s.insurance_fee,
    s.cod_amount,
    s.cod_fee,
    s.total_revenue,
    
    -- Measures - Performance metrics
    s.actual_delivery_hours,
    s.promised_delivery_hours,
    s.delivery_delay_hours,
    
    -- Calculated measures
    s.total_revenue - ISNULL(s.cod_amount, 0) AS net_revenue,
    CASE 
        WHEN s.promised_delivery_hours > 0 
        THEN (s.actual_delivery_hours / s.promised_delivery_hours) * 100 
        ELSE NULL 
    END AS delivery_time_performance_pct,
    
    -- Flags
    s.is_delivered,
    s.is_on_time,
    s.is_cod,
    s.is_damaged,
    s.is_returned,
    
    -- Quality metrics
    s.customer_rating,
    CASE 
        WHEN s.is_on_time = 1 AND s.is_damaged = 0 AND s.is_returned = 0 THEN 1 
        ELSE 0 
    END AS is_perfect_delivery,
    
    -- Metadata
    s.dwh_create_date,
    s.dwh_update_date
    
FROM silver.viettel_shipments s

-- Join to dimension views for surrogate keys
LEFT JOIN gold.dim_customers c
    ON s.customer_id = c.customer_id
    
LEFT JOIN gold.dim_routes r
    ON s.route_id = r.route_id
    
LEFT JOIN gold.dim_date pd
    ON s.pickup_date = pd.full_date
    
LEFT JOIN gold.dim_date dd
    ON s.delivery_date = dd.full_date
    
LEFT JOIN gold.dim_service_types st
    ON s.service_type = st.service_type_code

WHERE s.shipment_id IS NOT NULL;
GO

PRINT '==============================================';
PRINT 'Gold Layer Views Created Successfully';
PRINT '==============================================';
PRINT 'Dimensions Created:';
PRINT '  - gold.dim_customers';
PRINT '  - gold.dim_locations';
PRINT '  - gold.dim_routes';
PRINT '  - gold.dim_date';
PRINT '  - gold.dim_service_types';
PRINT '';
PRINT 'Fact Tables Created:';
PRINT '  - gold.fact_shipments';
PRINT '==============================================';
GO
