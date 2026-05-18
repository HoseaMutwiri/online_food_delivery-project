
-- command to check the number of records in each table after loading data


select count(*) from online_p.customers;
select count(*) from online_p.delivery_agents;
select count(*) from online_p.restaurant;
select count(*) from online_p.orders;
select count(*) from online_p.order_items;

/* PHASE 1 —EXPLORATORY ANALYSIS
The company wants to know:
1.Total Revenue
2. Total Orders Per City
3. Top 10 Customers by Spending
*/


-- 1.Total Revenue
SELECT ROUND(SUM(order_amount)::numeric,2) AS total_revenue
FROM online_p.orders;

-- 2. Total Orders Per City
SELECT r.city, COUNT(o.order_id) AS total_orders
FROM online_p.orders o
JOIN online_p.restaurant r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city;

-- 3. Top 10 Customers by Spending

SELECT c.name AS customer_name, ROUND(SUM(o.order_amount)::numeric,2) AS total_spent
FROM online_p.orders o
JOIN online_p.customers c ON o.customer_id = c.customer_id
GROUP BY c.name
ORDER BY total_spent DESC
LIMIT 10;

/*PHASE 2 — CUSTOMER SEGMENTATION
1. Customer Category (Gold/Silver/Bronze)
*/

-- 1. Customer Category (Gold/Silver/Bronze)
WITH customer_spending AS (
    SELECT c.customer_id, c.name, ROUND(SUM(o.order_amount)::numeric,2) AS total_spent
    FROM online_p.orders o
    JOIN online_p.customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.name
)
SELECT customer_id, name, total_spent,
    CASE
        WHEN total_spent >= 1500 THEN 'Gold'
        WHEN total_spent >= 500 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_category
FROM customer_spending
ORDER BY total_spent DESC;

/*PHASE 3 — RESTAURANT PERFORMANCE
1.Top 10 Restaurants by Revenue
2. Average Rating vs Revenue
*/

-- 1.Top 10 Restaurants by Revenue
SELECT r.restaurant_name, ROUND(SUM(o.order_amount)::numeric,2) AS total_revenue
FROM online_p.orders o
JOIN online_p.restaurant r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name
ORDER BY total_revenue DESC
LIMIT 10;

-- 2. Average Rating vs Revenue
SELECT r.restaurant_name, r.rating, ROUND(SUM(o.order_amount)::numeric,2) AS total_revenue
FROM online_p.orders o
JOIN online_p.restaurant r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name, r.rating
ORDER BY total_revenue DESC;


/*PHASE 4 — DELIVERY ANALYSIS
1. Average Delivery Time Per City
2.Late Deliveries (Above 45 Minutes)
*/

-- 1. Average Delivery Time Per City
 
SELECT r.city, ROUND(AVG(o.delivery_time)::numeric,2) AS avg_delivery_time_minutes
FROM online_p.orders o
JOIN online_p.restaurant r ON o.restaurant_id = r.restaurant_id
WHERE o.delivery_time IS NOT NULL
GROUP BY r.city
ORDER BY avg_delivery_time_minutes;

-- 2.Late Deliveries (Above 45 Minutes)
SELECT o.order_id, r.restaurant_name, o.delivery_time
FROM online_p.orders o
JOIN online_p.restaurant r ON o.restaurant_id = r.restaurant_id
WHERE o.delivery_time > 45
ORDER BY o.delivery_time DESC;

/*PHASE 5 — PAYMENT & DISCOUNT ANALYSIS
1.Payment Method Distribution
2. Discount Impact on Revenue
*/

-- 1.Payment Method Distribution
SELECT
payment_method,
order_amount, 
COUNT(order_id) over(PARTITION BY payment_method) AS total_orders_by_payment_method
FROM online_p.orders
ORDER BY order_amount DESC;    

-- 2. Discount Impact on Revenue
SELECT
CASE
    WHEN discount > 0 THEN 'With Discount'
    ELSE 'Without Discount'
END AS discount_status,
ROUND(SUM(order_amount)::numeric,2) AS total_revenue
FROM online_p.orders
GROUP BY discount_status
ORDER BY total_revenue DESC;

/*PHASE 6 — ADVANCED SQL
1.Monthly Revenue Using CTE
2.Rank Restaurants by Revenue (Window Function)
3.Above Average Revenue Restaurants (Subquery)*/

-- 1.Monthly Revenue Using CTE
WITH monthly_revenue AS (
    SELECT
    TO_CHAR(order_date::DATE,'Month') AS month,
    ROUND(SUM(order_amount)::numeric,2) AS total_revenue
    FROM online_p.orders
    GROUP BY month
)
SELECT month, total_revenue
FROM monthly_revenue
ORDER BY total_revenue DESC;


-- 2.Rank Restaurants by Revenue (Window Function)
SELECT
    r.restaurant_name,
    ROUND(SUM(o.order_amount)::numeric,2) AS total_revenue,
    RANK() OVER (ORDER BY SUM(o.order_amount) DESC) AS revenue_rank
FROM online_p.orders o
JOIN online_p.restaurant r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name
ORDER BY total_revenue DESC;

-- 3.Above Average Revenue Restaurants (Subquery)
SELECT
    r.restaurant_name,
    ROUND(SUM(o.order_amount)::numeric,2) AS total_revenue
FROM online_p.orders o
JOIN online_p.restaurant r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name
HAVING SUM(o.order_amount) > (
    SELECT AVG(order_amount)
    FROM online_p.orders
)
ORDER BY total_revenue DESC;

/*PHASE 7 — DATABASE OBJECTS
1.Create Revenue View
2.Stored Procedure: Get Top N Restaurant*/

-- 1.Create Revenue View
CREATE OR REPLACE VIEW online_p.restaurant_revenue AS
SELECT
    r.restaurant_name,
    ROUND(SUM(o.order_amount)::numeric,2) AS total_revenue
FROM online_p.orders o
JOIN online_p.restaurant r ON o.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name;


SELECT * FROM online_p.restaurant_revenue
ORDER BY total_revenue DESC;

-- 2.Stored Procedure: Get Top N Restaurant
CREATE OR REPLACE FUNCTION online_p.get_top_n_restaurants(n INT) 
RETURNS TABLE(restaurant_name VARCHAR, total_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.restaurant_name::VARCHAR,
        ROUND(SUM(o.order_amount)::numeric,2) AS total_revenue
    FROM online_p.orders o
    JOIN online_p.restaurant r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_name
    ORDER BY 2 DESC
    LIMIT n;
END;
$$ LANGUAGE plpgsql;

-- Example usage: Get top 5 restaurants by revenue
SELECT * FROM online_p.get_top_n_restaurants(5);


/*PHASE 8-- Performance Optimization
Index on order_date (for monthly reports)
Index on customer_name (for joins)
Index on restaurant_name (for joins)*/

-- Index on order_date (for monthly reports)

CREATE INDEX idx_order_date ON online_p.orders(order_date);

-- Index on customer_name (for joins)

CREATE INDEX idx_customer_name ON online_p.customers(name);

-- Index on restaurant_name (for joins)

CREATE INDEX idx_restaurant_name ON online_p.restaurant(restaurant_name);

-- After creating indexes, you can analyze the query performance using EXPLAIN ANALYZE to see the improvements.

EXPLAIN ANALYZE
SELECT * FROM online_p.orders WHERE order_date >= '2024-01-01' AND order_date < '2024-02-01';

/*PHASE 9 —Automation Logic
TRIGGER 1 — Prevent Negative Discount
TRIGGER 2 — Delivery Delay Warning

*/

-- TRIGGER 1 — Prevent Negative Discount
CREATE OR REPLACE FUNCTION online_p.prevent_negative_discount()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.discount < 0 THEN
        RAISE EXCEPTION 'Discount cannot be negative';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_negative_discount
    BEFORE INSERT OR UPDATE ON online_p.orders
    FOR EACH ROW
    EXECUTE FUNCTION online_p.prevent_negative_discount();


-- test the trigger by trying to insert a record with a negative discount

INSERT INTO online_p.orders (order_date, customer_id, restaurant_id, order_amount, discount)
VALUES ('2024-01-15', 1, 1, 100.00, -10.00);

-- TRIGGER 2 — Delivery Delay Warning
CREATE OR REPLACE FUNCTION online_p.delivery_delay_warning()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.delivery_time > 45 THEN
        RAISE WARNING 'Delivery time exceeds 45 minutes for order ID: %', NEW.order_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_delivery_delay_warning
    BEFORE INSERT OR UPDATE ON online_p.orders
    FOR EACH ROW
    EXECUTE FUNCTION online_p.delivery_delay_warning();


-- test the trigger by trying to insert a record with a delivery time greater than 45 minutes

INSERT INTO online_p.orders (order_date,
    customer_id,
    restaurant_id,
    order_amount,
    delivery_time,
    order_id,
    payment_method,
    discount)
VALUES ('2024-01-15', 1, 1, 100.00, 50,700,'cash',10);
