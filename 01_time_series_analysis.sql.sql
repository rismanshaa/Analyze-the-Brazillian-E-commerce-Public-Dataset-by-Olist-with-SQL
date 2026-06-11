

SHOW TABLES;

SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'olist'
ORDER BY table_name, ordinal_position;

SELECT order_purchase_timestamp, order_delivered_customer_date, order_estimated_delivery_date
FROM orders
LIMIT 5;

-- THEME 1: Monthly Sales Trend
SELECT 
    YEAR(STR_TO_DATE(o.order_purchase_timestamp, '%m/%d/%Y %H:%i')) AS year,
    MONTH(STR_TO_DATE(o.order_purchase_timestamp, '%m/%d/%Y %H:%i')) AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY year, month
ORDER BY year, MONTH;


-- THEME 2: Delivery Performance
SELECT
    YEAR(STR_TO_DATE(o.order_purchase_timestamp, '%m/%d/%Y %H:%i')) AS year,
    MONTH(STR_TO_DATE(o.order_purchase_timestamp, '%m/%d/%Y %H:%i')) AS month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(
        DATEDIFF(
            STR_TO_DATE(o.order_delivered_customer_date, '%m/%d/%Y %H:%i'),
            STR_TO_DATE(o.order_purchase_timestamp, '%m/%d/%Y %H:%i')
        )
    ), 1) AS avg_delivery_days,
    ROUND(AVG(
        DATEDIFF(
            STR_TO_DATE(o.order_estimated_delivery_date, '%m/%d/%Y %H:%i'),
            STR_TO_DATE(o.order_delivered_customer_date, '%m/%d/%Y %H:%i')
        )
    ), 1) AS avg_days_early_late,
    ROUND(SUM(CASE 
        WHEN STR_TO_DATE(o.order_delivered_customer_date, '%m/%d/%Y %H:%i') 
             <= STR_TO_DATE(o.order_estimated_delivery_date, '%m/%d/%Y %H:%i')
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS on_time_pct
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY year, month
ORDER BY year, MONTH;



-- THEME 3: Customer Satisfaction
SELECT
    YEAR(STR_TO_DATE(o.order_purchase_timestamp, '%m/%d/%Y %H:%i')) AS year,
    MONTH(STR_TO_DATE(o.order_purchase_timestamp, '%m/%d/%Y %H:%i')) AS month,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    SUM(CASE WHEN r.review_score >= 4 THEN 1 ELSE 0 END) AS positive_reviews,
    SUM(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END) AS negative_reviews,
    ROUND(AVG(
        DATEDIFF(
            STR_TO_DATE(o.order_delivered_customer_date, '%m/%d/%Y %H:%i'),
            STR_TO_DATE(o.order_purchase_timestamp, '%m/%d/%Y %H:%i')
        )
    ), 1) AS avg_delivery_days
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY year, month
ORDER BY year, month;
