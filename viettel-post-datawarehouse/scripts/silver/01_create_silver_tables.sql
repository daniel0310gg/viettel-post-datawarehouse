-- =====================================================
-- Viettel Post Data Warehouse - SILVER Layer DDL
-- =====================================================
-- Purpose: Create cleansed and standardized tables
-- Layer: Silver (Cleansed Data)
-- Load Method: Full Load (Truncate & Insert)
-- Transformations: Cleansing, Standardization, Enrichment
-- =====================================================

USE viettel_post_dwh;
GO

-- =====================================================
-- Table: silver.viettel_customers
-- Purpose: Cleansed customer data
-- =====================================================
CREATE TABLE silver.viettel_customers (
    customer_id NVARCHAR(50) NOT NULL,
    customer_name NVARCHAR(255),
    customer_type NVARCHAR(50),
    registration_date DATE,
    email NVARCHAR(255),
    phone NVARCHAR(50),
    province NVARCHAR(100),
    is_active BIT,
    customer_segment NVARCHAR(50),
    -- Derived columns
    customer_tenure_days AS DATEDIFF(DAY, registration_date, GETDATE()),
    -- Technical columns
    dwh_create_date DATETIME DEFAULT GETDATE(),
    dwh_update_date DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_silver_customers PRIMARY KEY (customer_id)
);
GO

CREATE NONCLUSTERED INDEX IX_silver_customers_province ON silver.viettel_customers(province);
CREATE NONCLUSTERED INDEX IX_silver_customers_segment ON silver.viettel_customers(customer_segment);
CREATE NONCLUSTERED INDEX IX_silver_customers_type ON silver.viettel_customers(customer_type);
GO

-- =====================================================
-- Table: silver.viettel_locations
-- Purpose: Cleansed location data
-- =====================================================
CREATE TABLE silver.viettel_locations (
    location_id NVARCHAR(50) NOT NULL,
    location_name NVARCHAR(255),
    location_type NVARCHAR(50),
    province NVARCHAR(100),
    district NVARCHAR(100),
    address NVARCHAR(1000),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    capacity_sqm INT,
    has_sorting_system BIT,
    is_active BIT,
    -- Technical columns
    dwh_create_date DATETIME DEFAULT GETDATE(),
    dwh_update_date DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_silver_locations PRIMARY KEY (location_id)
);
GO

CREATE NONCLUSTERED INDEX IX_silver_locations_province ON silver.viettel_locations(province);
CREATE NONCLUSTERED INDEX IX_silver_locations_type ON silver.viettel_locations(location_type);
GO

-- =====================================================
-- Table: silver.viettel_routes
-- Purpose: Cleansed route data
-- =====================================================
CREATE TABLE silver.viettel_routes (
    route_id NVARCHAR(50) NOT NULL,
    route_name NVARCHAR(255),
    origin_province NVARCHAR(100),
    destination_province NVARCHAR(100),
    distance_km DECIMAL(10,2),
    estimated_duration_hours DECIMAL(6,2),
    route_type NVARCHAR(50),
    transport_mode NVARCHAR(50),
    is_express_route BIT,
    -- Derived columns
    avg_speed_kmh AS CASE 
        WHEN estimated_duration_hours > 0 
        THEN distance_km / estimated_duration_hours 
        ELSE NULL 
    END,
    -- Technical columns
    dwh_create_date DATETIME DEFAULT GETDATE(),
    dwh_update_date DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_silver_routes PRIMARY KEY (route_id)
);
GO

CREATE NONCLUSTERED INDEX IX_silver_routes_origin ON silver.viettel_routes(origin_province);
CREATE NONCLUSTERED INDEX IX_silver_routes_destination ON silver.viettel_routes(destination_province);
CREATE NONCLUSTERED INDEX IX_silver_routes_transport_mode ON silver.viettel_routes(transport_mode);
GO

-- =====================================================
-- Table: silver.viettel_shipments
-- Purpose: Cleansed shipment transaction data
-- =====================================================
CREATE TABLE silver.viettel_shipments (
    shipment_id NVARCHAR(50) NOT NULL,
    customer_id NVARCHAR(50),
    pickup_datetime DATETIME,
    delivery_datetime DATETIME,
    origin_province NVARCHAR(100),
    destination_province NVARCHAR(100),
    route_id NVARCHAR(50),
    service_type NVARCHAR(50),
    package_type NVARCHAR(50),
    weight_kg DECIMAL(10,2),
    volume_cbm DECIMAL(10,4),
    declared_value DECIMAL(18,2),
    shipping_fee DECIMAL(18,2),
    insurance_fee DECIMAL(18,2),
    cod_amount DECIMAL(18,2),
    cod_fee DECIMAL(18,2),
    total_revenue DECIMAL(18,2),
    actual_delivery_hours DECIMAL(10,2),
    promised_delivery_hours DECIMAL(10,2),
    is_delivered BIT,
    is_on_time BIT,
    is_cod BIT,
    is_damaged BIT,
    is_returned BIT,
    customer_rating DECIMAL(3,1),
    current_status NVARCHAR(50),
    -- Derived columns
    pickup_date AS CAST(pickup_datetime AS DATE),
    delivery_date AS CAST(delivery_datetime AS DATE),
    pickup_year AS YEAR(pickup_datetime),
    pickup_month AS MONTH(pickup_datetime),
    pickup_quarter AS DATEPART(QUARTER, pickup_datetime),
    delivery_delay_hours AS CASE 
        WHEN actual_delivery_hours > promised_delivery_hours 
        THEN actual_delivery_hours - promised_delivery_hours 
        ELSE 0 
    END,
    -- Technical columns
    dwh_create_date DATETIME DEFAULT GETDATE(),
    dwh_update_date DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_silver_shipments PRIMARY KEY (shipment_id)
);
GO

CREATE NONCLUSTERED INDEX IX_silver_shipments_customer ON silver.viettel_shipments(customer_id);
CREATE NONCLUSTERED INDEX IX_silver_shipments_route ON silver.viettel_shipments(route_id);
CREATE NONCLUSTERED INDEX IX_silver_shipments_pickup_date ON silver.viettel_shipments(pickup_date);
CREATE NONCLUSTERED INDEX IX_silver_shipments_status ON silver.viettel_shipments(current_status);
CREATE NONCLUSTERED INDEX IX_silver_shipments_service_type ON silver.viettel_shipments(service_type);
GO

PRINT '==============================================';
PRINT 'Silver Layer Tables Created Successfully';
PRINT '==============================================';
PRINT 'Tables Created:';
PRINT '  - silver.viettel_customers';
PRINT '  - silver.viettel_locations';
PRINT '  - silver.viettel_routes';
PRINT '  - silver.viettel_shipments';
PRINT '==============================================';
GO
