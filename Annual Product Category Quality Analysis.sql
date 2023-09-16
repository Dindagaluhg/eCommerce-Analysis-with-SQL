-- revenue per tahun
SELECT 
    EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
    ROUND(SUM(price + freight_value),2) AS total_revenue
FROM
    orders_dataset od 
join 
	order_items_dataset oid 
on oid.order_id = od.order_id 
where od.order_status = 'delivered'
GROUP BY
    EXTRACT(YEAR FROM order_purchase_timestamp)
ORDER BY
    year;

-- jumlah cancel order per tahun   
SELECT 
    EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
    COUNT(order_id) AS cancel_orders_count
FROM
    orders_dataset
WHERE
    order_status = 'canceled'
GROUP BY
    EXTRACT(YEAR FROM order_purchase_timestamp)
ORDER BY
    year;
   
-- top kategori yang menghasilkan revenue terbesar per tahun
WITH RankedCategories AS (
    SELECT 
        EXTRACT(YEAR FROM od.order_purchase_timestamp) AS year,
        pd.product_category_name,
        ROUND(SUM(oid.price + oid.freight_value),2) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM od.order_purchase_timestamp) ORDER BY ROUND(SUM(oid.price + oid.freight_value),2) DESC) AS ranking
    FROM
        orders_dataset od
    JOIN 
        order_items_dataset oid 
    ON 
        oid.order_id = od.order_id 
    JOIN 
        product_dataset pd
    ON 
        oid.product_id = pd.product_id
    WHERE 
        od.order_status = 'delivered'
    GROUP BY
        EXTRACT(YEAR FROM od.order_purchase_timestamp),
        pd.product_category_name
)

SELECT 
    year,
    product_category_name,
    total_revenue
FROM
    RankedCategories
WHERE
    ranking = 1
ORDER BY
    year;


-- kategori yang mengalami cancel order terbanyak per tahun
WITH CanceledOrders AS (
    SELECT 
        EXTRACT(YEAR FROM od.order_purchase_timestamp) AS year,
        pd.product_category_name,
        COUNT(od.order_id) AS cancel_count,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM od.order_purchase_timestamp) ORDER BY COUNT(od.order_id) DESC) AS ranking
    FROM
        orders_dataset od 
    JOIN 
        order_items_dataset oid 
    ON 
        od.order_id = oid.order_id 
    JOIN 
        product_dataset pd
    ON 
        oid.product_id = pd.product_id
    WHERE 
        od.order_status = 'canceled'
    GROUP BY
        EXTRACT(YEAR FROM od.order_purchase_timestamp),
        pd.product_category_name
)

SELECT 
    year,
    product_category_name,
    cancel_count
FROM
    CanceledOrders
WHERE
    ranking = 1
ORDER BY
    year;
   
   
-- Menggabungkan semua hasil
WITH RevenuePerYear AS (
    -- revenue per tahun
    SELECT 
        EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
        ROUND(SUM(price + freight_value),2) AS total_revenue
    FROM
        orders_dataset od 
    JOIN 
        order_items_dataset oid 
    ON oid.order_id = od.order_id 
    WHERE od.order_status = 'delivered'
    GROUP BY
        EXTRACT(YEAR FROM order_purchase_timestamp)
),
CancelOrderPerYear AS (
    -- jumlah cancel order per tahun
    SELECT 
        EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
        COUNT(order_id) AS cancel_orders_count
    FROM
        orders_dataset
    WHERE
        order_status = 'canceled'
    GROUP BY
        EXTRACT(YEAR FROM order_purchase_timestamp)
),
TopCategoryPerYear AS (
    -- subquery untuk menghitung revenue dan ranking
    WITH RankedRevenue AS (
        SELECT 
            EXTRACT(YEAR FROM od.order_purchase_timestamp) AS year,
            pd.product_category_name,
            ROUND(SUM(oid.price + oid.freight_value),2) AS total_revenue,
            ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM od.order_purchase_timestamp) ORDER BY ROUND(SUM(oid.price + oid.freight_value),2) DESC) AS ranking
        FROM
            orders_dataset od
        JOIN 
            order_items_dataset oid 
        ON 
            oid.order_id = od.order_id 
        JOIN 
            product_dataset pd
        ON 
            oid.product_id = pd.product_id
        WHERE 
            od.order_status = 'delivered'
        GROUP BY
            EXTRACT(YEAR FROM od.order_purchase_timestamp),
            pd.product_category_name
    )
    SELECT 
        year,
        product_category_name AS top_category_revenue,
        total_revenue AS top_category_revenue_amount
    FROM 
        RankedRevenue
    WHERE 
        ranking = 1
),
MostCanceledCategoryPerYear AS (
    -- subquery untuk menghitung cancel count dan ranking
    WITH RankedCancel AS (
        SELECT 
            EXTRACT(YEAR FROM od.order_purchase_timestamp) AS year,
            pd.product_category_name,
            COUNT(od.order_id) AS cancel_count,
            ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM od.order_purchase_timestamp) ORDER BY COUNT(od.order_id) DESC) AS ranking
        FROM
            orders_dataset od 
        JOIN 
            order_items_dataset oid 
        ON 
            od.order_id = oid.order_id 
        JOIN 
            product_dataset pd
        ON 
            oid.product_id = pd.product_id
        WHERE 
            od.order_status = 'canceled'
        GROUP BY
            EXTRACT(YEAR FROM od.order_purchase_timestamp),
            pd.product_category_name
    )
    SELECT 
        year,
        product_category_name AS most_canceled_category,
        cancel_count AS most_canceled_count
    FROM 
        RankedCancel
    WHERE 
        ranking = 1
)
SELECT
    r.year,
    r.total_revenue,
    c.cancel_orders_count,
    t.top_category_revenue,
    t.top_category_revenue_amount,
    m.most_canceled_category,
    m.most_canceled_count
FROM
    RevenuePerYear r
JOIN
    CancelOrderPerYear c ON r.year = c.year
JOIN
    TopCategoryPerYear t ON r.year = t.year
JOIN
    MostCanceledCategoryPerYear m ON r.year = m.year
ORDER BY
    r.year;

