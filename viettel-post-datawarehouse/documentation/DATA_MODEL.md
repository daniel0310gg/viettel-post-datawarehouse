# Viettel Post Data Warehouse - Data Model

## Overview
This data warehouse follows the **Medallion Architecture** with three layers:
- **Bronze Layer**: Raw data (exact copy from source)
- **Silver Layer**: Cleansed and standardized data
- **Gold Layer**: Business-ready data (Star Schema)

## Architecture Pattern
**Star Schema** - Optimized for analytical queries and BI tools

---

## Gold Layer - Star Schema

### Fact Table

#### fact_shipments
**Purpose**: Central fact table containing shipment transactions

**Grain**: One row per shipment

| Column | Type | Description |
|--------|------|-------------|
| shipment_id | NVARCHAR(50) | Primary key - Shipment identifier |
| customer_key | INT | FK to dim_customers |
| route_key | INT | FK to dim_routes |
| pickup_date_key | INT | FK to dim_date |
| delivery_date_key | INT | FK to dim_date |
| service_type_key | INT | FK to dim_service_types |
| **Measures** | | |
| weight_kg | DECIMAL(10,2) | Package weight |
| volume_cbm | DECIMAL(10,4) | Package volume |
| shipping_fee | DECIMAL(18,2) | Shipping revenue |
| insurance_fee | DECIMAL(18,2) | Insurance revenue |
| cod_amount | DECIMAL(18,2) | COD collection value |
| cod_fee | DECIMAL(18,2) | COD service fee |
| total_revenue | DECIMAL(18,2) | Total revenue from shipment |
| actual_delivery_hours | DECIMAL(10,2) | Actual time to deliver |
| promised_delivery_hours | DECIMAL(10,2) | Promised delivery time |
| delivery_delay_hours | DECIMAL(10,2) | Delay in hours |
| customer_rating | DECIMAL(3,1) | Customer satisfaction rating (1-5) |
| **Flags** | | |
| is_delivered | BIT | Delivery completed? |
| is_on_time | BIT | Delivered on time? |
| is_cod | BIT | Cash on delivery? |
| is_damaged | BIT | Package damaged? |
| is_returned | BIT | Package returned? |
| is_perfect_delivery | BIT | Perfect delivery (on-time, no damage, no return) |

---

### Dimension Tables

#### dim_customers
**Purpose**: Customer master data

**Type**: Type 1 SCD (Slowly Changing Dimension)

| Column | Type | Description |
|--------|------|-------------|
| customer_key | INT | Surrogate key |
| customer_id | NVARCHAR(50) | Natural key from source |
| customer_name | NVARCHAR(255) | Customer full name |
| customer_type | NVARCHAR(50) | Individual, Business, E-commerce |
| customer_segment | NVARCHAR(50) | Regular, VIP, New, At Risk |
| province | NVARCHAR(100) | Customer province |
| registration_date | DATE | When customer registered |
| customer_tenure_days | INT | Days since registration |
| customer_lifecycle_stage | NVARCHAR(50) | New/Growing/Loyal Customer |
| email | NVARCHAR(255) | Contact email |
| phone | NVARCHAR(50) | Contact phone |
| is_active | BIT | Active customer? |

**Business Rules**:
- Customers are uniquely identified by customer_id
- Customer type standardized to: Individual, Business, E-commerce
- Customer segment: Regular, VIP, New, At Risk
- Lifecycle stage derived from tenure:
  - New Customer: < 90 days
  - Growing Customer: 90-365 days
  - Loyal Customer: > 365 days

---

#### dim_locations
**Purpose**: Viettel Post facilities (offices, hubs, distribution centers)

| Column | Type | Description |
|--------|------|-------------|
| location_key | INT | Surrogate key |
| location_id | NVARCHAR(50) | Natural key from source |
| location_name | NVARCHAR(255) | Facility name |
| location_type | NVARCHAR(50) | Post Office, Distribution Center, Hub, Agent |
| province | NVARCHAR(100) | Province location |
| district | NVARCHAR(100) | District location |
| address | NVARCHAR(1000) | Full address |
| latitude | DECIMAL(10,8) | GPS latitude |
| longitude | DECIMAL(11,8) | GPS longitude |
| capacity_sqm | INT | Facility capacity in square meters |
| facility_size_category | NVARCHAR(50) | Small/Medium/Large/Extra Large |
| has_sorting_system | BIT | Automated sorting system? |
| is_active | BIT | Facility active? |

**Business Rules**:
- Facility size categories:
  - Small: < 1,000 sqm
  - Medium: 1,000 - 4,999 sqm
  - Large: 5,000 - 9,999 sqm
  - Extra Large: ≥ 10,000 sqm

---

#### dim_routes
**Purpose**: Delivery routes between provinces

| Column | Type | Description |
|--------|------|-------------|
| route_key | INT | Surrogate key |
| route_id | NVARCHAR(50) | Natural key from source |
| route_name | NVARCHAR(255) | Route name |
| origin_province | NVARCHAR(100) | Starting province |
| destination_province | NVARCHAR(100) | Ending province |
| distance_km | DECIMAL(10,2) | Route distance |
| estimated_duration_hours | DECIMAL(6,2) | Estimated travel time |
| route_type | NVARCHAR(50) | Inter-city, Intra-city |
| transport_mode | NVARCHAR(50) | Air, Truck, Motorbike |
| is_express_route | BIT | Express service route? |
| avg_speed_kmh | DECIMAL(10,2) | Average speed (calculated) |
| distance_category | NVARCHAR(50) | Short/Medium/Long/Extra Long |
| service_tier | NVARCHAR(50) | Express/Standard/Economy |

**Business Rules**:
- Distance categories:
  - Short Distance: < 100 km
  - Medium Distance: 100-499 km
  - Long Distance: 500-999 km
  - Extra Long Distance: ≥ 1,000 km
- Service tier mapping:
  - Air → Express
  - Truck → Standard
  - Motorbike → Economy

---

#### dim_date
**Purpose**: Date dimension for time intelligence

| Column | Type | Description |
|--------|------|-------------|
| date_key | INT | Surrogate key |
| full_date | DATE | Actual date |
| year | INT | Year (2024, 2025) |
| month | INT | Month (1-12) |
| day | INT | Day (1-31) |
| quarter | INT | Quarter (1-4) |
| week_of_year | INT | Week number |
| day_of_week | INT | Day of week (1=Sunday) |
| month_name | NVARCHAR(20) | January, February, ... |
| month_short_name | NVARCHAR(10) | Jan, Feb, ... |
| day_name | NVARCHAR(20) | Monday, Tuesday, ... |
| day_short_name | NVARCHAR(10) | Mon, Tue, ... |
| year_month | NVARCHAR(10) | 2024-01, 2024-02 |
| year_quarter | NVARCHAR(10) | 2024-Q1, 2024-Q2 |
| is_weekend | BIT | Saturday or Sunday? |
| is_weekday | BIT | Monday-Friday? |

---

#### dim_service_types
**Purpose**: Viettel Post service types

| Column | Type | Description |
|--------|------|-------------|
| service_type_key | INT | Surrogate key |
| service_type_code | NVARCHAR(10) | VHT, VCN, VTK |
| service_type_name | NVARCHAR(100) | Full service name |
| service_tier | NVARCHAR(50) | Premium, Standard, Economy |

**Service Types**:
- **VHT** - Viettel Post Hỏa Tốc (Express 24h) - Premium
- **VCN** - Viettel Post Chuyển Nhanh (Fast Delivery) - Standard
- **VTK** - Viettel Post Tiết Kiệm (Economy) - Economy

---

## Data Model Diagram (Star Schema)

```
                    ┌─────────────────┐
                    │  dim_customers  │
                    ├─────────────────┤
                    │ customer_key PK │
                    │ customer_id     │
                    │ customer_name   │
                    │ customer_type   │
                    │ customer_segment│
                    │ province        │
                    │ ...             │
                    └────────┬────────┘
                             │
                             │ 1:M
                             │
    ┌────────────────┐       ▼       ┌─────────────────┐
    │   dim_routes   │   ┌───────────────────┐    │  dim_date       │
    ├────────────────┤   │ fact_shipments    │◄───┤  (pickup)       │
    │ route_key PK   │   ├───────────────────┤    ├─────────────────┤
    │ route_id       │◄──│ shipment_id   PK  │    │ date_key PK     │
    │ route_name     │   │ customer_key  FK  │    │ full_date       │
    │ origin_province│   │ route_key     FK  │    │ year            │
    │ destination... │   │ pickup_date_key FK│    │ month           │
    │ distance_km    │   │ delivery_date_key │    │ quarter         │
    │ transport_mode │   │ service_type_key  │    │ ...             │
    │ ...            │   │ -----------       │    └─────────────────┘
    └────────────────┘   │ weight_kg         │
                         │ shipping_fee      │    ┌─────────────────┐
 ┌───────────────────┐   │ total_revenue     │    │  dim_date       │
 │ dim_service_types │   │ actual_del_hours  │◄───┤  (delivery)     │
 ├───────────────────┤   │ customer_rating   │    ├─────────────────┤
 │ service_type_key  │   │ is_on_time        │    │ date_key PK     │
 │ service_type_code │   │ is_damaged        │    │ full_date       │
 │ service_type_name │   │ ...               │    │ ...             │
 │ service_tier      │   └───────────────────┘    └─────────────────┘
 └──────────┬────────┘
            │
            │ 1:M
            │
            └──────────────────────┘

Legend:
PK = Primary Key
FK = Foreign Key
1:M = One-to-Many Relationship
```

---

## Analytics Views

The Gold layer includes pre-built analytics views for common business questions:

### report_daily_shipment_summary
Daily aggregated metrics including:
- Total shipments, revenue, weight
- On-time delivery rate
- Average customer rating
- Damage and return rates

### report_customer_performance
Customer-level analytics:
- Total shipments and revenue per customer
- Average order value
- Customer lifetime value
- Service preferences (COD usage)
- Quality metrics (on-time rate, rating)

### report_route_performance
Route efficiency analysis:
- Shipment volume per route
- Revenue per route
- Average delivery time vs. estimated
- On-time delivery rate by route

### report_service_type_performance
Service type comparison:
- Volume and revenue by service
- Average delivery time
- On-time delivery rate
- Customer satisfaction by service

### report_provincial_analysis
Geographic analysis:
- Inbound vs outbound shipments
- Revenue by province
- Active customers per province
- Performance metrics by region

---

## Data Flow

```
CSV Files                Bronze Layer           Silver Layer              Gold Layer
(Source Data)            (Raw Data)          (Cleansed Data)        (Business-Ready)

viettel_customers.csv ──► bronze.viettel_    ──► silver.viettel_    ──► dim_customers
                          customers               customers

viettel_locations.csv ──► bronze.viettel_    ──► silver.viettel_    ──► dim_locations
                          locations               locations

viettel_routes.csv    ──► bronze.viettel_    ──► silver.viettel_    ──► dim_routes
                          routes                  routes

viettel_shipments.csv ──► bronze.viettel_    ──► silver.viettel_    ──► fact_shipments
                          shipments               shipments               dim_date
                                                                          dim_service_types
                                                                          
                                                                      ──► Analytics Views
                                                                          (reports)
```

---

## Key Metrics & KPIs

### Operational KPIs
- **On-Time Delivery Rate**: % of shipments delivered within promised time
- **Perfect Delivery Rate**: % of shipments with no delays, damage, or returns
- **Damage Rate**: % of damaged shipments
- **Return Rate**: % of returned shipments
- **Average Delivery Time**: Hours from pickup to delivery
- **Average Delay**: Hours beyond promised delivery time

### Financial KPIs
- **Total Revenue**: Sum of all shipping fees
- **Average Revenue Per Shipment**: Total revenue / shipment count
- **COD Collection Value**: Total COD amounts collected
- **Net Revenue**: Total revenue - COD amounts

### Customer KPIs
- **Customer Lifetime Value (CLV)**: Total revenue per customer
- **Average Customer Rating**: Mean satisfaction rating (1-5 scale)
- **Active Customers**: Customers with shipments in period
- **Customer Retention**: Repeat customer rate

### Operational Efficiency
- **Capacity Utilization**: % of facility capacity used
- **Route Utilization**: Shipments per route
- **Average Package Weight**: Mean weight per shipment
- **COD Usage Rate**: % of shipments using COD service

---

## Data Refresh Strategy

### Current Implementation
- **Bronze Layer**: Full load (TRUNCATE & INSERT)
- **Silver Layer**: Full load (TRUNCATE & INSERT)
- **Gold Layer**: Views (no load needed, auto-refresh)

### Recommended Schedule
- **Daily**: Full refresh during off-peak hours (e.g., 2:00 AM)
- **Execute**: `EXEC load_data_warehouse;`
- **Duration**: Approximately 1-5 minutes (depending on volume)

### Future Enhancements
- Implement incremental loading for Bronze layer
- Add CDC (Change Data Capture) for real-time updates
- Implement SCD Type 2 for customer and location dimensions
- Add data quality checks and alerting

---

## Data Quality Rules

### Customers
- customer_id must be unique and not null
- Email must be in valid format
- Customer type must be: Individual, Business, or E-commerce
- Province must exist in standard province list

### Shipments
- shipment_id must be unique and not null
- Customer_id must reference valid customer
- Route_id must reference valid route
- Pickup date must be before or equal to delivery date
- Revenue amounts must be non-negative
- Rating must be between 1 and 5 (if provided)

### Locations
- location_id must be unique and not null
- Capacity must be positive number
- Latitude must be between -90 and 90
- Longitude must be between -180 and 180

### Routes
- route_id must be unique and not null
- Distance must be positive number
- Estimated duration must be positive number
- Origin and destination provinces must be different

---

*Last Updated: 2025-11-09*
*Data Warehouse Version: 1.0*
