USE magist;

# What categories of tech products does Magist have?

SELECT DISTINCT 

    CASE 

        WHEN p.product_category_name IN ( 

            'computer_accessories', 

            'electronics', 

            'console_games', 

            'air_conditioning', 

            'audio', 

            'computers', 

            'computer accessories' 

            'music', 

            'tablets_printing_image', 

            'pc_gamer', 

            'telephony', 

            'fixed_telephony')  

        THEN 'Tech' 

        ELSE 'Non-tech' 

    END AS category_group, 

    p.product_category_name, 

    t.product_category_name_english 

FROM products p 

LEFT JOIN product_category_name_translation t 

    ON p.product_category_name = t.product_category_name 

ORDER BY category_group, p.product_category_name; 

# What’s the average price of the products being sold?

SELECT AVG(oi.price)
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered';

# Are expensive tech products popular?

SELECT
    CASE
        WHEN oi.price > 500 THEN 'expensive'
        ELSE 'cheap'
    END AS price_category,
    COUNT(*) AS number_of_products
FROM order_items oi
JOIN products p USING(product_id)
JOIN product_category_name_translation pt USING(product_category_name)
WHERE pt.product_category_name_english IN (
    'electronics',
    'computers',
    'computers_accessories',
    'pc_gamer',
    'audio',
    'telephony',
    'fixed_telephony',
    'tablets_printing_image'
)
GROUP BY price_category
ORDER BY number_of_products DESC;

# What’s the average time between the order being placed and the product being delivered?

SELECT 
    ROUND(AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date)), 2) AS avg_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

# How many orders are delivered on time vs orders delivered with a delay?

SELECT 
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'on_time'
        ELSE 'delayed'
    END AS delivery_status,
    COUNT(*) AS total_orders
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;

# Is there any pattern for delayed orders, e.g. big products being delayed more often?

SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'delayed'
        ELSE 'on_time'
    END AS delivery_status,
    ROUND(AVG(p.product_weight_g), 2) AS avg_weight
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;

# How many months of data are included in the magist database?

SELECT 
    TIMESTAMPDIFF(
        MONTH, 
        MIN(order_purchase_timestamp), 
        MAX(order_purchase_timestamp)
    ) AS total_months
FROM orders;

# How many sellers are there? How many Tech sellers are there? What percentage are Tech sellers?

SELECT COUNT(DISTINCT seller_id) AS total_sellers
FROM sellers;

SELECT 
    ROUND(
        (
            SELECT COUNT(DISTINCT s.seller_id)
            FROM sellers s
            JOIN order_items oi ON s.seller_id = oi.seller_id
            JOIN products p ON oi.product_id = p.product_id
            WHERE p.product_category_name IN (
                'electronics',
                'consoles_games',
                'computers',
                'tablets_printing_image',
                'pc_gamer',
                'telephony',
                'fixed_telephony'
            )
        ) * 100.0
        /
        (
            SELECT COUNT(DISTINCT seller_id)
            FROM sellers
        ),
    2) AS tech_seller_percentage;
    
    # What is the total amount earned by all sellers? What is the total amount earned by all Tech sellers?
    
SELECT
    CASE
        WHEN p.product_category_name IN (
            'electronics',
            'consoles_games',
            'computers',
            'tablets_printing_image',
            'pc_gamer',
            'telephony',
            'fixed_telephony'
        ) THEN 'Tech'
        ELSE 'Non-Tech'
    END AS product_type,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY product_type;

# Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?

# Umsatz pro Monat
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    SUM(oi.price + oi.freight_value) AS monthly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY month;

# Durchschnitt
SELECT 
    ROUND(AVG(monthly_revenue), 2) AS avg_monthly_income
FROM (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
        SUM(oi.price + oi.freight_value) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY month
) AS monthly_data;

# All Tech Sellers

SELECT 
    ROUND(AVG(monthly_revenue), 2) AS avg_monthly_income_tech
FROM (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
        SUM(oi.price + oi.freight_value) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE p.product_category_name IN (
        'electronics',
        'consoles_games',
        'computers',
        'tablets_printing_image',
        'pc_gamer',
        'telephony',
        'fixed_telephony'
    )
    GROUP BY month
) AS monthly_data;

# Revenue by time

SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS monthly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

# tech vs non tech revenue by time

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    CASE
        WHEN p.product_category_name IN (
            'electronics',
            'consoles_games',
            'computers',
            'tablets_printing_image',
            'pc_gamer',
            'telephony',
            'fixed_telephony'
        ) THEN 'Tech'
        ELSE 'Non-Tech'
    END AS product_type,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS monthly_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY month, product_type
ORDER BY month, product_type;




SELECT 
    r.review_comment_message,
    COUNT(*) AS frequency,

    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
        THEN 'Delayed'
        ELSE 'On Time'
    END AS delay_status

FROM order_reviews r
JOIN orders o
ON r.order_id = o.order_id

WHERE r.review_score <= 2
AND r.review_comment_message IS NOT NULL

GROUP BY r.review_comment_message, delay_status

ORDER BY frequency DESC

LIMIT 5;


SELECT 
    'Did not receive product' AS issue,
    COUNT(*) AS frequency,

    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
        THEN 'Delayed'
        ELSE 'On Time'
    END AS delay_status

FROM order_reviews r
JOIN orders o
ON r.order_id = o.order_id

WHERE r.review_score <= 2
AND r.review_comment_message LIKE '%recebi%'

GROUP BY delay_status
ORDER BY frequency DESC;



SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Delayed'
        ELSE 'On Time'
    END AS delay_status,
    
    COUNT(DISTINCT r.order_id) AS reviewed_orders,
    
    COUNT(DISTINCT CASE
        WHEN r.review_score <= 2 THEN r.order_id
    END) AS negative_review_orders,
    
    ROUND(
        COUNT(DISTINCT CASE
            WHEN r.review_score <= 2 THEN r.order_id
        END) * 100.0 / COUNT(DISTINCT r.order_id),
        2
    ) AS negative_review_rate_percent

FROM orders o
JOIN order_reviews r
    ON o.order_id = r.order_id

GROUP BY delay_status;




-- GEO Analysis

SELECT 
    g.state,
    SUM(oi.price) AS total_revenue
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN geo g
    ON c.customer_zip_code_prefix = g.zip_code_prefix
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY g.state
ORDER BY total_revenue DESC;


-- GEO Revenue per Order

SELECT 
    g.state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.price) AS total_revenue,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS revenue_per_order
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN geo g
    ON c.customer_zip_code_prefix = g.zip_code_prefix
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY g.state
ORDER BY revenue_per_order DESC;


-- Geo Delay Rate

SELECT 
    g.state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    
    SUM(
        CASE 
            WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
            THEN 1 
            ELSE 0 
        END
    ) AS delayed_orders,

    ROUND(
        SUM(
            CASE 
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
                THEN 1 
                ELSE 0 
            END
        ) * 100.0 / COUNT(DISTINCT o.order_id),
        2
    ) AS delay_rate_percent,

    SUM(oi.price) AS total_revenue

FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN geo g
    ON c.customer_zip_code_prefix = g.zip_code_prefix
JOIN order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY g.state;