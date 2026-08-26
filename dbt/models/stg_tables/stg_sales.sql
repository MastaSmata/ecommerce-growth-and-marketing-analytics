WITH deduped AS (
    SELECT
        TRIM(order_id) AS order_id,
        TRIM(customer_id) AS customer_id,

        LOWER(TRIM(customer_status)) AS customer_status,

        TRIM(product_id) AS product_id,
        LOWER(TRIM(product_name)) AS product_name,
        LOWER(TRIM(category)) AS category,

        LOWER(TRIM(ship_mode)) AS ship_mode,

        SAFE_CAST(quantity AS INT64) AS quantity,
        SAFE_CAST(discount AS NUMERIC) AS discount,
        SAFE_CAST(unit_cost AS NUMERIC) AS unit_cost,
        SAFE_CAST(price AS NUMERIC) AS price,
        SAFE_CAST(revenue AS NUMERIC) AS revenue,

        LOWER(TRIM(refund_status)) AS refund_status,

        SAFE_CAST(order_date AS DATE) AS order_date,

        LOWER(TRIM(channel)) AS channel,

        TRIM(campaign_id) AS campaign_id,

        -- Incremental loads use WRITE_APPEND, so a retried or rerun batch
        -- can insert the same order twice. Keep only the most recently
        -- ingested copy of each order_id
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(order_id)
            ORDER BY _ingested_at DESC
        ) AS _row_num

    FROM {{ source('raw', 'raw_sales') }}
)

SELECT
    order_id,
    customer_id,
    customer_status,
    product_id,
    product_name,
    category,
    ship_mode,
    quantity,
    discount,
    unit_cost,
    price,
    revenue,
    refund_status,
    order_date,
    channel,
    campaign_id

FROM deduped
WHERE _row_num = 1