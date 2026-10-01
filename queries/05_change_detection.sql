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
)
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