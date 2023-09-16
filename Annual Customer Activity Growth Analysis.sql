WITH 
MonthlyActiveUsers AS (
    SELECT
        EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
        EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
        COUNT(DISTINCT customer_id) AS MAU
    FROM
        orders_dataset
    GROUP BY 1,2   
),
FirstPurchaseYear AS (
    SELECT
        cd.customer_unique_id,
        EXTRACT(YEAR FROM MIN(order_purchase_timestamp)) AS first_year
    FROM
        orders_dataset od 
    JOIN customers_dataset cd 
    	on od.customer_id = cd.customer_id 
    GROUP BY 1
),
YearlyOrderCounts AS (
    SELECT
        customer_unique_id,
        EXTRACT(YEAR FROM order_purchase_timestamp) AS order_year,
        COUNT(DISTINCT order_purchase_timestamp) AS order_count
    FROM
        orders_dataset od 
    JOIN customers_dataset cd 
    ON od.customer_id = cd.customer_id 
    GROUP BY
        customer_unique_id,
        EXTRACT(YEAR FROM order_purchase_timestamp)
),
YearlyOrderFrequency AS (
    SELECT
        EXTRACT(YEAR FROM order_purchase_timestamp) AS order_year,
        COUNT(DISTINCT order_purchase_timestamp) AS order_count
    FROM
        orders_dataset od 
    JOIN customers_dataset cd 
    ON od.customer_id = cd.customer_id 
    GROUP BY
        customer_unique_id,
        EXTRACT(YEAR FROM order_purchase_timestamp)
)

-- Menggabungkan semua hasil
SELECT 
    mau.year,
    FLOOR(AVG(mau.MAU)) AS average_MAU,
    fpy.total_new_customers,
    yoc.repeat_customers,
    yof.average_order_frequency
FROM
    MonthlyActiveUsers mau
LEFT JOIN (
    SELECT
        first_year,
        COUNT(customer_unique_id) AS total_new_customers
    FROM
        FirstPurchaseYear
    GROUP BY
        first_year
) fpy ON mau.year = fpy.first_year
LEFT JOIN (
    SELECT
        order_year,
        COUNT(DISTINCT customer_unique_id) AS repeat_customers
    FROM
        YearlyOrderCounts
    WHERE
        order_count > 1
    GROUP BY
        order_year
) yoc ON mau.year = yoc.order_year
LEFT JOIN (
    SELECT 
        order_year,
        AVG(order_count) AS average_order_frequency
    FROM
        YearlyOrderFrequency
    GROUP BY order_year
) yof ON mau.year = yof.order_year
GROUP BY
    mau.year, fpy.total_new_customers, yoc.repeat_customers, yof.average_order_frequency
ORDER BY
    mau.year;
