{{ config(

    materialized='table'

) }}

--------------------------------------------------
-- SALES SUMMARY
--------------------------------------------------

WITH sales_summary AS (

    SELECT

        DATE_TRUNC(fact_sales.date_key, MONTH)
            AS report_month,

        fact_sales.channel_key,

        COUNT(DISTINCT fact_sales.order_id)
            AS total_orders,

        COUNT(DISTINCT fact_sales.customer_key)
            AS total_customers,

        SUM(fact_sales.net_sales)
            AS total_revenue,

        SUM(fact_sales.gross_profit)
            AS gross_profit

    FROM {{ ref('fact_sales') }} fact_sales

    GROUP BY

        report_month,
        fact_sales.channel_key

),

--------------------------------------------------
-- MARKETING SUMMARY
--------------------------------------------------

marketing_summary AS (

    SELECT

        DATE_TRUNC(date_key, MONTH)
            AS report_month,

        channel_key,

        SUM(ad_spend)
            AS total_ad_spend,

        SUM(impressions)
            AS impressions,

        SUM(clicks)
            AS clicks,

        SUM(conversions)
            AS conversions

    FROM {{ ref('fact_marketing') }}

    GROUP BY

        report_month,
        channel_key

)

--------------------------------------------------
-- FINAL CHANNEL PERFORMANCE
--------------------------------------------------

SELECT

    --------------------------------------------------
    -- REPORTING GRAIN
    --------------------------------------------------

    sales_summary.report_month,

    --------------------------------------------------
    -- CHANNEL
    --------------------------------------------------

    dim_channels.channel_name,

    --------------------------------------------------
    -- SALES
    --------------------------------------------------

    sales_summary.total_orders,

    sales_summary.total_customers,

    sales_summary.total_revenue,

    sales_summary.gross_profit,

    --------------------------------------------------
    -- MARKETING
    --------------------------------------------------

    COALESCE(
        marketing_summary.total_ad_spend,
        0
    ) AS total_ad_spend,

    COALESCE(
        marketing_summary.impressions,
        0
    ) AS impressions,

    COALESCE(
        marketing_summary.clicks,
        0
    ) AS clicks,

    COALESCE(
        marketing_summary.conversions,
        0
    ) AS conversions,

    

    --------------------------------------------------
    -- AUDIT
    --------------------------------------------------

    CURRENT_TIMESTAMP()

        AS loaded_at

FROM sales_summary

LEFT JOIN marketing_summary

    ON sales_summary.report_month =
       marketing_summary.report_month

    AND sales_summary.channel_key =
        marketing_summary.channel_key

JOIN {{ ref('dim_channels') }} dim_channels

    ON sales_summary.channel_key =
       dim_channels.channel_key