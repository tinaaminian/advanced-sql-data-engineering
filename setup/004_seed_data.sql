-- ============================================================
-- CUSTOMERS
-- ============================================================

INSERT INTO source.customers (
    customer_id,
    first_name,
    last_name,
    email,
    country,
    created_at,
    updated_at
)
VALUES
    (1, 'Tina', 'Amini', 'tina@example.com', 'Canada',
     '2025-01-10 10:00:00+00', '2026-01-10 10:00:00+00'),

    (2, 'John', 'Smith', 'john@example.com', 'Canada',
     '2025-02-15 11:00:00+00', '2026-02-15 11:00:00+00'),

    (3, 'Sara', 'Lee', 'sara@example.com', 'USA',
     '2025-03-20 12:00:00+00', '2026-03-20 12:00:00+00'),

    (4, 'David', 'Brown', 'david@example.com', 'Canada',
     '2025-04-05 09:00:00+00', '2026-04-05 09:00:00+00'),

    (5, 'Emma', 'Wilson', 'emma@example.com', 'UK',
     '2025-05-01 14:00:00+00', '2026-05-01 14:00:00+00');

-- ============================================================
-- CATEGORIES
-- ============================================================

INSERT INTO source.categories (
    category_id,
    category_name
)
VALUES
    (1, 'Electronics'),
    (2, 'Home'),
    (3, 'Books');

-- ============================================================
-- PRODUCTS
-- ============================================================

INSERT INTO source.products (
    product_id,
    product_name,
    category_id,
    price,
    is_active,
    created_at,
    updated_at
)
VALUES
    (101, 'Laptop', 1, 1200.00, TRUE,
     '2025-01-01 00:00:00+00', '2026-01-01 00:00:00+00'),

    (102, 'Mouse', 1, 40.00, TRUE,
     '2025-01-01 00:00:00+00', '2026-01-01 00:00:00+00'),

    (103, 'Coffee Maker', 2, 150.00, TRUE,
     '2025-01-01 00:00:00+00', '2026-01-01 00:00:00+00'),

    (104, 'SQL Handbook', 3, 60.00, TRUE,
     '2025-01-01 00:00:00+00', '2026-01-01 00:00:00+00');

-- ============================================================
-- ORDERS
-- ============================================================

INSERT INTO source.ordrs (
    order_id,
    customer_id,
    order_status,
    order_date,
    updated_at
)
VALUES
    (1001, 1, 'COMPLETED',
     '2026-01-10 10:00:00+00', '2026-01-10 12:00:00+00'),

    (1002, 1, 'COMPLETED',
     '2026-02-15 11:00:00+00', '2026-02-15 13:00:00+00'),

    (1003, 2, 'CANCELLED',
     '2026-02-20 09:00:00+00', '2026-02-20 10:00:00+00'),

    (1004, 3, 'COMPLETED',
     '2026-03-05 15:00:00+00', '2026-03-05 17:00:00+00'),

    (1005, 999, 'COMPLETED',
     '2026-03-10 10:00:00+00', '2026-03-10 11:00:00+00');

-- ============================================================
-- ORDER ITEMS
-- Grain: one row per product line within an order
-- ============================================================

INSERT INTO source.order_items (
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price
)
VALUES
    (1, 1001, 101, 1, 1200.00),
    (2, 1001, 102, 2, 40.00),
    (3, 1002, 103, 1, 150.00),
    (4, 1004, 104, 2, 60.00),

    -- Deliberately references a nonexistent product
    (5, 1005, 999, 1, 100.00);


-- ============================================================
-- PAYMENTS
-- ============================================================

INSERT INTO source.payments (
    payment_id,
    order_id,
    customer_id,
    payment_amount,
    payment_method,
    payment_status,
    payment_date
)
VALUES
    (501, 1001, 1, 600.00, 'CARD', 'SUCCESS',
     '2026-01-10 10:05:00+00'),

    (502, 1001, 1, 680.00, 'CARD', 'SUCCESS',
     '2026-01-10 10:06:00+00'),

    (503, 1002, 1, 150.00, 'PAYPAL', 'SUCCESS',
     '2026-02-15 11:05:00+00'),

    (504, 1003, 2, 50.00, 'CARD', 'FAILED',
     '2026-02-20 09:05:00+00'),

    (505, 1004, 3, 120.00, 'CARD', 'SUCCESS',
     '2026-03-05 15:05:00+00');

-- ============================================================
-- CUSTOMER ADDRESS HISTORY
-- ============================================================

INSERT INTO source.customer_addresses (
    address_id,
    customer_id,
    city,
    province,
    country,
    valid_from,
    valid_to
)
VALUES
    (1, 1, 'Windsor', 'Ontario', 'Canada',
     '2025-01-01', '2026-01-31'),

    (2, 1, 'Toronto', 'Ontario', 'Canada',
     '2026-02-01', NULL),

    (3, 2, 'Ottawa', 'Ontario', 'Canada',
     '2025-01-01', NULL),

    (4, 3, 'New York', 'New York', 'USA',
     '2025-01-01', NULL);

-- ============================================================
-- PRODUCT PRICE HISTORY
-- ============================================================

INSERT INTO source.product_prices (
    product_id,
    country,
    price,
    valid_from,
    valid_to
)
VALUES
    (101, 'Canada', 1150.00, '2025-01-01', '2025-12-31'),
    (101, 'Canada', 1200.00, '2026-01-01', NULL),

    (101, 'USA', 1100.00, '2026-01-01', NULL),

    (102, 'Canada', 35.00, '2025-01-01', '2025-12-31'),
    (102, 'Canada', 40.00, '2026-01-01', NULL),

    (103, 'Canada', 150.00, '2026-01-01', NULL),

    (104, 'Canada', 60.00, '2026-01-01', NULL);

-- ============================================================
-- EMPLOYEE HIERARCHY
-- ============================================================

INSERT INTO source.employees (
    employee_id,
    employee_name,
    manager_id
)
VALUES
    (1, 'Alice', NULL),
    (2, 'Bob', 1),
    (3, 'Carol', 1),
    (4, 'Daniel', 2),
    (5, 'Eva', 2),
    (6, 'Frank', 4);

-- ============================================================
-- CUSTOMER EVENTS
-- ============================================================

INSERT INTO source.events (
    event_id,
    customer_id,
    event_type,
    event_time
)
VALUES
    (1, 1, 'page_view',   '2026-03-01 10:00:00+00'),
    (2, 1, 'search',      '2026-03-01 10:05:00+00'),
    (3, 1, 'add_to_cart', '2026-03-01 10:10:00+00'),
    (4, 1, 'purchase',    '2026-03-01 10:15:00+00'),

    (5, 1, 'page_view',   '2026-03-01 14:00:00+00'),
    (6, 1, 'search',      '2026-03-01 14:08:00+00'),

    (7, 2, 'page_view',   '2026-03-02 09:00:00+00'),
    (8, 2, 'search',      '2026-03-02 09:10:00+00'),
    (9, 2, 'purchase',    '2026-03-02 09:20:00+00');

-- ============================================================
-- STAGING CUSTOMER RECORDS
-- Contains multiple versions of the same business key.
-- ============================================================

INSERT INTO staging.customers (
    customer_id,
    first_name,
    last_name,
    email,
    country,
    source_updated_at
)
VALUES
    (1, 'Tina', 'Amini', 'old_tina@example.com', 'Canada',
     '2026-01-01 10:00:00+00'),

    (1, 'Tina', 'Amini', 'tina@example.com', 'Canada',
     '2026-02-01 10:00:00+00'),

    (2, 'John', 'Smith', 'john@example.com', 'Canada',
     '2026-01-15 10:00:00+00'),

    (2, 'John', 'Smith', 'john.new@example.com', 'Canada',
     '2026-03-01 10:00:00+00'),

    (3, 'Sara', 'Lee', 'sara@example.com', 'USA',
     '2026-02-20 10:00:00+00');

-- ============================================================
-- PIPELINE WATERMARK
-- ============================================================

INSERT INTO staging.pipeline_watermark (
    pipeline_name,
    last_processed_at
)
VALUES (
    'customers_incremental_load',
    '2026-01-01 00:00:00+00'
);