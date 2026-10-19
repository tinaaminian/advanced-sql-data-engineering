-- INCREMENTAL LOAD USING A WATERMARK

--===========================================================================
-- Return only customer records that were updated AFTER the pipeline's
--===========================================================================

select c.customer_id, c.first_name , c.last_name , c.email 
from staging.customers c 
where c.source_updated_at > (
	select last_processed_at
	from staging.pipeline_watermark pw 
	where pipeline_name = 'customers_incremental_load'
)


--===========================================================================
-- Watermark Boundary & Safe Incremental Loading
--===========================================================================

select c.customer_id, c.first_name , c.last_name , c.email 
from staging.customers c 
where c.source_updated_at >= (
	select last_processed_at  - interval '5 minutes'
	from staging.pipeline_watermark pw 
	where pw.pipeline_name = 'customers_incremental_load'
)

--===========================================================================
-- Determine the newest source_updated_at value in the customer records.
--===========================================================================
select max(source_updated_at) as newest_date
from staging.customers c 

--===========================================================================
-- Upsert the Pipeline Watermark
-- Store the new watermark for: 'customers_incremental_load'
--===========================================================================

insert into staging.pipeline_watermark (
    pipeline_name, 
    last_processed_at
)
select 
    'customers_incremental_load' , 
    max(source_updated_at) 
from staging.customers
on conflict (pipeline_name)
do update set 
last_processed_at = excluded.last_processed_at

--===========================================================================
-- Transaction-safe incremental load
-- Perform the target load and watermark update as one atomic transaction.
--===========================================================================
    -- Step1: laod/upsert customers into warehouse
insert into warehouse.dim_customer(
    customer_id,
    first_name,
    last_name,
    email,
    country
)
select customer_id, first_name,last_name,email,country 
from staging.customers
on conflict (customer_id)
do update set 
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    email = excluded.email,
    country = excluded.country

-- Step2: Update the watermark
insert into staging.pipeline_watermark(
    pipeline_name, 
    last_processed_at
)
select 'customers_incremental_load',
        max(source_updated_at)
from staging.customers
on conflict(customer_id)
do update set 
    last_processed_at = excluded.last_processed_at
