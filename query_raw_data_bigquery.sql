CREATE DATABASE thelook_sales;

--Query 1: Extract Raw Order Items Data
--Purpose: Collect raw order item records to build the fact_sales table.
--Output File: order_items.csv

SELECT 
    id AS order_item_id,
    order_id,
    user_id, 
    product_id, 
    sale_price, 
    status
FROM "bigquery-public-data.thelook_ecommerce.order_items";

--Query 2: Extract Raw Products Data
--Purpose: Collect raw product identity records to build the dim_products table. <br>
--Output File: products.csv <br>

SELECT
  id AS product_id,
  name,
  category,
  brand,
  department,
  cost,
  retail_price
FROM "bigquery-public-data.thelook_ecommerce.products";

--Query 3: Extract Raw Users Data
--Purpose: Collect raw product identity records to build the dim_products table. <br>
--Output File: users.csv <br>

SELECT
  id AS users_id,
  gender,
  country,
  traffic_source
FROM "bigquery-public-data.thelook_ecommerce.users";