WITH YearlyPayments AS (
    SELECT
        EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
        op.payment_type,
        COUNT(op.order_id) AS yearly_count,
        SUM(op.payment_value) AS yearly_value
    FROM
        order_payments_dataset op
    JOIN
        orders_dataset o ON op.order_id = o.order_id
    WHERE op.payment_type <> 'not_defined'
    GROUP BY
        EXTRACT(YEAR FROM o.order_purchase_timestamp),
        op.payment_type
),

TotalPayments AS (
    SELECT
        payment_type,
        COUNT(order_id) AS total_count,
        SUM(payment_value) AS total_value
    FROM
        order_payments_dataset
    GROUP BY
        payment_type
)

SELECT
    yp.year,
    yp.payment_type,
    yp.yearly_count,
    tp.total_count,
    ROUND(yp.yearly_value,2) AS yearly_value,
    ROUND(tp.total_value,2) AS total_value
FROM
    YearlyPayments yp
JOIN
    TotalPayments tp ON yp.payment_type = tp.payment_type
ORDER BY
    tp.total_count DESC, yp.year, yp.payment_type;
