-- ==========================================================================
-- Return the 2 largest payments for each customer.
-- ==========================================================================

with ranked_payments as(
	select p.customer_id , p.payment_id, p.payment_amount ,
	row_number() over(partition by p.customer_id order by p.payment_amount desc) as payment_rank
	from source.payments p 
)
select * 
from ranked_payments 
where payment_rank < 3

-- ==========================================================================
--For every SUCCESS payment, return:
-- customer_id
-- payment_id
-- payment_date
-- payment_amount
-- running_payment_total
-- ==========================================================================
select p.customer_id , 
p.payment_id ,
p.payment_date ::DATE as payment_date,
p.payment_amount,
sum(p.payment_amount) 
over(partition by p.customer_id
order by p.payment_date::DATE, p.payment_id
rows between UNBOUNDED PRECEDING AND CURRENT ROW) as running_payment_total
from source.payments p 
where p.payment_status  = 'SUCCESS'


-- =========================================================================
--BUSINESS REQUIREMENT:
--For every SUCCESS payment, return:
-- customer_id
-- payment_id
-- payment_date
-- payment_amount
-- previous_payment_amount
-- payment_amount_change

--Where:
    --payment_amount_change = current payment_amount - previous payment_amount
--===========================================================================
select p.customer_id , 
p.payment_id , p.payment_date, p.payment_amount,
lag(p.payment_amount) 
over(partition by p.customer_id 
order by p.payment_date , p.payment_id) as previous_amount,
p.payment_amount - lag(p.payment_amount) 
over(partition by p.customer_id 
order by p.payment_date , p.payment_id) as payment_change
from source.payments as p 
where p.payment_status = 'SUCCESS'


--===========================================================================
--For every event, return:
-- user_id
-- event_id
-- event_type
-- event_time
-- next_event_time
-- minutes_until_next_event
--===========================================================================
select e.event_id ,
e.customer_id ,
e.event_type ,
e.event_time ,
lead(e.event_time)
over(partition by e.customer_id order by e.event_time , e.event_id) as next_event_time,
lead(e.event_time) over(partition by e.customer_id  order by e.event_time , e.event_id) - e.event_time  as minutes_until_next
from source.events e 


--===========================================================================
--For every SUCCESS payment, return:

-- customer_id
-- payment_id
-- payment_date
-- payment_amount
-- three_payment_moving_average

--The moving average should include:
-- the current payment
-- the previous 2 payments

--The moving average should include: the current payment
-- the previous 2 payments
--===========================================================================
select p.payment_id , p.customer_id ,p.payment_date, 
p.payment_amount ,
avg(p.payment_amount)
over(partition by p.customer_id
order by p.payment_date, p.payment_id
rows between 2 preceding and current row) as moving_average
from source.payments p 
WHERE p.payment_status = 'SUCCESS'


--===========================================================================
-- For every SUCCESS payment, return:
-- customer_id
-- payment_id
-- payment_date
-- payment_amount
-- - first_payment_amount
-- latest_payment_amount
--===========================================================================
select p.payment_id , p.customer_id ,p.payment_date, 
p.payment_amount ,
first_value(p.payment_amount)
over(partition by p.customer_id 
order by p.payment_date , p.payment_id 
) as first_payment_amount,
last_value(p.payment_amount) 
over(partition by p.customer_id 
order by p.payment_date, p.payment_id
ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
) as latest_payment_amount
from source.payments p 
WHERE p.payment_status = 'SUCCESS'

--===========================================================================
--Calculate each customer's total successful payment amount, then divide
--customers into 4 groups (quartiles) based on that total.
--===========================================================================
SELECT
    p.customer_id,
    SUM(p.payment_amount) AS total_payment_amount,
    NTILE(4) OVER (
        ORDER BY SUM(p.payment_amount) DESC
    ) AS payment_quartile
FROM source.payments AS p
WHERE p.payment_status = 'SUCCESS'
GROUP BY p.customer_id;
