SELECT
    ct.product_category_name_english AS category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROUND(AVG(
        DATEDIFF(
            STR_TO_DATE(o.order_delivered_customer_date, '%m/%d/%Y %H:%i'),
            STR_TO_DATE(o.order_purchase_timestamp, '%m/%d/%Y %H:%i')
        )
    ), 1) AS avg_delivery_days
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN category_translation ct ON p.product_category_name = ct.product_category_name
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND ct.product_category_name_english IS NOT NULL
GROUP BY ct.product_category_name_english
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY avg_review_score DESC;
