{{ config(
    materialized='table'
) }}

WITH customer_orders AS (

    SELECT

        customer_id,

        MIN(DATE(order_date)) AS first_purchase_date,

        MAX(DATE(order_date)) AS latest_purchase_date,

        COUNT(DISTINCT order_id) AS lifetime_orders,

        -- Refunded orders excluded from lifetime revenue for the same
        -- reason as the aggregate tables (see audit P1.10) — this
        -- dimension attribute wasn't covered by that original fix.
        SUM(CASE WHEN refund_status != 'refunded' THEN revenue END)
            AS lifetime_revenue

    FROM {{ ref('stg_sales') }}

    GROUP BY customer_id

)

SELECT

    --------------------------------------------------
    -- SURROGATE KEY
    --------------------------------------------------

    {{ dbt_utils.generate_surrogate_key([
        'customers.customer_id'
    ]) }} AS customer_key,

    --------------------------------------------------
    -- BUSINESS KEY
    --------------------------------------------------

    customers.customer_id,

    --------------------------------------------------
    -- DEMOGRAPHICS
    --------------------------------------------------

    LOWER(TRIM(customers.gender)) AS gender,

    customers.age,

    CASE

        WHEN customers.age < 18 THEN 'Under 18'

        WHEN customers.age BETWEEN 18 AND 24 THEN '18-24'

        WHEN customers.age BETWEEN 25 AND 34 THEN '25-34'

        WHEN customers.age BETWEEN 35 AND 44 THEN '35-44'

        WHEN customers.age BETWEEN 45 AND 54 THEN '45-54'

        ELSE '55+'

    END AS age_band,

    LOWER(TRIM(customers.country)) AS country,

    LOWER(TRIM(customers.region)) AS region,

    LOWER(TRIM(customers.city)) AS city,

    --------------------------------------------------
    -- ACQUISITION ATTRIBUTES
    --------------------------------------------------

    customers.acquisition_date,

    LOWER(TRIM(customers.acquisition_channel))
        AS acquisition_channel,

    LOWER(TRIM(customers.acquisition_campaign))
        AS acquisition_campaign,

    --------------------------------------------------
    -- CUSTOMER LIFECYCLE
    --------------------------------------------------

    customer_orders.first_purchase_date,

    customer_orders.latest_purchase_date,

    customer_orders.lifetime_orders,

    customer_orders.lifetime_revenue,

    --------------------------------------------------
    -- CUSTOMER STATUS
    --------------------------------------------------

    CASE

        WHEN customer_orders.lifetime_orders IS NULL
            THEN 'prospect'

        WHEN customer_orders.lifetime_orders = 1
            THEN 'new'

        ELSE 'returning'

    END AS customer_status,

    --------------------------------------------------
    -- AUDIT
    --------------------------------------------------

    CURRENT_TIMESTAMP() AS loaded_at

FROM {{ ref('stg_customers') }} AS customers

LEFT JOIN customer_orders

    ON customers.customer_id = customer_orders.customer_id

UNION ALL

-- Unknown customer member (see audit P1.8) — used when a sales row's
-- customer_id has no match in this dimension, so the order can still be
-- joined and counted instead of silently dropped by an INNER JOIN.
SELECT

    {{ dbt_utils.generate_surrogate_key(["'unknown'"]) }} AS customer_key,
    'unknown' AS customer_id,
    CAST(NULL AS STRING) AS gender,
    CAST(NULL AS INT64) AS age,
    'unknown' AS age_band,
    'unknown' AS country,
    'unknown' AS region,
    'unknown' AS city,
    CAST(NULL AS DATE) AS acquisition_date,
    'unknown' AS acquisition_channel,
    'unknown' AS acquisition_campaign,
    CAST(NULL AS DATE) AS first_purchase_date,
    CAST(NULL AS DATE) AS latest_purchase_date,
    CAST(0 AS INT64) AS lifetime_orders,
    CAST(0 AS NUMERIC) AS lifetime_revenue,
    'unknown' AS customer_status,
    CURRENT_TIMESTAMP() AS loaded_at