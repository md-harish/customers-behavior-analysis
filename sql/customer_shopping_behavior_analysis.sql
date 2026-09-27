-- Customer Shopping Behavior - SQL queries
-- table: customer_shopping_behavior (SQL Server, customer_behavior db)

-- quick check
select count(*) as total_customers from customer_shopping_behavior;

select top 10 * from customer_shopping_behavior;

-- how many purchases per category
select category, count(*) as num_purchases
from customer_shopping_behavior
group by category
order by num_purchases desc;


-- revenue stuff

select category, count(*) as num_purchases, sum(purchase_amount) as total_revenue, avg(purchase_amount) as avg_purchase_amount
from customer_shopping_behavior
group by category
order by total_revenue desc;

-- revenue by age group
select age_group, count(*) as num_customers, sum(purchase_amount) as total_revenue, avg(purchase_amount) as avg_purchase_amount
from customer_shopping_behavior
group by age_group
order by total_revenue desc;

select gender, subscription_status, count(*) as num_customers, sum(purchase_amount) as total_revenue
from customer_shopping_behavior
group by gender, subscription_status
order by gender, subscription_status;


-- loyalty / how often people buy

select category, avg(purchase_frequency_days) as avg_days_between_purchases
from customer_shopping_behavior
group by category
order by avg_days_between_purchases;

-- top 10 most loyal customers
select top 10 customer_id, previous_purchases, purchase_amount, category
from customer_shopping_behavior
order by previous_purchases desc;


-- window functions

-- rank customers by spend inside their own category
select customer_id, category, purchase_amount,
	rank() over (partition by category order by purchase_amount desc) as spend_rank_in_category
from customer_shopping_behavior;

-- running total of revenue (just going by customer_id order, not real dates)
select customer_id, purchase_amount,
	sum(purchase_amount) over (order by customer_id rows between unbounded preceding and current row) as running_total
from customer_shopping_behavior;

select customer_id, purchase_amount,
	percent_rank() over (order by purchase_amount) as spend_percentile
from customer_shopping_behavior;

-- compare each customer to the one before them
select customer_id, purchase_amount,
	lag(purchase_amount, 1) over (order by customer_id) as prev_customer_spend,
	purchase_amount - lag(purchase_amount, 1) over (order by customer_id) as spend_diff
from customer_shopping_behavior;


-- CTEs / subqueries

-- customers spending above the overall average
with avg_spend as (
	select avg(purchase_amount) as overall_avg
	from customer_shopping_behavior
)
select c.customer_id, c.purchase_amount, a.overall_avg
from customer_shopping_behavior c
cross join avg_spend a
where c.purchase_amount > a.overall_avg
order by c.purchase_amount desc;

-- categories doing better than the average category revenue
with category_summary as (
	select category, sum(purchase_amount) as total_revenue, avg(review_rating) as avg_rating
	from customer_shopping_behavior
	group by category
)
select * from category_summary
where total_revenue > (select avg(total_revenue) from category_summary)
order by total_revenue desc;

-- customers rated below their category's average rating
select customer_id, category, review_rating
from customer_shopping_behavior c
where review_rating < (
	select avg(review_rating)
	from customer_shopping_behavior c2
	where c2.category = c.category
)
order by category, review_rating;


-- discounts / shipping / payment

select discount_applied, count(*) as num_purchases, avg(purchase_amount) as avg_purchase_amount
from customer_shopping_behavior
group by discount_applied;

select shipping_type, count(*) as num_orders, avg(purchase_amount) as avg_purchase_amount
from customer_shopping_behavior
group by shipping_type
order by num_orders desc;

select payment_method, count(*) as num_orders, sum(purchase_amount) as total_revenue
from customer_shopping_behavior
group by payment_method
order by total_revenue desc;
