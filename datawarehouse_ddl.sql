-- ============================================================================
-- Project      : TheLook E-Commerce Star-Schema Data Warehouse
-- Description  : DDL script to provision dimension and fact tables in PostgreSQL
-- Target DB    : thelook_sales
-- Author       : Ryan Farid Pratama
-- ============================================================================

-- 0. Cleaning: Drop existing tables in dependency order (Fact first, then Dimensions)
DROP TABLE IF EXISTS fact_sales CASCADE;
DROP TABLE IF EXISTS dim_products CASCADE;
DROP TABLE IF EXISTS dim_users CASCADE;

-- ============================================================================
-- 1. Dimension Table: Products (dim_products)
-- Grain: One row per unique product SKU
-- ============================================================================
CREATE TABLE dim_products (
    product_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    brand VARCHAR(100) NOT NULL,          
    department VARCHAR(50) NOT NULL,         
    cost NUMERIC(10, 2) NOT NULL,            
    retail_price NUMERIC(10, 2) NOT NULL     
);

-- ============================================================================
-- 2. Dimension Table: Users (dim_users)
-- Grain: One row per unique registered customer
-- ============================================================================
CREATE TABLE dim_users (
    user_id INT PRIMARY KEY,
    gender VARCHAR(10),
    country VARCHAR(100) NOT NULL,
    traffic_source VARCHAR(100) NOT NULL
);

-- ============================================================================
-- 3. Fact Table: Sales (fact_sales)
-- Grain: One row per individual order line item
-- ============================================================================
CREATE TABLE fact_sales (
    order_item_id INT PRIMARY KEY,
    product_id INT NOT NULL REFERENCES dim_products(product_id),
    user_id INT NOT NULL REFERENCES dim_users(user_id),
    sale_price NUMERIC(10, 2) NOT NULL,
    cost NUMERIC(10, 2) NOT NULL,
    profit NUMERIC(10, 2) NOT NULL
);

-- ============================================================================
-- 4. Performance Indexes
-- Speed up analytical GROUP BY and JOIN queries on foreign keys and reporting dimensions
-- ============================================================================
CREATE INDEX idx_fact_sales_product_id ON fact_sales(product_id);
CREATE INDEX idx_fact_sales_user_id    ON fact_sales(user_id);
CREATE INDEX idx_dim_products_category ON dim_products(category);
CREATE INDEX idx_dim_products_brand    ON dim_products(brand);

-- ============================================================================
-- 5. Post-Load Verification Query
-- Run after ETL pipeline execution to confirm expected row counts across tables
-- ============================================================================
SELECT 'dim_products' AS table_name, COUNT(*) AS row_count FROM dim_products
UNION ALL
SELECT 'dim_users'    AS table_name, COUNT(*) AS row_count FROM dim_users
UNION ALL
SELECT 'fact_sales'   AS table_name, COUNT(*) AS row_count FROM fact_sales;