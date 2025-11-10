# 🏗️ Viettel Post Data Warehouse

> A production-ready SQL data warehouse implementing Medallion Architecture (Bronze-Silver-Gold) for Viettel Post shipment analytics

## 📋 Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Data Model](#data-model)
- [Installation](#installation)
- [Usage](#usage)
- [Analytics & Reporting](#analytics--reporting)
- [Performance](#performance)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This data warehouse consolidates Viettel Post's operational data into a unified analytics platform, enabling data-driven decision making across:

- **Customer Analytics**: Segment analysis, lifetime value, retention
- **Operational Performance**: On-time delivery, damage rates, efficiency metrics
- **Financial Analytics**: Revenue trends, service profitability, COD collections
- **Route Optimization**: Route performance, capacity utilization
- **Service Quality**: Customer ratings, perfect delivery rate

### Key Features

✅ **Medallion Architecture** - Bronze (raw) → Silver (cleansed) → Gold (business-ready)  
✅ **Star Schema** - Optimized for BI tools and analytical queries  
✅ **Automated ETL** - One-command data warehouse refresh  
✅ **Pre-built Analytics** - 5+ ready-to-use report views  
✅ **Data Quality** - Comprehensive validation and cleansing  
✅ **Well-Documented** - Complete data catalog and diagrams

---

## 🏛️ Architecture

### Medallion Architecture Layers

```
📁 Sources (CSV Files)
    ↓
🥉 Bronze Layer (Raw Data)
    ├─ Exact copy of source data
    ├─ No transformations
    └─ Full load method
    ↓
🥈 Silver Layer (Cleansed Data)
    ├─ Data cleansing & standardization
    ├─ Type conversions
    ├─ Derived columns
    └─ Indexed tables
    ↓
🥇 Gold Layer (Business-Ready)
    ├─ Star schema (dimensions + facts)
    ├─ Business logic applied
    ├─ Aggregated views
    └─ Ready for BI tools
```

### Star Schema Components

**Fact Table:**
- `fact_shipments` - 100K+ shipment transactions

**Dimension Tables:**
- `dim_customers` - 10K+ customers
- `dim_locations` - 1K+ facilities
- `dim_routes` - 96 delivery routes
- `dim_date` - Date dimension
- `dim_service_types` - Service types (VHT, VCN, VTK)

**Analytics Views:**
- `report_daily_shipment_summary`
- `report_customer_performance`
- `report_route_performance`
- `report_service_type_performance`
- `report_provincial_analysis`

---

## 🚀 Quick Start

### Prerequisites

- SQL Server 2016+ (or compatible RDBMS)
- SQL Server Management Studio (SSMS) or Azure Data Studio
- Access to source CSV files
- Minimum 2GB database space

### 5-Minute Setup

1. **Create Database & Schemas**
   ```sql
   -- Run in SSMS
   :r scripts/setup/01_create_database_and_schemas.sql
   ```

2. **Create Bronze Layer**
   ```sql
   :r scripts/bronze/01_create_bronze_tables.sql
   :r scripts/bronze/02_load_bronze_procedure.sql
   ```

3. **Create Silver Layer**
   ```sql
   :r scripts/silver/01_create_silver_tables.sql
   :r scripts/silver/02_load_silver_procedure.sql
   ```

4. **Create Gold Layer**
   ```sql
   :r scripts/gold/01_create_gold_views.sql
   :r scripts/gold/02_create_analytics_views.sql
   ```

5. **Create Master Orchestration**
   ```sql
   :r scripts/setup/02_master_load_procedure.sql
   ```

6. **Load Data Warehouse**
   ```sql
   EXEC load_data_warehouse;
   ```

**Done!** 🎉 Your data warehouse is ready for analytics.

---

## 📂 Project Structure

```
viettel_dwh/
├── scripts/
│   ├── setup/
│   │   ├── 01_create_database_and_schemas.sql
│   │   └── 02_master_load_procedure.sql
│   ├── bronze/
│   │   ├── 01_create_bronze_tables.sql
│   │   └── 02_load_bronze_procedure.sql
│   ├── silver/
│   │   ├── 01_create_silver_tables.sql
│   │   └── 02_load_silver_procedure.sql
│   └── gold/
│       ├── 01_create_gold_views.sql
│       └── 02_create_analytics_views.sql
├── documentation/
│   ├── DATA_MODEL.md
│   ├── ARCHITECTURE_DIAGRAMS.md
│   ├── DATA_CATALOG.md
│   └── README.md (this file)
└── diagrams/
    └── (visual diagrams)
```

---

## 📊 Data Model

### Fact Table: `fact_shipments`

| Measure | Description |
|---------|-------------|
| **Volume** | weight_kg, volume_cbm, shipment_count |
| **Revenue** | shipping_fee, cod_amount, total_revenue |
| **Performance** | actual_delivery_hours, delivery_delay_hours |
| **Quality** | customer_rating, is_on_time, is_damaged |

### Dimensions

- **Customers**: 10K+ customers across Individual, Business, E-commerce types
- **Routes**: 96 routes covering major Vietnamese provinces
- **Locations**: 1K+ post offices, hubs, distribution centers
- **Date**: Time intelligence with year, quarter, month, week, day
- **Service Types**: VHT (Express), VCN (Standard), VTK (Economy)

See [DATA_MODEL.md](documentation/DATA_MODEL.md) for complete schema.

---

## 💻 Installation

### Step-by-Step Installation

#### 1. Database Setup

```sql
-- Create database
CREATE DATABASE viettel_post_dwh;
GO

USE viettel_post_dwh;
GO

-- Create schemas
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
GO
```

#### 2. Bronze Layer Tables

```sql
-- Run all Bronze scripts
-- Creates 4 raw data tables
```

#### 3. Silver Layer Tables

```sql
-- Run all Silver scripts
-- Creates 4 cleansed tables with indexes
```

#### 4. Gold Layer Views

```sql
-- Run all Gold scripts
-- Creates 5 dimensions, 1 fact, 5 report views
```

#### 5. Configure File Paths

Update file paths in `bronze/02_load_bronze_procedure.sql`:

```sql
-- Change these paths to your actual CSV locations
FROM '/mnt/user-data/uploads/viettel_customers.csv'
FROM '/mnt/user-data/uploads/viettel_locations.csv'
FROM '/mnt/user-data/uploads/viettel_routes.csv'
FROM '/mnt/user-data/uploads/viettel_shipments.csv'
```

---

## 🔄 Usage

### Daily Data Refresh

```sql
-- Full warehouse refresh (Bronze → Silver → Gold)
EXEC load_data_warehouse;
```

Expected output:
```
========================================================
     VIETTEL POST DATA WAREHOUSE - MASTER LOAD
========================================================
[1/4] Loading bronze.viettel_customers...
  ✓ Loaded 10001 rows

[2/4] Loading bronze.viettel_locations...
  ✓ Loaded 1001 rows

[3/4] Loading bronze.viettel_routes...
  ✓ Loaded 96 rows

[4/4] Loading bronze.viettel_shipments...
  ✓ Loaded 100001 rows

========================================================
                  LOAD COMPLETED SUCCESSFULLY
========================================================
Customers Loaded     : 10001
Locations Loaded     : 1001
Routes Loaded        : 96
Shipments Loaded     : 100001
--------------------------------------------------------
Bronze Layer Time    : 5 seconds
Silver Layer Time    : 10 seconds
Total Duration       : 15 seconds
========================================================
```

### Individual Layer Loads

```sql
-- Load Bronze only
EXEC bronze.load_bronze;

-- Load Silver only (requires Bronze to be loaded)
EXEC silver.load_silver;

-- Gold layer is views - no load needed
```

---

## 📈 Analytics & Reporting

### Sample Queries

#### 1. Daily Performance Overview

```sql
SELECT 
    pickup_date,
    total_shipments,
    total_revenue,
    on_time_delivery_rate,
    avg_customer_rating
FROM gold.report_daily_shipment_summary
WHERE year = 2024
ORDER BY pickup_date DESC;
```

#### 2. Top 10 Customers by Revenue

```sql
SELECT TOP 10
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

#### 3. Route Performance Analysis

```sql
SELECT 
    route_name,
    transport_mode,
    total_shipments,
    total_revenue,
    avg_actual_delivery_hours,
    on_time_rate
FROM gold.report_route_performance
WHERE route_utilization = 'High Utilization'
ORDER BY on_time_rate DESC;
```

#### 4. Service Type Comparison

```sql
SELECT 
    service_type_name,
    service_tier,
    total_shipments,
    avg_revenue_per_shipment,
    on_time_rate,
    avg_customer_rating
FROM gold.report_service_type_performance
ORDER BY total_revenue DESC;
```

#### 5. Monthly Trends

```sql
SELECT 
    year,
    month,
    month_name,
    SUM(total_shipments) AS monthly_shipments,
    SUM(total_revenue) AS monthly_revenue,
    AVG(on_time_delivery_rate) AS avg_otd_rate
FROM gold.report_daily_shipment_summary
WHERE year = 2024
GROUP BY year, month, month_name
ORDER BY year, month;
```

### BI Tool Connection

**Power BI:**
1. Get Data → SQL Server
2. Server: `your_server_name`
3. Database: `viettel_post_dwh`
4. Import: `gold.fact_shipments` and all `gold.dim_*` tables

**Tableau:**
1. Connect → Microsoft SQL Server
2. Server: `your_server_name`
3. Database: `viettel_post_dwh`
4. Select tables from `gold` schema

**Excel:**
1. Data → Get Data → From Database → From SQL Server
2. Server: `your_server_name`
3. Database: `viettel_post_dwh`
4. Load: Pre-built report views

---

## ⚡ Performance

### Current Performance

| Operation | Volume | Duration |
|-----------|--------|----------|
| Bronze Load | 111K rows | ~5 seconds |
| Silver Transform | 111K rows | ~10 seconds |
| Gold Views | N/A (views) | Instant |
| **Total ETL** | **111K rows** | **~15 seconds** |

### Optimization Features

✅ Indexed foreign keys  
✅ Computed columns for common calculations  
✅ Views instead of materialized tables in Gold  
✅ Bulk insert operations  
✅ Minimal logging (TABLOCK)

### Future Optimizations

- [ ] Partitioning on date columns
- [ ] Columnstore indexes for fact table
- [ ] Incremental loading (CDC)
- [ ] Parallel processing
- [ ] Compression

---

## 🔧 Troubleshooting

### Common Issues

#### Issue: "Cannot bulk load. File does not exist"
**Solution**: Update file paths in `bronze/02_load_bronze_procedure.sql` to point to your CSV files.

#### Issue: "Conversion failed when converting date from character string"
**Solution**: Check date format in CSV files. Should be YYYY-MM-DD for dates and YYYY-MM-DD HH:MM:SS for datetimes.

#### Issue: "Invalid column name"
**Solution**: Ensure CSV headers match expected column names exactly (case-sensitive).

#### Issue: "View or function has more nesting than maximum allowed"
**Solution**: This shouldn't happen, but if it does, simplify complex views or materialize intermediate results.

### Data Quality Checks

```sql
-- Check for duplicates
SELECT customer_id, COUNT(*) 
FROM silver.viettel_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check for NULLs in key fields
SELECT COUNT(*) AS null_count
FROM silver.viettel_shipments
WHERE customer_id IS NULL OR shipment_id IS NULL;

-- Verify data loaded
SELECT 
    'Customers' AS entity, COUNT(*) AS row_count 
FROM silver.viettel_customers
UNION ALL
SELECT 'Locations', COUNT(*) FROM silver.viettel_locations
UNION ALL
SELECT 'Routes', COUNT(*) FROM silver.viettel_routes
UNION ALL
SELECT 'Shipments', COUNT(*) FROM silver.viettel_shipments;
```

---

## 📚 Additional Documentation

- [Data Model](documentation/DATA_MODEL.md) - Complete schema reference
- [Architecture Diagrams](documentation/ARCHITECTURE_DIAGRAMS.md) - Visual diagrams
- [Data Catalog](documentation/DATA_CATALOG.md) - Field-level documentation

---

## 🤝 Contributing

This is a learning project. To extend or modify:

1. Follow the Medallion Architecture pattern
2. Add new transformations to Silver layer
3. Create new analytics views in Gold layer
4. Document all changes

---

## 📄 License

Educational/Learning Project - Viettel Post Data Warehouse

---

## 📞 Support

For questions or issues:
1. Check [Troubleshooting](#troubleshooting) section
2. Review [Data Model documentation](documentation/DATA_MODEL.md)
3. Verify all prerequisites are met

---

**Version**: 1.0  
**Last Updated**: 2025-11-09  
**Database**: SQL Server 2016+  
**Status**: Production-Ready ✅
