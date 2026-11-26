# The Look E-Commerce: ETL Pipeline & Star-Schema Data Warehouse

An end-to-end **ETL (Extract, Transform, Load)** pipeline that builds a star-schema
data warehouse for **The Look**, a fictional e-commerce clothing retailer. Raw
transactional data is extracted from Google BigQuery, cleaned and reshaped with
PySpark, and loaded into a PostgreSQL data warehouse modeled for sales analytics.

**Author:** Ryan Farid Pratama <br>
**Tech Stack:** Python · PySpark · Google BigQuery · PostgreSQL · SQL

> **Scope:** This project covers the data engineering pipeline (extraction,
> transformation, modeling, and loading). The business context in the notebook
> explains *why* the warehouse is modeled the way it is; downstream analytical
> querying is out of scope.

---

## Business Context

As a data engineer at The Look, the task is to give the executive team an
analytical foundation for sales analysis without querying the operational
database directly. A dedicated data warehouse isolates analytical workloads and
models the data for fast aggregation.

**Business question:** Which product categories, brands, and departments generate
the highest sales volume and revenue? The warehouse is modeled to answer exactly
this kind of question.

---

## Pipeline Architecture

```
Google BigQuery                PySpark                     PostgreSQL
(thelook_ecommerce)        (clean + transform)         (star-schema DWH)
+---------------+          +----------------+          +----------------+
|  order_items  | -------> |  fact_sales    | -------> |  fact_sales    |
|  products     | -------> |  dim_products  | -------> |  dim_products  |
|  users        | -------> |  dim_users     | -------> |  dim_users     |
+---------------+          +----------------+          +----------------+
     Extract                  Transform                      Load
```

1. **Extract** — Query the required columns from the public BigQuery dataset
   `bigquery-public-data.thelook_ecommerce` and export them as local CSV staging
   files. See [`query_raw_data_bigquery.sql`](query_raw_data_bigquery.sql).
2. **Transform** — With PySpark: drop nulls on primary keys, remove duplicates,
   impute missing descriptive values, cast types, round monetary columns, keep
   only `Complete` orders, and derive `profit = sale_price - cost`.
3. **Model** — Design a **star schema** (`fact_sales` + `dim_products` +
   `dim_users`) optimized for analytical (OLAP) queries.
4. **Load** — Provision the warehouse tables with
   [`datawarehouse_ddl.sql`](datawarehouse_ddl.sql) and load the transformed
   DataFrames into PostgreSQL.

---

## Data Model (Star Schema)

A central fact table references two dimension tables.

**`fact_sales`** — grain: one row per completed order line item

| Column | Type | Key | Description |
| :--- | :--- | :--- | :--- |
| `order_item_id` | `INTEGER` | PK | Unique line item in an order |
| `product_id` | `INTEGER` | FK → `dim_products` | Product reference |
| `user_id` | `INTEGER` | FK → `dim_users` | Customer reference |
| `sale_price` | `NUMERIC(10,2)` | | Final selling price (USD) |
| `cost` | `NUMERIC(10,2)` | | Unit cost (USD) |
| `profit` | `NUMERIC(10,2)` | | Derived: `sale_price - cost` |

**`dim_products`** — grain: one row per product SKU
(`product_id`, `name`, `category`, `brand`, `department`, `cost`, `retail_price`)

**`dim_users`** — grain: one row per customer
(`user_id`, `gender`, `country`, `traffic_source`)

**Why a star schema?** Analytical queries aggregate the fact table and join to
dimensions in a single hop, which is faster and simpler to write than the
multi-level joins a fully normalized (snowflake) model needs. Measures live in
the fact table; descriptive attributes live in the dimensions, so the model is
easy to extend.

---

## Key Results

| Target table | Source | Before | After | Difference | Reason |
| :--- | :--- | ---: | ---: | ---: | :--- |
| `fact_sales` | `order_items` | 151,239 | 38,097 | −113,142 | Kept only `status = "Complete"` orders |
| `dim_products` | `products` | 29,120 | 29,120 | 0 | No PK nulls or duplicates |
| `dim_users` | `users` | 100,000 | 100,000 | 0 | No PK nulls or duplicates |

- Imputed missing `name` (2 rows) and `brand` (24 rows) in `dim_products` with
  `"Unknown"` rather than dropping valid products.
- No nulls remained in any table after transformation.

---

## Repository Structure

```
.
├── thelook_etl_pipeline.ipynb     # Main ETL notebook (Extract → Transform → Load)
├── query_raw_data_bigquery.sql    # BigQuery extraction queries
├── datawarehouse_ddl.sql          # PostgreSQL DDL: tables, keys, indexes, verification
├── requirements.txt               # Python dependencies
├── .env.example                   # Template for environment variables
├── .gitignore
├── LICENSE
└── README.md
```

---

## Getting Started

### Prerequisites
- Python 3.10+
- Apache Spark / PySpark with the [PostgreSQL JDBC driver](https://jdbc.postgresql.org/)
- A running PostgreSQL instance
- Google Cloud access to query BigQuery public datasets

### Setup

1. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure credentials** — copy the template and fill in your values:
   ```bash
   cp .env.example .env
   ```
   ```
   PG_HOST=localhost
   PG_PORT=5432
   PG_DB=thelook_sales
   PG_USER=your_username
   PG_PASSWORD=your_password
   ```
   `.env` is git-ignored and must never be committed.

3. **Create the warehouse schema**
   ```bash
   psql -U your_username -d thelook_sales -f datawarehouse_ddl.sql
   ```

4. **Run the pipeline** — open `thelook_etl_pipeline.ipynb` and run the cells top
   to bottom. It extracts, transforms, and loads the data into PostgreSQL.

5. **Verify the load** — the DDL script ends with a row-count query you can run to
   confirm the expected counts (38,097 / 29,120 / 100,000).

---

## Notes

- Raw CSV extracts are **not** committed to this repository; they are generated by
  running the extraction queries against BigQuery.
- Credentials live only in a local, git-ignored `.env` file.

## License

See [LICENSE](LICENSE).
