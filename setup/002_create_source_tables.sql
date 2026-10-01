-- =============================================
--SOURCE TABLES
-- =============================================


create table if not exists source.customers(
    customer_id BIGINT PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    country text,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

create table if not exists source.categories (
    category_id BIGINT PRIMARY KEY ,
    category_name TEXT NOT NULL
);

create table if not exists source.products(
    product_id BIGINT PRIMARY KEY, 
    product_name TEXT NOT NULL,
    category_id BIGINT,
    price NUMERIC(12,2) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE, 
    created_at TIMESTAMPTZ NOT NULL, 
    updated_at TIMESTAMPTZ NOT NULL
);

create table if not exists source.ordrs(
    order_id BIGINT PRIMARY KEY,
    customer_id BIGINT,
    order_status TEXT NOT NULL,
    order_date TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

create table if not exists source.order_items(
    order_item_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT,
    quantity INTEGER NOT NULL, 
    unit_price NUMERIC(12,2) NOT NULL
);

CREATE TABLE source.payments (
    payment_id      BIGINT PRIMARY KEY,
    order_id        BIGINT NOT NULL,
    customer_id     BIGINT,
    payment_amount  NUMERIC(12, 2) NOT NULL,
    payment_method  TEXT,
    payment_status  TEXT NOT NULL,
    payment_date    TIMESTAMPTZ NOT NULL
);


CREATE TABLE source.customer_addresses (
    address_id      BIGINT PRIMARY KEY,
    customer_id     BIGINT NOT NULL,
    city            TEXT,
    province        TEXT,
    country         TEXT,
    valid_from      DATE NOT NULL,
    valid_to        DATE
);


CREATE TABLE source.product_prices (
    product_id      BIGINT NOT NULL,
    country         TEXT NOT NULL,
    price           NUMERIC(12, 2) NOT NULL,
    valid_from      DATE NOT NULL,
    valid_to        DATE,

    PRIMARY KEY (product_id, country, valid_from)
);


CREATE TABLE source.employees (
    employee_id     BIGINT PRIMARY KEY,
    employee_name   TEXT NOT NULL,
    manager_id      BIGINT
);


CREATE TABLE source.events (
    event_id        BIGINT PRIMARY KEY,
    customer_id     BIGINT NOT NULL,
    event_type      TEXT NOT NULL,
    event_time      TIMESTAMPTZ NOT NULL
);

-- =============================================
--STAGING TABLES
-- =============================================
create table if not exists staging.customers(
    ingestion_id BIGINT generated always as identity primary key, 
    customer_id BIGINT,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    country TEXT,
    source_updated_at TIMESTAMPTZ, 
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

create table if not exists staging.pipeline_watermark(
    pipeline_name TEXT PRIMARY KEY, 
    last_processed_at TIMESTAMPTZ NOT NULL
);