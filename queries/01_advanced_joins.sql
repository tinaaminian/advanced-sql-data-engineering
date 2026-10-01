-- ==========================================================================
-- Return all orders whose customer_id does not exist in source.customers
-- ==========================================================================
select o.order_id,o.customer_id, o.order_status, o.order_date,
c.first_name, c.last_name,c.customer_id  
from source.ordrs o 
left join source.customers c 
on o.customer_id  = c.customer_id 
where c.customer_id is null

-- ==========================================================================
-- For all customers calculate total_order_amount = sum(quantity * unit_price)
-- ==========================================================================
with order_amount as (
 select  o.customer_id, sum(quantity*unit_price) as total_order_amount 
 from source.ordrs o 
 inner join source.order_items oi 
 on o.order_id = oi.order_id 
 group by o.customer_id
),
payment_amount as (
	select p.customer_id, sum(p.payment_amount) as total_payment_amount
	from source.payments as p
	group by p.customer_id
)
select c.customer_id, c.first_name, c.last_name,
coalesce(ot.total_order_amount, 0) as total_order_amount,
coalesce(pa.total_payment_amount, 0) as total_payment_amount
from source.customers c 
left join order_amount as ot 
on ot.customer_id = c.customer_id 
left join payment_amount as pa 
on pa.customer_id = c.customer_id 
order by c.customer_id 

-- ==========================================================================
-- For each order, find the customer's address that was valid on the date the
--order was placed.
-- ==========================================================================
select ca.address_id, ca.customer_id,
ca.city, ca.province, ca.valid_from, ca.valid_to,
o.order_date, o.order_status 
from source.ordrs o 
left join source.customer_addresses ca 
on ca.customer_id  = o.customer_id 
and 
o.order_date::DATE >= ca.valid_from
and 
(o.order_date::DATE <= ca.valid_to or ca.valid_to is null)
order by ca.customer_id 

-- =======================================================================
-- Show every employee together with their manager.
-- =======================================================================
select e.employee_id , e.employee_name as employee , m.employee_name as employer
from source.employees e 
left join source.employees m
on e.manager_id  = m.employee_id 

-- =======================================================================
-- Create a reconciliation result showing which order IDs exist in:
--1. Both orders and payments
--2. Orders only
--3. Payments only
-- =======================================================================
select o.order_id, o.order_status, p.payment_id, p.payment_amount,
    CASE
        WHEN p.order_id IS NULL THEN 'ORDER_ONLY'
        WHEN o.order_id IS NULL THEN 'PAYMENT_ONLY'
        ELSE 'MATCHED'
    END AS reconciliation_status

from source.ordrs AS o
full outer join source.payments AS p
    on o.order_id = p.order_id
order by order_id;

-- =======================================================================
-- Return customers who have at least one order where: order_status = 'COMPLETED'
-- =======================================================================

select  c.customer_id,c.first_name, c.last_name
from source.customers c 
where exists(
	select 1 
	from source.ordrs as o 
	where c.customer_id = o.customer_id 
	and o.order_status = 'COMPLETED'
)

-- =======================================================================
--For every payment, show:
--- payment_id
--- customer_id
--- payment_amount
--- customer's total_payment_amount
--- customer's average_payment_amount

--Then return ONLY payments whose payment_amount is greater than that
--customer's average payment amount.
-- =======================================================================
with payments as (
	select p.payment_id , p.customer_id , p.payment_amount,
	sum(p.payment_amount) over(partition by p.customer_id ) as customers_total_payment,
	avg(p.payment_amount) over(partition by p.customer_id) as customer_average_payment
	from source.payments as p
)
select * 
from payments 
where payment_amount > customer_average_payment 

-- =======================================================================
--For each customer, return:
-- customer_id
-- total_orders
-- completed_orders
-- cancelled_orders
-- completed_order_percentage
-- =======================================================================
select o.customer_id , 
count(*) as total_orders,
count(*) filter (where o.order_status = 'COMPLETED') as completed_orders,
count(*) filter (where o.order_status = 'CANCELLED' ) as cancelled_orders,
100.00 * count(*) filter (where o.order_status = 'COMPLETED')  / count(*)  as completed_order_percentage
from source.ordrs o 
group by o.customer_id