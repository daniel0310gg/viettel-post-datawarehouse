# 🚀 Viettel Post Data Warehouse - Implementation Guide

## Quick Start (5 Minutes)

### Step 1: Review Prerequisites
✅ SQL Server 2016+ installed  
✅ SQL Server Management Studio (SSMS) or Azure Data Studio  
✅ Your CSV files ready: viettel_customers.csv, viettel_locations.csv, viettel_routes.csv, viettel_shipments.csv  
✅ Minimum 2GB disk space

### Step 2: Update File Paths
Open `scripts/bronze/02_load_bronze_procedure.sql` and update these lines:

```sql
-- Line ~30: Update to your file locations
FROM 'D:\your_path\viettel_customers.csv'
FROM 'D:\your_path\viettel_locations.csv'
FROM 'D:\your_path\viettel_routes.csv'
FROM 'D:\your_path\viettel_shipments.csv'
```

### Step 3: Execute Scripts in Order

**In SSMS, run these in sequence:**

1. **Setup** (30 seconds)
   ```sql
   :r scripts/setup/01_create_database_and_schemas.sql
   ```

2. **Bronze Layer** (1 minute)
   ```sql
   :r scripts/bronze/01_create_bronze_tables.sql
   :r scripts/bronze/02_load_bronze_procedure.sql
   ```

3. **Silver Layer** (1 minute)
   ```sql
   :r scripts/silver/01_create_silver_tables.sql
   :r scripts/silver/02_load_silver_procedure.sql
   ```

4. **Gold Layer** (1 minute)
   ```sql
   :r scripts/gold/01_create_gold_views.sql
   :r scripts/gold/02_create_analytics_views.sql
   ```

5. **Master Procedure** (30 seconds)
   ```sql
   :r scripts/setup/02_master_load_procedure.sql
   ```

### Step 4: Load Data
```sql
EXEC load_data_warehouse;
```

### Step 5: Validate
```sql
:r scripts/setup/03_validation_script.sql
```

### Step 6: Start Analyzing!
```sql
-- Get today's performance
SELECT * FROM gold.report_daily_shipment_summary
WHERE pickup_date = CAST(GETDATE() AS DATE);

-- Top 10 customers
SELECT TOP 10 * FROM gold.report_customer_performance
ORDER BY total_revenue DESC;
```

---

## Detailed Architecture

### Medallion Architecture Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        DATA FLOW                            │
└─────────────────────────────────────────────────────────────┘

CSV Files (Source)
    │
    │ EXTRACT + LOAD (No Transform)
    ↓
🥉 BRONZE LAYER
    ├─ bronze.viettel_customers      (10,001 rows)
    ├─ bronze.viettel_locations      (1,001 rows)
    ├─ bronze.viettel_routes         (96 rows)
    └─ bronze.viettel_shipments      (100,001 rows)
    │
    │ EXTRACT + TRANSFORM + LOAD
    ↓
🥈 SILVER LAYER
    ├─ silver.viettel_customers      (10,001 rows, cleansed)
    ├─ silver.viettel_locations      (1,001 rows, cleansed)
    ├─ silver.viettel_routes         (96 rows, cleansed)
    └─ silver.viettel_shipments      (100,001 rows, cleansed)
    │
    │ TRANSFORM (Views)
    ↓
🥇 GOLD LAYER (Star Schema)
    ├─ Dimensions:
    │  ├─ dim_customers
    │  ├─ dim_locations
    │  ├─ dim_routes
    │  ├─ dim_date
    │  └─ dim_service_types
    ├─ Facts:
    │  └─ fact_shipments
    └─ Analytics:
       ├─ report_daily_shipment_summary
       ├─ report_customer_performance
       ├─ report_route_performance
       ├─ report_service_type_performance
       └─ report_provincial_analysis
```

---

## Transformations Applied

### Bronze → Silver Transformations

| Transformation Type | Examples |
|---------------------|----------|
| **Data Cleansing** | TRIM whitespace, remove duplicates |
| **Standardization** | Province to UPPERCASE, email to lowercase |
| **Type Conversion** | "True"/"False" → BIT, strings → DECIMAL, strings → DATE |
| **Validation** | Check enums (service_type IN ('VHT','VCN','VTK')) |
| **Enrichment** | Add dwh_create_date, dwh_update_date |
| **Derived Columns** | Calculate customer_tenure_days, delivery_delay_hours |

### Silver → Gold Transformations

| Transformation Type | Examples |
|---------------------|----------|
| **Surrogate Keys** | Generate customer_key, route_key, etc. |
| **Data Integration** | JOIN multiple silver tables |
| **Business Logic** | Calculate lifecycle_stage, revenue_tier |
| **Aggregations** | Daily summaries, customer totals |
| **Star Schema** | Create fact + dimension views |

---

## SQL Cheat Sheet

### Most Common Queries

```sql
-- 1. Check data warehouse status
SELECT 
    'Customers' AS entity, 
    COUNT(*) AS silver_count,
    (SELECT COUNT(*) FROM gold.dim_customers) AS gold_count
FROM silver.viettel_customers
UNION ALL
SELECT 'Shipments', COUNT(*), (SELECT COUNT(*) FROM gold.fact_shipments)
FROM silver.viettel_shipments;

-- 2. Today's performance
SELECT 
    total_shipments,
    total_revenue,
    on_time_delivery_rate,
    avg_customer_rating
FROM gold.report_daily_shipment_summary
WHERE pickup_date = CAST(GETDATE() AS DATE);

-- 3. This month's revenue
SELECT 
    SUM(total_revenue) AS monthly_revenue,
    SUM(total_shipments) AS monthly_shipments,
    AVG(on_time_delivery_rate) AS avg_otd_rate
FROM gold.report_daily_shipment_summary
WHERE year = YEAR(GETDATE())
  AND month = MONTH(GETDATE());

-- 4. Customer segments distribution
SELECT 
    customer_segment,
    COUNT(*) AS customer_count,
    SUM(total_shipments) AS shipments,
    SUM(total_revenue) AS revenue
FROM gold.report_customer_performance
GROUP BY customer_segment
ORDER BY revenue DESC;

-- 5. Service type comparison
SELECT 
    service_type_name,
    total_shipments,
    total_revenue,
    on_time_rate,
    avg_customer_rating
FROM gold.report_service_type_performance
ORDER BY total_shipments DESC;

-- 6. Top performing routes
SELECT TOP 10
    route_name,
    transport_mode,
    total_shipments,
    total_revenue,
    on_time_rate
FROM gold.report_route_performance
ORDER BY total_revenue DESC;

-- 7. Provincial analysis
SELECT TOP 10
    province,
    outbound_shipments,
    inbound_shipments,
    total_revenue,
    on_time_rate
FROM gold.report_provincial_analysis
ORDER BY total_revenue DESC;
```

---

## Maintenance & Operations

### Daily Refresh (Recommended Schedule: 2:00 AM)

```sql
-- Single command to refresh entire warehouse
EXEC load_data_warehouse;
```

### Manual Layer Refresh

```sql
-- Refresh Bronze only (if new CSV files)
EXEC bronze.load_bronze;

-- Refresh Silver only (if Bronze updated)
EXEC silver.load_silver;

-- Gold refreshes automatically (it's views)
```

### Data Quality Checks

```sql
-- Run comprehensive validation
:r scripts/setup/03_validation_script.sql

-- Quick row count check
SELECT 
    'Customers' AS table_name, 
    COUNT(*) AS row_count 
FROM silver.viettel_customers
UNION ALL
SELECT 'Shipments', COUNT(*) FROM silver.viettel_shipments;

-- Check for processing errors
SELECT 
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customers,
    SUM(CASE WHEN total_revenue < 0 THEN 1 ELSE 0 END) AS negative_revenue
FROM silver.viettel_shipments;
```

---

## BI Tool Integration

### Power BI Setup

1. **Get Data** → SQL Server
2. **Server**: `your_server_name`
3. **Database**: `viettel_post_dwh`
4. **Import these tables**:
   - gold.fact_shipments
   - gold.dim_customers
   - gold.dim_routes
   - gold.dim_date
   - gold.dim_service_types

5. **Create relationships** in Power BI:
   - fact_shipments[customer_key] → dim_customers[customer_key]
   - fact_shipments[route_key] → dim_routes[route_key]
   - fact_shipments[pickup_date_key] → dim_date[date_key]
   - fact_shipments[service_type_key] → dim_service_types[service_type_key]

### Tableau Setup

1. **Connect** → Microsoft SQL Server
2. **Server**: `your_server_name`
3. **Database**: `viettel_post_dwh`
4. **Drag tables** to canvas:
   - Start with `fact_shipments`
   - Join dimensions via foreign keys
   - Or use pre-built report views for quick dashboards

### Excel Setup

1. **Data** → Get Data → From Database → From SQL Server
2. **Connection details**: Server + Database
3. **Load report views** directly:
   - gold.report_daily_shipment_summary
   - gold.report_customer_performance
   - gold.report_route_performance

---

## Troubleshooting Guide

### Issue: CSV files not loading

**Symptoms**: Error "Cannot bulk load. File does not exist"

**Solution**:
1. Update file paths in `bronze/02_load_bronze_procedure.sql`
2. Ensure SQL Server has read access to file location
3. Check file names match exactly (case-sensitive on Linux)

**Example fix**:
```sql
-- Change FROM path
FROM 'C:\Data\viettel_customers.csv'  -- ✅ Correct path
-- not
FROM 'D:\Wrong\path\customers.csv'    -- ❌ Wrong path
```

### Issue: Data type conversion errors

**Symptoms**: "Conversion failed when converting..."

**Solution**:
1. Check CSV data format matches expected types
2. Look for special characters or encoding issues
3. Verify dates are in YYYY-MM-DD format
4. Ensure UTF-8 encoding for Vietnamese characters

### Issue: Slow performance

**Symptoms**: Queries taking > 10 seconds

**Solution**:
1. Add missing indexes:
   ```sql
   CREATE INDEX IX_shipments_customer 
   ON silver.viettel_shipments(customer_id);
   ```
2. Update statistics:
   ```sql
   UPDATE STATISTICS silver.viettel_shipments;
   ```
3. Consider partitioning large tables by date

### Issue: Missing data in Gold layer

**Symptoms**: Gold views show fewer rows than Silver

**Solution**:
1. Check for NULL foreign keys:
   ```sql
   SELECT COUNT(*) FROM silver.viettel_shipments
   WHERE customer_id IS NULL;
   ```
2. Verify referential integrity:
   ```sql
   :r scripts/setup/03_validation_script.sql
   ```

---

## Performance Benchmarks

### Expected Load Times (100K shipments)

| Layer | Operation | Duration |
|-------|-----------|----------|
| Bronze | BULK INSERT | 3-5 seconds |
| Silver | Transform + INSERT | 8-12 seconds |
| Gold | Views (instant) | 0 seconds |
| **Total** | **Full refresh** | **15-20 seconds** |

### Query Performance (Gold Layer)

| Query Type | Expected Time |
|------------|---------------|
| Simple dimension lookup | < 0.1 seconds |
| Fact table scan (100K rows) | 1-2 seconds |
| Daily aggregation | 0.5-1 seconds |
| Complex report view | 2-3 seconds |
| Customer lifetime value | 1-2 seconds |

---

## Next Steps & Enhancements

### Immediate (You can do now)
- [ ] Connect Power BI and build dashboards
- [ ] Create alerts for low on-time delivery rate
- [ ] Schedule daily refreshes
- [ ] Share reports with stakeholders

### Short-term (Next sprint)
- [ ] Add incremental loading for large tables
- [ ] Implement SCD Type 2 for customer dimension
- [ ] Create more aggregated fact tables
- [ ] Add data quality monitoring dashboard

### Long-term (Next quarter)
- [ ] Migrate to cloud (Azure SQL / Snowflake)
- [ ] Implement real-time CDC
- [ ] Add machine learning predictions
- [ ] Build self-service BI layer

---

## File Structure Reference

```
viettel_dwh/
│
├── README.md                           ← Start here!
│
├── documentation/
│   ├── DATA_MODEL.md                   ← Schema reference
│   ├── ARCHITECTURE_DIAGRAMS.md        ← Visual diagrams (Mermaid)
│   ├── DATA_CATALOG.md                 ← Field-level documentation
│   └── IMPLEMENTATION_GUIDE.md         ← This file
│
└── scripts/
    ├── setup/
    │   ├── 01_create_database_and_schemas.sql
    │   ├── 02_master_load_procedure.sql
    │   └── 03_validation_script.sql
    │
    ├── bronze/
    │   ├── 01_create_bronze_tables.sql
    │   └── 02_load_bronze_procedure.sql
    │
    ├── silver/
    │   ├── 01_create_silver_tables.sql
    │   └── 02_load_silver_procedure.sql
    │
    └── gold/
        ├── 01_create_gold_views.sql
        └── 02_create_analytics_views.sql
```

---

## Support & Resources

### Documentation
- [README.md](../README.md) - Project overview
- [DATA_MODEL.md](DATA_MODEL.md) - Complete schema
- [DATA_CATALOG.md](DATA_CATALOG.md) - Field dictionary
- [ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md) - Visual diagrams

### Key Concepts
- **Medallion Architecture**: Bronze (raw) → Silver (cleansed) → Gold (business)
- **Star Schema**: Dimensions + Facts optimized for analytics
- **SCD**: Slowly Changing Dimensions for historical tracking
- **ETL**: Extract, Transform, Load process

### Best Practices
1. Always run validation after loading data
2. Schedule daily refreshes during off-peak hours
3. Monitor query performance regularly
4. Document any custom modifications
5. Back up database before major changes

---

**Version**: 1.0  
**Last Updated**: 2025-11-09  
**Status**: Production-Ready ✅

**Happy Analyzing! 📊**
