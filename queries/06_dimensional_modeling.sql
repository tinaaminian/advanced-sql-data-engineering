--===========================================================================
-- SCD Type 1: Update Current Dimension
--===========================================================================

--  INSERT / UPDATE / UNCHANGED CLASSIFICATION

--===========================================================================
-- SCENARIO:
-- New customer records have arrived in staging.

-- Before loading them into the warehouse, determine whether each customer is:
-- INSERT    → customer does not exist in the warehouse
-- UPDATE    → customer exists, but at least one tracked attribute changed
-- UNCHANGED → customer exists and tracked attributes are identical
--===========================================================================
select c.customer_id,
	   c.first_name,
	   c.last_name,
	   c.email ,
	   c.country ,
	   case
	   		when dc.customer_id is null then 'INSERT'
	   		when c.first_name is distinct from dc.first_name or 
		   	c.last_name is distinct from dc.last_name or 
		   	c.email is distinct from dc.email or
		   	c.country is distinct from dc.country 
	   		then 'UPDATE'
	   		else 'UNCHANGED' 
	   end as change_type
	   
from staging.customers c 
left join warehouse.dim_customer dc 
on c.customer_id  = dc.customer_id 

--===========================================================================
-- Hashed-based change detection
--SCENARIO:
-- Compare the latest incoming customer record with the current warehouse
-- customer and classify it as INSERT, UPDATE, or UNCHANGED.
--===========================================================================
with ranked_customers as (
    -- STEP1: Rank staging versions newset -> old
    select c.customer_id,
           c.first_name,
           c.last_name,
           c.email,
           c.country,
           c.source_updated_at,
           row_number() over(partition by c.customer_id order by c.source_updated_at desc) as ranked_customers
    from staging.customers as c
),
latest_customer as (
    -- STEP2: Keep only the latest version of each customer
    select customer_id,first_name,last_name,email,country,source_updated_at
    from ranked_customers
    where ranked_customers = 1
),
source_hashed as (
    -- STEP3: Generate finger print for incoming attributes
    select c.customer_id,c.first_name,c.last_name,c.email,c.country,
     md5(
        jsonb_build_array(
            c.first_name,
            c.last_name,
            c.email,
            c.country
        )::TEXT
    ) as source_hash
    from latest_customer as c
),
target_hash as (
    -- STEP 4: Generate the same finger print for warehouse attributes
    select dc.customer_id,
    md5(
        jsonb_build_array(
            dc.first_name,dc.last_name,dc.email,dc.country
        )::TEXT
    )as target_hash
    from warehouse.dim_customer as dc
),
final_customer as (
-- STEP 5: Compare source with target
    select s.customer_id,
        s.first_name,
        s.last_name,
        s.email,
        s.country,
        s.source_hash,
        t.target_hash,

        case
            when t.customer_id is null then 'INSERT'
            when s.source_hash is distinct from t.target_hash then 'UPDATE'
            else 'UNCHANGED'
        end as change_type

    from source_hashed as s
    left join target_hash as t
    on s.customer_id = t.customer_id
    order by s.customer_id
)
insert into warehouse.dim_customer(
    customer_id,
    first_name,
    last_name,
    email,
    country,
    effective_from,
    is_current
)
select customer_id, first_name, last_name, email, now() , TRUE
from final_customer
where change_type in ('INSERT', 'UPDATE')

on conflict (customer_id)
do update set 
first_name = excluded.first_name,
last_name = excluded.last_name,
email = excluded.email,
country = excluded.country ;


--===========================================================================
-- SCD Type 2
-- History is preserved
--===========================================================================


with duplicate_customer_detection as (
	select customer_id, first_name, last_name, email, country , 
	row_number() over(partition by c.customer_id order by c.source_updated_at desc) as ranked
	from staging.customers c 
),
deduplicated_customers as (
	select customer_id, first_name, last_name, email, country 
	from duplicate_customer_detection 
	where ranked = 1
),
detect_changes as (
	select c.customer_id , c.first_name , c.last_name , c.email , c.country ,
	case 
		when dc.customer_id  is null then 'INSERT'
		when dc.first_name is distinct from c.first_name or 
			 dc.last_name is distinct from c.last_name or 
			 dc.email is distinct from c.email or 
			 dc.country is distinct from c.country then 'UPDATE'
			 else 'SKIP'
	end as type_detection
	from deduplicated_customers as c
	left join warehouse.dim_customer dc 
	on c.customer_id  = dc.customer_id and dc.is_current = TRUE -- This Condition is required.
)
select *
from detect_changes

--===========================================================================
-- SCD Type 2
-- Update and insert must occure at the same time, so update can be inside a CTE
--===========================================================================

with ranked_customers as (
    select customer_id, first_name, last_name, email, country,source_updated_at,
    row_number() over(partition by customer_id order by source_updated_at desc) as rn
    from staging.customers
),
latest_customers as (
    select rc.customer_id, rc.first_name, rc.last_name, rc.email, rc.country, rc.source_updated_at
    from ranked_customers as rc
    where rn = 1
),
detect_changes as (
    select ls.customer_id, ls.first_name, ls.last_name, ls.email, ls.country, ls.source_updated_at, 
    case
        when dc.customer_id is null then 'INSERT'
        when dc.first_name is distinct from ls.first_name or 
        dc.last_name is distinct from ls.last_name or
        dc.email is distinct from ls.email or
        dc.country is distinct from ls.country then 'CHANGED'
        else 'SKIP'
    end as change_type
    from latest_customers as ls
    left join warehouse.dim_customer as dc 
    on ls.customer_id = dc.customer_id and dc.is_current = TRUE
),
expire_rows as (
    update warehouse.dim_customer as dc 
    set effective_to = ch.source_updated_at,
    is_current = FALSE 
    from detect_changes as ch 
    where dc.customer_id = ch.customer_id and 
    ch.change_type = 'CHANGED' and 
    dc.is_current = TRUE

    returning dc.customer_id
)
insert into warehouse.dim_customer(
    customer_id,first_name,last_name,email,country,effective_from, effective_to, is_current
)
select ch.customer_id,ch.first_name, ch.last_name,ch.email, ch.country, ch.source_updated_at, null, TRUE
from detect_changes as ch 
where ch.change_type in ('INSERT', 'CHANGED')



 ============================================================
-- SCD TYPE 2 — CUSTOMER DIMENSION
-- ============================================================
-- Assumptions:
-- 1. staging.customers contains source_updated_at.
-- 2. source_updated_at is NOT NULL for eligible records.
-- 3. This load maintains the latest customer state.
-- 4. Historical changes arriving out of order require
--    separate handling.
-- ============================================================

BEGIN;

-- ============================================================
-- STEP 1: Identify NEW and CHANGED customers
-- ============================================================

CREATE TEMP TABLE customer_changes
ON COMMIT DROP
AS

WITH ranked_customers AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.country,
        c.source_updated_at,

        ROW_NUMBER() OVER (
            PARTITION BY c.customer_id
            ORDER BY
                c.source_updated_at DESC,
                c.first_name DESC NULLS LAST,
                c.last_name DESC NULLS LAST,
                c.email DESC NULLS LAST,
                c.country DESC NULLS LAST
        ) AS rn

    FROM staging.customers AS c
    WHERE c.customer_id IS NOT NULL
      AND c.source_updated_at IS NOT NULL
),

latest_customers AS (
    SELECT
        customer_id,
        first_name,
        last_name,
        email,
        country,
        source_updated_at
    FROM ranked_customers
    WHERE rn = 1
),

detect_changes AS (
    SELECT
        s.customer_id,
        s.first_name,
        s.last_name,
        s.email,
        s.country,
        s.source_updated_at,

        CASE
            WHEN d.customer_id IS NULL
                THEN 'INSERT'

            WHEN (
                s.first_name,
                s.last_name,
                s.email,
                s.country
            ) IS DISTINCT FROM (
                d.first_name,
                d.last_name,
                d.email,
                d.country
            )
            AND s.source_updated_at > d.effective_from
                THEN 'CHANGED'

            ELSE 'SKIP'
        END AS change_type

    FROM latest_customers AS s

    LEFT JOIN warehouse.dim_customer AS d
        ON s.customer_id = d.customer_id
       AND d.is_current = TRUE
)

SELECT *
FROM detect_changes
WHERE change_type IN ('INSERT', 'CHANGED');


-- STEP 2: Expire existing versions for CHANGED customers


UPDATE warehouse.dim_customer AS d
SET
    effective_to = c.source_updated_at,
    is_current = FALSE

FROM customer_changes AS c

WHERE d.customer_id = c.customer_id
  AND d.is_current = TRUE
  AND c.change_type = 'CHANGED';

-- STEP 3: Insert NEW customers and new CHANGED versions


INSERT INTO warehouse.dim_customer (
    customer_id,
    first_name,
    last_name,
    email,
    country,
    effective_from,
    effective_to,
    is_current
)

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.country,
    c.source_updated_at,
    NULL,
    TRUE

FROM customer_changes AS c;

-- STEP 4: Commit both operations atomically

COMMIT;

--===========================================================================
-- Fact table loading and surrogate-key lookup
--===========================================================================
select dc.customer_key, o.order_id , o.customer_id ,o.order_date ,
dc.first_name , dc.last_name ,dc.email, dc.effective_from , dc.effective_to 
from source.ordrs o 
left join warehouse.dim_customer dc 
on o.customer_id = dc.customer_id
and  o.order_date >= dc.effective_from
and (o.order_date < dc.effective_to or dc.effective_to is null)

-- ============================================================================
-- FACT TABLE LOAD — DIMENSION SURROGATE KEY LOOKUPS
-- Grain: one row per order item
--
-- Demonstrates:
--   1. SCD2 temporal customer lookup
--   2. Product surrogate-key lookup
--   3. Date surrogate-key lookup
--   4. Fact measure calculation
-- ============================================================================

SELECT
    o.order_id,
    oi.item_id AS order_item_id,
    dc.customer_key,
    dp.product_key,
    dd.date_key,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price AS sales_amount
FROM source.orders AS o
JOIN source.order_items AS oi
    ON o.order_id = oi.order_id

LEFT JOIN warehouse.dim_customer AS dc
    ON o.customer_id = dc.customer_id
   AND o.order_date >= dc.effective_from
   AND (
       o.order_date < dc.effective_to
       OR dc.effective_to IS NULL
   )

LEFT JOIN warehouse.dim_product AS dp
    ON oi.product_id = dp.product_id

LEFT JOIN warehouse.dim_date AS dd
    ON o.order_date::date = dd.full_date;
