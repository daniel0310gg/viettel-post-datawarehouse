-- =====================================================
-- Viettel Post Data Warehouse - BRONZE Layer DDL
-- =====================================================
-- Purpose: Create raw data tables (exact copy from source)
-- Layer: Bronze (Raw Data)
-- Load Method: Full Load (Truncate & Insert)
-- Transformations: None
-- =====================================================

USE viettel_post_dwh;
GO

-- =====================================================
-- Table: bronze.viettel_customers
-- Purpose: Raw customer data from source system
-- =====================================================
CREATE TABLE bronze.viettel_customers (
    customer_id NVARCHAR(50),
    customer_name NVARCHAR(255),
    customer_type NVARCHAR(50),
    registration_date DATE,
    email NVARCHAR(255),
    phone NVARCHAR(50),
    province NVARCHAR(100),
    is_active NVARCHAR(10),
    customer_segment NVARCHAR(50)
);
GO

-- =====================================================
-- Table: bronze.viettel_locations
-- Purpose: Raw location/address data (warehouses, hubs, stations)
-- =====================================================
CREATE TABLE bronze.viettel_locations (
    location_id NVARCHAR(50),
    location_name NVARCHAR(255),
    location_type NVARCHAR(50),
    province NVARCHAR(100),
    district NVARCHAR(100),
    address NVARCHAR(1000),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    capacity_sqm INT,
    has_sorting_system NVARCHAR(10),
    is_active NVARCHAR(10)
);
GO

-- =====================================================
-- Table: bronze.viettel_routes
-- Purpose: Raw delivery route data
-- =====================================================
CREATE TABLE bronze.viettel_routes (
    route_id NVARCHAR(50),
    route_name NVARCHAR(255),
    origin_province NVARCHAR(100),
    destination_province NVARCHAR(100),
    distance_km DECIMAL(10,2),
    estimated_duration_hours DECIMAL(6,2),
    route_type NVARCHAR(50),
    transport_mode NVARCHAR(50),
    is_express_route NVARCHAR(10)
);
GO

-- =====================================================
-- Table: bronze.viettel_shipments
-- Purpose: Raw shipment transaction data
-- =====================================================
CREATE TABLE bronze.viettel_shipments (
    shipment_id NVARCHAR(50),
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
    is_delivered NVARCHAR(10),
    is_on_time NVARCHAR(10),
    is_cod NVARCHAR(10),
    is_damaged NVARCHAR(10),
    is_returned NVARCHAR(10),
    customer_rating DECIMAL(3,1),
    current_status NVARCHAR(50)
);
GO

PRINT '==============================================';
PRINT 'Bronze Layer Tables Created Successfully';
PRINT '==============================================';
PRINT 'Tables Created:';
PRINT '  - bronze.viettel_customers';
PRINT '  - bronze.viettel_locations';
PRINT '  - bronze.viettel_routes';
PRINT '  - bronze.viettel_shipments';
PRINT '==============================================';
GO
