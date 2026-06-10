SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROUND(AVG(
        DATEDIFF(
            STR_TO_DATE(o.order_delivered_customer_date, '%m/%d/%Y %H:%i'),
            STR_TO_DATE(o.order_purchase_timestamp, '%m/%d/%Y %H:%i')
        )
    ), 1) AS avg_delivery_days,
    ROUND(SUM(CASE 
        WHEN STR_TO_DATE(o.order_delivered_customer_date, '%m/%d/%Y %H:%i') 
             <= STR_TO_DATE(o.order_estimated_delivery_date, '%m/%d/%Y %H:%i')
        THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS on_time_pct
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;