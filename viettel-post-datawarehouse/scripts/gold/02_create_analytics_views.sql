-- =====================================================
-- Viettel Post Data Warehouse - GOLD Layer Analytics
-- =====================================================
-- Purpose: Create aggregated views for common analytics
-- =====================================================

USE viettel_post_dwh;
GO

-- =====================================================
-- VIEW: report_daily_shipment_summary
-- Purpose: Daily shipment performance metrics
-- =====================================================
CREATE OR ALTER VIEW gold.report_daily_shipment_summary AS
SELECT
    -- Date dimensions
    f.pickup_date,
    d.year,
    d.month,
    d.month_name,
    d.quarter,
    d.day_name,
    d.is_weekend,
    
    -- Volume metrics
    COUNT(DISTINCT f.shipment_id) AS total_shipments,
    COUNT(DISTINCT f.customer_key) AS unique_customers,
    
    -- Weight and volume metrics
    SUM(f.weight_kg) AS total_weight_kg,
    AVG(f.weight_kg) AS avg_weight_kg,
    SUM(f.volume_cbm) AS total_volume_cbm,
    
    -- Revenue metrics
    SUM(f.total_revenue) AS total_revenue,
    AVG(f.total_revenue) AS avg_revenue_per_shipment,
    SUM(f.shipping_fee) AS total_shipping_fee,
    SUM(f.cod_amount) AS total_cod_amount,
    SUM(f.cod_fee) AS total_cod_fee,
    SUM(f.insurance_fee) AS total_insurance_fee,
    
    -- Performance metrics
    AVG(f.actual_delivery_hours) AS avg_delivery_hours,
    AVG(f.delivery_delay_hours) AS avg_delay_hours,
    AVG(CAST(f.customer_rating AS FLOAT)) AS avg_customer_rating,
    
    -- Quality metrics
    SUM(CAST(f.is_on_time AS INT)) AS on_time_shipments,
    SUM(CAST(f.is_damaged AS INT)) AS damaged_shipments,
    SUM(CAST(f.is_returned AS INT)) AS returned_shipments,
    SUM(CAST(f.is_perfect_delivery AS INT)) AS perfect_deliveries,
    
    -- Calculated KPIs
    CAST(SUM(CAST(f.is_on_time AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS on_time_delivery_rate,
    CAST(SUM(CAST(f.is_damaged AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS damage_rate,
    CAST(SUM(CAST(f.is_returned AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS return_rate
    
FROM gold.fact_shipments f
LEFT JOIN gold.dim_date d ON f.pickup_date_key = d.date_key
GROUP BY 
    f.pickup_date,
    d.year,
    d.month,
    d.month_name,
    d.quarter,
    d.day_name,
    d.is_weekend;
GO

-- =====================================================
-- VIEW: report_customer_performance
-- Purpose: Customer-level performance and revenue metrics
-- =====================================================
CREATE OR ALTER VIEW gold.report_customer_performance AS
SELECT
    -- Customer attributes
    c.customer_key,
    c.customer_id,
    c.customer_name,
    c.customer_type,
    c.customer_segment,
    c.province,
    c.is_active,
    c.customer_lifecycle_stage,
    
    -- Shipment metrics
    COUNT(DISTINCT f.shipment_id) AS total_shipments,
    MIN(f.pickup_date) AS first_shipment_date,
    MAX(f.pickup_date) AS last_shipment_date,
    DATEDIFF(DAY, MIN(f.pickup_date), MAX(f.pickup_date)) AS customer_activity_days,
    
    -- Revenue metrics
    SUM(f.total_revenue) AS total_revenue,
    AVG(f.total_revenue) AS avg_revenue_per_shipment,
    SUM(f.shipping_fee) AS total_shipping_fee,
    SUM(f.cod_amount) AS total_cod_value,
    
    -- Service preferences
    COUNT(CASE WHEN f.is_cod = 1 THEN 1 END) AS cod_shipments,
    CAST(COUNT(CASE WHEN f.is_cod = 1 THEN 1 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS cod_usage_rate,
    
    -- Quality metrics
    AVG(CAST(f.customer_rating AS FLOAT)) AS avg_rating,
    SUM(CAST(f.is_on_time AS INT)) AS on_time_deliveries,
    CAST(SUM(CAST(f.is_on_time AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS on_time_rate,
    
    -- Package characteristics
    SUM(f.weight_kg) AS total_weight_shipped,
    AVG(f.weight_kg) AS avg_package_weight,
    
    -- Customer value segment
    CASE 
        WHEN SUM(f.total_revenue) > 100000000 THEN 'Platinum'
        WHEN SUM(f.total_revenue) > 50000000 THEN 'Gold'
        WHEN SUM(f.total_revenue) > 10000000 THEN 'Silver'
        ELSE 'Bronze'
    END AS revenue_tier
    
FROM gold.dim_customers c
LEFT JOIN gold.fact_shipments f ON c.customer_key = f.customer_key
GROUP BY 
    c.customer_key,
    c.customer_id,
    c.customer_name,
    c.customer_type,
    c.customer_segment,
    c.province,
    c.is_active,
    c.customer_lifecycle_stage;
GO

-- =====================================================
-- VIEW: report_route_performance
-- Purpose: Route-level performance metrics
-- =====================================================
CREATE OR ALTER VIEW gold.report_route_performance AS
SELECT
    -- Route attributes
    r.route_key,
    r.route_id,
    r.route_name,
    r.origin_province,
    r.destination_province,
    r.distance_km,
    r.estimated_duration_hours,
    r.transport_mode,
    r.is_express_route,
    r.distance_category,
    
    -- Volume metrics
    COUNT(DISTINCT f.shipment_id) AS total_shipments,
    SUM(f.weight_kg) AS total_weight_kg,
    SUM(f.volume_cbm) AS total_volume_cbm,
    
    -- Revenue metrics
    SUM(f.total_revenue) AS total_revenue,
    AVG(f.total_revenue) AS avg_revenue_per_shipment,
    
    -- Performance metrics
    AVG(f.actual_delivery_hours) AS avg_actual_delivery_hours,
    AVG(f.delivery_delay_hours) AS avg_delay_hours,
    SUM(CAST(f.is_on_time AS INT)) AS on_time_deliveries,
    CAST(SUM(CAST(f.is_on_time AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS on_time_rate,
    
    -- Utilization
    CASE 
        WHEN COUNT(*) > 1000 THEN 'High Utilization'
        WHEN COUNT(*) > 500 THEN 'Medium Utilization'
        ELSE 'Low Utilization'
    END AS route_utilization
    
FROM gold.dim_routes r
LEFT JOIN gold.fact_shipments f ON r.route_key = f.route_key
GROUP BY 
    r.route_key,
    r.route_id,
    r.route_name,
    r.origin_province,
    r.destination_province,
    r.distance_km,
    r.estimated_duration_hours,
    r.transport_mode,
    r.is_express_route,
    r.distance_category;
GO

-- =====================================================
-- VIEW: report_service_type_performance
-- Purpose: Service type comparison
-- =====================================================
CREATE OR ALTER VIEW gold.report_service_type_performance AS
SELECT
    -- Service attributes
    st.service_type_key,
    st.service_type_code,
    st.service_type_name,
    st.service_tier,
    
    -- Volume metrics
    COUNT(DISTINCT f.shipment_id) AS total_shipments,
    COUNT(DISTINCT f.customer_key) AS unique_customers,
    
    -- Revenue metrics
    SUM(f.total_revenue) AS total_revenue,
    AVG(f.total_revenue) AS avg_revenue_per_shipment,
    SUM(f.shipping_fee) AS total_shipping_fee,
    
    -- Performance metrics
    AVG(f.actual_delivery_hours) AS avg_delivery_hours,
    AVG(f.promised_delivery_hours) AS avg_promised_hours,
    AVG(f.delivery_delay_hours) AS avg_delay_hours,
    
    -- Quality metrics
    SUM(CAST(f.is_on_time AS INT)) AS on_time_deliveries,
    CAST(SUM(CAST(f.is_on_time AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS on_time_rate,
    AVG(CAST(f.customer_rating AS FLOAT)) AS avg_customer_rating,
    SUM(CAST(f.is_perfect_delivery AS INT)) AS perfect_deliveries,
    CAST(SUM(CAST(f.is_perfect_delivery AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS perfect_delivery_rate
    
FROM gold.dim_service_types st
LEFT JOIN gold.fact_shipments f ON st.service_type_key = f.service_type_key
GROUP BY 
    st.service_type_key,
    st.service_type_code,
    st.service_type_name,
    st.service_tier;
GO

-- =====================================================
-- VIEW: report_provincial_analysis
-- Purpose: Province-level performance metrics
-- =====================================================
CREATE OR ALTER VIEW gold.report_provincial_analysis AS
SELECT
    -- Province
    COALESCE(f.origin_province, f.destination_province) AS province,
    
    -- Outbound metrics (as origin)
    COUNT(CASE WHEN f.origin_province = COALESCE(f.origin_province, f.destination_province) THEN 1 END) AS outbound_shipments,
    SUM(CASE WHEN f.origin_province = COALESCE(f.origin_province, f.destination_province) THEN f.total_revenue ELSE 0 END) AS outbound_revenue,
    
    -- Inbound metrics (as destination)
    COUNT(CASE WHEN f.destination_province = COALESCE(f.origin_province, f.destination_province) THEN 1 END) AS inbound_shipments,
    SUM(CASE WHEN f.destination_province = COALESCE(f.origin_province, f.destination_province) THEN f.total_revenue ELSE 0 END) AS inbound_revenue,
    
    -- Total metrics
    COUNT(*) AS total_shipments,
    SUM(f.total_revenue) AS total_revenue,
    AVG(f.total_revenue) AS avg_revenue_per_shipment,
    
    -- Customer metrics
    COUNT(DISTINCT CASE WHEN f.origin_province = COALESCE(f.origin_province, f.destination_province) 
        THEN f.customer_key END) AS active_customers,
    
    -- Performance
    CAST(SUM(CAST(f.is_on_time AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS on_time_rate,
    AVG(CAST(f.customer_rating AS FLOAT)) AS avg_customer_rating
    
FROM gold.fact_shipments f
GROUP BY COALESCE(f.origin_province, f.destination_province);
GO

PRINT '==============================================';
PRINT 'Gold Layer Analytics Views Created Successfully';
PRINT '==============================================';
PRINT 'Report Views Created:';
PRINT '  - gold.report_daily_shipment_summary';
PRINT '  - gold.report_customer_performance';
PRINT '  - gold.report_route_performance';
PRINT '  - gold.report_service_type_performance';
PRINT '  - gold.report_provincial_analysis';
PRINT '==============================================';
GO
