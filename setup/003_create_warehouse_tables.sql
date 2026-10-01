-- ============================================================
-- CUSTOMER DIMENSION
-- Designed to support SCD Type 2 exercises.
-- ============================================================

create table if not exists warehouse.dim_customer(
    customer_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    country TEXT,

    effective_from TIMESTAMPTZ NOT NULL,
    effective_to TIMESTAMPTZ,
    is_current BOOLEAN NOT NULL DEFAULT TRUE
);

create table if not exists warehouse.dim_product(
    product_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id BIGINT NOT NULL,
    product_name TEXT NOT NULL,
    category_name TEXT,
    price NUMERIC(12,2),
    is_active BOOLEAN
);

create table if not exists warehouse.dim_date(
    date_key INTEGER PRIMARY KEY,
    full_date DATE UNIQUE NOT NULL, 
    year            INTEGER NOT NULL,
    quarter         INTEGER NOT NULL,
    month           INTEGER NOT NULL,
    month_name      TEXT NOT NULL,
    day_of_month    INTEGER NOT NULL,
    day_of_week     INTEGER NOT NULL,
    day_name        TEXT NOT NULL
);

create table if not exists warehouse.face_sales(
    sales_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    order_id BIGINT UNIQUE,
    order_item_id BIGINT NOT NULL UNIQUE, 

    customer_key BIGINT,
    product_key BIGINT,
    date_key INTEGER NOT NULL, 

    quantity INTEGER NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL, 
    sales_amount NUMERIC(14,2) NOT NULL,

    CONSTRAINT fk_fact_customer
        FOREIGN KEY (customer_key) REFERENCES warehouse.dim_customer(customer_key),

    CONSTRAINT fk_fact_product 
        FOREIGN KEY (product_key) REFERENCES warehouse.dim_product(product_key),

    CONSTRAINT fk_fact_date 
        FOREIGN KEY (date_key) REFERENCES warehouse.dim_date(date_key)
);