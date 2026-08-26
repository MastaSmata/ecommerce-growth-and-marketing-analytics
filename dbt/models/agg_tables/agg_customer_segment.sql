{{ config(

    materialized='table'

) }}

--------------------------------------------------
-- CUSTOMER MONTHLY SUMMARY
--------------------------------------------------

WITH customer_summary AS (

    SELECT

        --------------------------------------------------
        -- REPORTING PERIOD
        --------------------------------------------------

        DATE_TRUNC(fs.date_key, MONTH)
            AS report_month,

        --------------------------------------------------
        -- CUSTOMER
        --------------------------------------------------

        dc.customer_key,

        dc.region,

        dc.gender,

        dc.age_band,

        dc.customer_status,

        --------------------------------------------------
        -- LIFETIME / MONTHLY METRICS
        --------------------------------------------------

        COUNT(DISTINCT fs.order_id)
            AS total_orders,

        -- Refunded orders excluded from revenue 
        SUM(CASE WHEN NOT fs.is_refunded THEN fs.net_sales END)
            AS total_revenue

    FROM {{ ref('fact_sales') }} fs

    INNER JOIN {{ ref('dim_customers') }} dc

        ON fs.customer_key = dc.customer_key

    GROUP BY

        report_month,

        dc.customer_key,

        dc.region,

        dc.gender,

        dc.age_band,

        dc.customer_status

),

--------------------------------------------------
-- SEGMENT SUMMARY
--------------------------------------------------

segment_summary AS (

    SELECT

        --------------------------------------------------
        -- REPORTING PERIOD
        --------------------------------------------------

        report_month,

        --------------------------------------------------
        -- SEGMENT
        --------------------------------------------------

        region,

        gender,

        age_band,

        customer_status,

        --------------------------------------------------
        -- CUSTOMER COUNTS
        --------------------------------------------------

        COUNT(*) AS total_customers,

        
        COUNTIF(total_orders > 1)
            AS customers_with_multiple_orders_in_month,

        --------------------------------------------------
        -- SALES
        --------------------------------------------------

        SUM(total_orders)
            AS total_orders,

        SUM(total_revenue)
            AS total_revenue

    FROM customer_summary

    GROUP BY

        report_month,

        region,

        gender,

        age_band,

        customer_status

)

--------------------------------------------------
-- FINAL TABLE
--------------------------------------------------

SELECT

    --------------------------------------------------
    -- REPORT MONTH
    --------------------------------------------------

    report_month,

    --------------------------------------------------
    -- CUSTOMER SEGMENT
    --------------------------------------------------

    region,

    gender,

    age_band,

    customer_status,

    --------------------------------------------------
    -- CUSTOMER COUNTS
    --------------------------------------------------

    total_customers,

    customers_with_multiple_orders_in_month,

    --------------------------------------------------
    -- SALES
    --------------------------------------------------

    total_orders,

    total_revenue,

    --------------------------------------------------
    -- AUDIT
    --------------------------------------------------
    -- Note: repeat_purchase_rate is intentionally NOT stored here — it's
    -- a non-additive ratio and the KPI dictionary lists it under "Do NOT
    -- store as SQL KPIs" (see audit P1.15). Compute it in Power BI as
    -- DAX: DIVIDE(SUM(customers_with_multiple_orders_in_month), SUM(total_customers)).

    CURRENT_TIMESTAMP()

        AS loaded_at

FROM segment_summary