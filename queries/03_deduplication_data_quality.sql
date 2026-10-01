--- TABLE: staging.customers

-- ==========================================================================
-- Return exactly one record per customer, keeping the most recently updated record
--===========================================================================
with record_per_customer as (
	select *,
	row_number() over(partition by sc.customer_id order by sc.source_updated_at desc ) as ranked
	from staging.customers sc
)
select *
from record_per_customer 
where ranked = 1


--===========================================================================
-- Find customer_id values that have multiple records in staging.
--===========================================================================
select customer_id, count(*)
from staging.customers c 
group by customer_id 
having count(*) > 1 
order by customer_id

--===========================================================================
--Find customer records where any of these required fields are invalid:
-- customer_id is NULL
-- first_name is NULL or blank
-- last_name is NULL or blank
-- email is NULL or blank
--===========================================================================
select c.customer_id , c.first_name , c.last_name , c.email 
from staging.customers c 
where c.customer_id is null or 
c.first_name is null or 
trim(c.first_name) = '' or 
c.last_name is null or trim(c.last_name) = '' or
c.email is null or trim(c.email) = ''


--===========================================================================
--Find customer records where any of these required fields are invalid:
--Find order items where:
-- quantity is NULL
-- quantity <= 0
-- unit_price is NULL
-- unit_price < 0
 -- Return only invalid records.
-- Create a validation_error column using CASE.
--===========================================================================
SELECT
    oi.order_item_id,
    oi.order_id,
    oi.product_id,
    oi.quantity,
    oi.unit_price,
    CASE
        WHEN oi.quantity IS NULL OR oi.quantity <= 0
            THEN 'INVALID_QUANTITY'
        WHEN oi.unit_price IS NULL OR oi.unit_price < 0
            THEN 'INVALID_UNIT_PRICE'
    END AS validation_error
FROM source.order_items AS oi