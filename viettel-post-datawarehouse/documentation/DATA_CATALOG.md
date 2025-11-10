# Viettel Post Data Warehouse - Data Catalog

> Complete field-level documentation for all data warehouse objects

---

## 📊 Gold Layer - Business-Ready Data

### Dimension: `gold.dim_customers`

**Purpose**: Customer master dimension with demographic and behavioral attributes

**Refresh**: Via view from `silver.viettel_customers`

| Column | Data Type | Description | Example | Business Rules |
|--------|-----------|-------------|---------|----------------|
| customer_key | INT | Surrogate key (auto-generated) | 1, 2, 3 | Primary key, unique |
| customer_id | NVARCHAR(50) | Natural key from source | CUST00000001 | Business key |
| customer_name | NVARCHAR(255) | Full customer name | Lâm Dương | Can contain Vietnamese characters |
| customer_type | NVARCHAR(50) | Customer category | Individual, Business, E-commerce | Standardized values only |
| customer_segment | NVARCHAR(50) | Customer value segment | Regular, VIP, New, At Risk | Business-defined segments |
| province | NVARCHAR(100) | Customer province | HÀ NỘI, HỒ CHÍ MINH | Uppercase, standardized |
| registration_date | DATE | When customer joined | 2024-01-15 | Must be ≤ current date |
| email | NVARCHAR(255) | Contact email | customer@example.com | Lowercase, validated format |
| phone | NVARCHAR(50) | Contact phone | +84-24-236 1593 | Various formats accepted |
| is_active | BIT | Currently active? | 1 (True), 0 (False) | Determines eligibility for new shipments |
| customer_tenure_days | INT | Days since registration | 456 | Calculated: DATEDIFF(DAY, registration_date, GETDATE()) |
| customer_lifecycle_stage | NVARCHAR(50) | Lifecycle classification | New Customer, Growing, Loyal | Derived from tenure |
| dwh_create_date | DATETIME | When record created in DWH | 2025-11-09 10:30:00 | System-generated |
| dwh_update_date | DATETIME | When record last updated | 2025-11-09 10:30:00 | System-generated |

**Sample Query**:
```sql
SELECT TOP 10 
    customer_name,
    customer_segment,
    province,
    customer_tenure_days,
    customer_lifecycle_stage
FROM gold.dim_customers
WHERE is_active = 1
ORDER BY customer_tenure_days DESC;
```

---

### Dimension: `gold.dim_locations`

**Purpose**: Viettel Post facilities (offices, hubs, distribution centers, agents)

**Refresh**: Via view from `silver.viettel_locations`

| Column | Data Type | Description | Example | Business Rules |
|--------|-----------|-------------|---------|----------------|
| location_key | INT | Surrogate key | 1, 2, 3 | Primary key, unique |
| location_id | NVARCHAR(50) | Natural key | LOC00001 | Business key |
| location_name | NVARCHAR(255) | Facility name | Post Office Long An 1 | Descriptive name |
| location_type | NVARCHAR(50) | Facility category | Post Office, Distribution Center, Hub, Agent | 4 standard types |
| province | NVARCHAR(100) | Province location | LONG AN | Uppercase |
| district | NVARCHAR(100) | District location | Quận | Vietnamese administrative unit |
| address | NVARCHAR(1000) | Full street address | 1 Phạm Tổ, Thành phố | May include Vietnamese characters |
| latitude | DECIMAL(10,8) | GPS latitude | -8.300572 | Range: -90 to 90 |
| longitude | DECIMAL(11,8) | GPS longitude | -71.448611 | Range: -180 to 180 |
| capacity_sqm | INT | Facility size in square meters | 3717 | Positive integer |
| has_sorting_system | BIT | Automated sorting available? | 1, 0 | Impacts processing speed |
| is_active | BIT | Facility operational? | 1, 0 | Only active locations process shipments |
| facility_size_category | NVARCHAR(50) | Size classification | Small, Medium, Large, Extra Large | Derived from capacity_sqm |
| dwh_create_date | DATETIME | Record created | 2025-11-09 10:30:00 | System-generated |
| dwh_update_date | DATETIME | Record updated | 2025-11-09 10:30:00 | System-generated |

**Facility Size Categories**:
- Small: < 1,000 sqm
- Medium: 1,000 - 4,999 sqm
- Large: 5,000 - 9,999 sqm
- Extra Large: ≥ 10,000 sqm

**Sample Query**:
```sql
SELECT 
    location_type,
    COUNT(*) AS facility_count,
    AVG(capacity_sqm) AS avg_capacity,
    SUM(CAST(has_sorting_system AS INT)) AS automated_count
FROM gold.dim_locations
WHERE is_active = 1
GROUP BY location_type;
```

---

### Dimension: `gold.dim_routes`

**Purpose**: Delivery routes between provinces with distance and time estimates

**Refresh**: Via view from `silver.viettel_routes`

| Column | Data Type | Description | Example | Business Rules |
|--------|-----------|-------------|---------|----------------|
| route_key | INT | Surrogate key | 1, 2, 3 | Primary key |
| route_id | NVARCHAR(50) | Natural key | ROUTE00001 | Business key |
| route_name | NVARCHAR(255) | Route description | Hà Nội - Hồ Chí Minh | Origin - Destination format |
| origin_province | NVARCHAR(100) | Starting province | HÀ NỘI | Uppercase |
| destination_province | NVARCHAR(100) | Ending province | HỒ CHÍ MINH | Uppercase |
| distance_km | DECIMAL(10,2) | Route distance in kilometers | 1790.00 | Positive value |
| estimated_duration_hours | DECIMAL(6,2) | Expected travel time | 35.80 | Positive value |
| route_type | NVARCHAR(50) | Route classification | Inter-city, Intra-city | Inter-city for between cities |
| transport_mode | NVARCHAR(50) | Primary transport method | Air, Truck, Motorbike | Determines service level |
| is_express_route | BIT | Express service available? | 1, 0 | Premium pricing |
| avg_speed_kmh | DECIMAL(10,2) | Average speed | 50.00 | Calculated: distance_km / estimated_duration_hours |
| distance_category | NVARCHAR(50) | Distance classification | Short, Medium, Long, Extra Long | Derived from distance_km |
| service_tier | NVARCHAR(50) | Service level | Express, Standard, Economy | Derived from transport_mode |
| dwh_create_date | DATETIME | Record created | 2025-11-09 10:30:00 | System-generated |
| dwh_update_date | DATETIME | Record updated | 2025-11-09 10:30:00 | System-generated |

**Distance Categories**:
- Short Distance: < 100 km
- Medium Distance: 100-499 km
- Long Distance: 500-999 km
- Extra Long Distance: ≥ 1,000 km

**Service Tier Mapping**:
- Air → Express
- Truck → Standard
- Motorbike → Economy

**Sample Query**:
```sql
SELECT 
    transport_mode,
    distance_category,
    COUNT(*) AS route_count,
    AVG(distance_km) AS avg_distance,
    AVG(avg_speed_kmh) AS avg_speed
FROM gold.dim_routes
GROUP BY transport_mode, distance_category
ORDER BY transport_mode, avg_distance;
```

---

### Dimension: `gold.dim_date`

**Purpose**: Date dimension for time intelligence and reporting

**Refresh**: Via view from distinct dates in `silver.viettel_shipments`

| Column | Data Type | Description | Example | Business Rules |
|--------|-----------|-------------|---------|----------------|
| date_key | INT | Surrogate key | 1, 2, 3 | Primary key |
| full_date | DATE | Actual date | 2024-01-15 | Business key |
| year | INT | Year | 2024 | 4-digit year |
| month | INT | Month number | 1-12 | Calendar month |
| day | INT | Day of month | 1-31 | Calendar day |
| quarter | INT | Quarter | 1-4 | Calendar quarter |
| week_of_year | INT | Week number | 1-53 | ISO week |
| day_of_week | INT | Day of week | 1-7 | 1=Sunday |
| month_name | NVARCHAR(20) | Full month name | January | English |
| month_short_name | NVARCHAR(10) | Abbreviated month | Jan | 3-letter abbreviation |
| day_name | NVARCHAR(20) | Full day name | Monday | English |
| day_short_name | NVARCHAR(10) | Abbreviated day | Mon | 3-letter abbreviation |
| year_month | NVARCHAR(10) | Year-Month | 2024-01 | For grouping |
| year_quarter | NVARCHAR(10) | Year-Quarter | 2024-Q1 | For grouping |
| is_weekend | BIT | Weekend day? | 1, 0 | Saturday or Sunday |
| is_weekday | BIT | Weekday? | 1, 0 | Monday through Friday |

**Sample Query**:
```sql
SELECT 
    year,
    quarter,
    COUNT(DISTINCT full_date) AS days_count,
    SUM(CAST(is_weekday AS INT)) AS weekdays,
    SUM(CAST(is_weekend AS INT)) AS weekend_days
FROM gold.dim_date
GROUP BY year, quarter
ORDER BY year, quarter;
```

---

### Dimension: `gold.dim_service_types`

**Purpose**: Viettel Post service level offerings

**Refresh**: Via view from distinct service types in `silver.viettel_shipments`

| Column | Data Type | Description | Example | Business Rules |
|--------|-----------|-------------|---------|----------------|
| service_type_key | INT | Surrogate key | 1, 2, 3 | Primary key |
| service_type_code | NVARCHAR(10) | Service code | VHT, VCN, VTK | 3-letter code |
| service_type_name | NVARCHAR(100) | Full service name | Viettel Post Hỏa Tốc (Express 24h) | Vietnamese name with English |
| service_tier | NVARCHAR(50) | Service level | Premium, Standard, Economy | Pricing tier |

**Service Definitions**:
- **VHT**: Viettel Post Hỏa Tốc (Express 24h) - Premium tier, fastest delivery
- **VCN**: Viettel Post Chuyển Nhanh (Fast Delivery) - Standard tier, balanced speed/cost
- **VTK**: Viettel Post Tiết Kiệm (Economy) - Economy tier, cost-effective

**Sample Query**:
```sql
SELECT * FROM gold.dim_service_types ORDER BY service_type_code;
```

---

### Fact Table: `gold.fact_shipments`

**Purpose**: Shipment transactions with all measures and foreign keys

**Grain**: One row per shipment

**Refresh**: Via view from `silver.viettel_shipments` with joins to dimensions

| Column | Data Type | Description | Example | Business Rules |
|--------|-----------|-------------|---------|----------------|
| **Primary Key** |
| shipment_id | NVARCHAR(50) | Unique shipment identifier | VTP20240119000000 | Primary key |
| **Foreign Keys** |
| customer_key | INT | FK to dim_customers | 1234 | Links to customer dimension |
| route_key | INT | FK to dim_routes | 56 | Links to route dimension |
| pickup_date_key | INT | FK to dim_date | 789 | Links to date dimension |
| delivery_date_key | INT | FK to dim_date | 790 | Links to date dimension |
| service_type_key | INT | FK to dim_service_types | 2 | Links to service type dimension |
| **Degenerate Dimensions** |
| origin_province | NVARCHAR(100) | Shipment origin | HÀ NỘI | Uppercase |
| destination_province | NVARCHAR(100) | Shipment destination | HỒ CHÍ MINH | Uppercase |
| package_type | NVARCHAR(50) | Package category | Document, Parcel, Fragile, Heavy, Cold | Standard types |
| current_status | NVARCHAR(50) | Current shipment status | DELIVERED | Uppercase |
| **Date/Time Attributes** |
| pickup_datetime | DATETIME | When package picked up | 2024-01-19 07:56:00 | Must be ≤ delivery_datetime |
| delivery_datetime | DATETIME | When package delivered | 2024-01-20 04:31:44 | Actual delivery time |
| pickup_date | DATE | Pickup date only | 2024-01-19 | Derived from pickup_datetime |
| delivery_date | DATE | Delivery date only | 2024-01-20 | Derived from delivery_datetime |
| pickup_year | INT | Pickup year | 2024 | For partitioning |
| pickup_month | INT | Pickup month | 1 | For grouping |
| pickup_quarter | INT | Pickup quarter | 1 | For grouping |
| **Package Measures** |
| weight_kg | DECIMAL(10,2) | Package weight in kg | 5.96 | Positive value |
| volume_cbm | DECIMAL(10,4) | Package volume in cubic meters | 0.0243 | Positive value |
| declared_value | DECIMAL(18,2) | Declared package value (VND) | 3572920.00 | For insurance |
| **Revenue Measures** |
| shipping_fee | DECIMAL(18,2) | Base shipping charge (VND) | 4611579.00 | Primary revenue |
| insurance_fee | DECIMAL(18,2) | Insurance charge (VND) | 3573.00 | Optional add-on |
| cod_amount | DECIMAL(18,2) | Cash on delivery amount (VND) | 3572920.00 | If COD service used |
| cod_fee | DECIMAL(18,2) | COD service fee (VND) | 71458.00 | Typically 2% of COD amount |
| total_revenue | DECIMAL(18,2) | Total revenue (VND) | 4686610.00 | Sum of all fees |
| net_revenue | DECIMAL(18,2) | Revenue minus COD | 1113690.00 | Calculated: total_revenue - cod_amount |
| **Performance Measures** |
| actual_delivery_hours | DECIMAL(10,2) | Actual delivery time | 20.60 | Hours from pickup to delivery |
| promised_delivery_hours | DECIMAL(10,2) | Promised delivery time | 18.00 | SLA commitment |
| delivery_delay_hours | DECIMAL(10,2) | Delay in hours | 2.60 | Calculated: actual - promised (if positive) |
| delivery_time_performance_pct | DECIMAL(10,2) | Performance % | 114.44 | (actual/promised) * 100 |
| **Quality Measures** |
| customer_rating | DECIMAL(3,1) | Customer satisfaction rating | 4.0 | Scale: 1.0 to 5.0 |
| **Boolean Flags** |
| is_delivered | BIT | Delivery completed? | 1 | 1=delivered, 0=in transit/cancelled |
| is_on_time | BIT | Delivered on time? | 0 | 1=yes, 0=delayed |
| is_cod | BIT | Cash on delivery? | 1 | 1=COD service, 0=prepaid |
| is_damaged | BIT | Package damaged? | 0 | 1=damaged, 0=intact |
| is_returned | BIT | Package returned? | 0 | 1=returned to sender, 0=delivered |
| is_perfect_delivery | BIT | Perfect delivery? | 0 | 1=on-time AND not damaged AND not returned |
| **Metadata** |
| dwh_create_date | DATETIME | Record created | 2025-11-09 10:30:00 | System-generated |
| dwh_update_date | DATETIME | Record updated | 2025-11-09 10:30:00 | System-generated |

**Sample Queries**:

```sql
-- Revenue analysis by service type
SELECT 
    st.service_type_name,
    COUNT(*) AS shipment_count,
    SUM(f.total_revenue) AS total_revenue,
    AVG(f.total_revenue) AS avg_revenue
FROM gold.fact_shipments f
JOIN gold.dim_service_types st ON f.service_type_key = st.service_type_key
GROUP BY st.service_type_name
ORDER BY total_revenue DESC;

-- On-time delivery rate by route
SELECT 
    r.route_name,
    COUNT(*) AS shipments,
    SUM(CAST(f.is_on_time AS INT)) AS on_time_shipments,
    CAST(SUM(CAST(f.is_on_time AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS otd_rate
FROM gold.fact_shipments f
JOIN gold.dim_routes r ON f.route_key = r.route_key
GROUP BY r.route_name
HAVING COUNT(*) > 100
ORDER BY otd_rate DESC;
```

---

## 📈 Analytics Views

### View: `gold.report_daily_shipment_summary`

**Purpose**: Daily aggregated performance metrics

**Grain**: One row per pickup date

**Key Metrics**:
- Total shipments, unique customers
- Total and average revenue
- Total weight and volume
- On-time delivery rate (%)
- Damage rate (%)
- Return rate (%)
- Average customer rating
- Average delivery and delay hours

**Sample Query**:
```sql
SELECT TOP 30
    pickup_date,
    day_name,
    total_shipments,
    total_revenue,
    on_time_delivery_rate,
    avg_customer_rating
FROM gold.report_daily_shipment_summary
ORDER BY pickup_date DESC;
```

---

### View: `gold.report_customer_performance`

**Purpose**: Customer-level analytics and value segmentation

**Grain**: One row per customer

**Key Metrics**:
- Total shipments and revenue per customer
- First and last shipment dates
- Customer activity days
- Average revenue per shipment
- COD usage rate (%)
- Average rating
- On-time rate (%)
- Revenue tier (Platinum/Gold/Silver/Bronze)

**Sample Query**:
```sql
SELECT TOP 20
    customer_name,
    customer_segment,
    total_shipments,
    total_revenue,
    avg_rating,
    revenue_tier
FROM gold.report_customer_performance
WHERE is_active = 1
ORDER BY total_revenue DESC;
```

---

### View: `gold.report_route_performance`

**Purpose**: Route efficiency and utilization analysis

**Grain**: One row per route

**Key Metrics**:
- Total shipments and volume per route
- Total and average revenue
- Average actual vs estimated delivery time
- On-time rate (%)
- Route utilization (High/Medium/Low)

**Sample Query**:
```sql
SELECT 
    route_name,
    transport_mode,
    total_shipments,
    on_time_rate,
    avg_actual_delivery_hours,
    route_utilization
FROM gold.report_route_performance
WHERE route_utilization = 'High Utilization'
ORDER BY on_time_rate DESC;
```

---

### View: `gold.report_service_type_performance`

**Purpose**: Service type comparison and analysis

**Grain**: One row per service type

**Key Metrics**:
- Volume and unique customers per service
- Revenue metrics
- Average delivery time vs promised
- On-time rate (%)
- Perfect delivery rate (%)
- Average customer rating

**Sample Query**:
```sql
SELECT 
    service_type_name,
    total_shipments,
    total_revenue,
    on_time_rate,
    perfect_delivery_rate,
    avg_customer_rating
FROM gold.report_service_type_performance
ORDER BY total_shipments DESC;
```

---

### View: `gold.report_provincial_analysis`

**Purpose**: Geographic performance analysis

**Grain**: One row per province

**Key Metrics**:
- Outbound vs inbound shipment counts
- Outbound vs inbound revenue
- Total shipments and revenue
- Active customers per province
- On-time rate (%)
- Average customer rating

**Sample Query**:
```sql
SELECT TOP 10
    province,
    total_shipments,
    total_revenue,
    active_customers,
    on_time_rate
FROM gold.report_provincial_analysis
ORDER BY total_revenue DESC;
```

---

## 🔍 Data Quality & Business Rules

### General Rules

1. **Uniqueness**: All primary keys must be unique and not null
2. **Referential Integrity**: All foreign keys must reference existing dimension records
3. **Date Validation**: Pickup dates must be ≤ delivery dates
4. **Positive Values**: All amounts, weights, volumes must be ≥ 0
5. **Rating Range**: Customer ratings must be between 1.0 and 5.0

### Data Standardization

| Field Type | Standardization Rule | Example |
|------------|---------------------|---------|
| Provinces | UPPERCASE | HÀ NỘI, HỒ CHÍ MINH |
| Emails | lowercase | customer@example.com |
| Boolean flags | BIT (0/1) | 1 for True, 0 for False |
| Service codes | UPPERCASE | VHT, VCN, VTK |
| Status | UPPERCASE | DELIVERED, IN TRANSIT |

---

## 📝 Glossary

| Term | Definition |
|------|------------|
| **COD** | Cash on Delivery - payment collected at delivery time |
| **VHT** | Viettel Post Hỏa Tốc - Express 24-hour service |
| **VCN** | Viettel Post Chuyển Nhanh - Fast delivery service |
| **VTK** | Viettel Post Tiết Kiệm - Economy service |
| **OTD** | On-Time Delivery - delivery within promised hours |
| **Perfect Delivery** | On-time delivery with no damage and no return |
| **Surrogate Key** | System-generated unique identifier (not from source) |
| **Natural Key** | Business key from source system |
| **Grain** | Level of detail in a fact table (e.g., one row per shipment) |
| **Degenerate Dimension** | Dimension attribute stored in fact table (no separate dimension) |

---

*Last Updated: 2025-11-09*
*Version: 1.0*
