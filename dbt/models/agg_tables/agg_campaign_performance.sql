-- The free version of Google CLoud Account does not permit increamental method for materialization

{{ config(

    materialized='table'

) }}

--------------------------------------------------
-- SALES SUMMARY
--------------------------------------------------

WITH sales_summary AS (

    SELECT

        DATE_TRUNC(fs.date_key, MONTH)
            AS report_month,

        fs.campaign_key,

        fs.channel_key,

        dc.region,

        --------------------------------------------------
        -- SALES FACTS
        --------------------------------------------------

        COUNT(DISTINCT fs.order_id)
            AS total_orders,

        COUNT(DISTINCT fs.customer_key)
            AS total_customers,

        COUNT(
            DISTINCT CASE

                WHEN DATE_TRUNC(dc.first_purchase_date, MONTH)
                     = DATE_TRUNC(fs.date_key, MONTH)

                THEN fs.customer_key

            END

        ) AS new_customers,

        SUM(fs.net_sales)
            AS total_revenue,

        SUM(fs.gross_profit)
            AS gross_profit

    FROM {{ ref('fact_sales') }} fs

    INNER JOIN {{ ref('dim_customers') }} dc

        ON fs.customer_key =
           dc.customer_key

    GROUP BY

        report_month,

        fs.campaign_key,

        fs.channel_key,

        dc.region

),

--------------------------------------------------
-- MARKETING SUMMARY
--------------------------------------------------

marketing_summary AS (

    SELECT

        DATE_TRUNC(date_key, MONTH)
            AS report_month,

        campaign_key,

        channel_key,

        --------------------------------------------------
        -- MARKETING FACTS
        --------------------------------------------------

        SUM(ad_spend)
            AS total_ad_spend,

        SUM(

            CASE

                WHEN campaign_objective = 'acquisition'

                THEN ad_spend

                ELSE 0

            END

        ) AS acquisition_cost,

        SUM(impressions)
            AS impressions,

        SUM(clicks)
            AS clicks,

        SUM(conversions)
            AS conversions

    FROM {{ ref('fact_marketing') }}

    GROUP BY

        report_month,

        campaign_key,

        channel_key

)

--------------------------------------------------
-- FINAL CAMPAIGN PERFORMANCE
--------------------------------------------------

SELECT

    --------------------------------------------------
    -- REPORTING DIMENSIONS
    --------------------------------------------------

    ss.report_month,

    dcmp.campaign_id,

    dcmp.campaign_name,

    dcmp.campaign_type,

    dch.channel_name,

    ss.region,

    --------------------------------------------------
    -- SALES FACTS
    --------------------------------------------------

    ss.total_orders,

    ss.total_customers,

    ss.new_customers,

    ss.total_revenue,

    ss.gross_profit,

    --------------------------------------------------
    -- MARKETING FACTS
    --------------------------------------------------

    COALESCE(
        ms.total_ad_spend,
        0
    ) AS total_ad_spend,

    COALESCE(
        ms.acquisition_cost,
        0
    ) AS acquisition_cost,

    COALESCE(
        ms.impressions,
        0
    ) AS impressions,

    COALESCE(
        ms.clicks,
        0
    ) AS clicks,

    COALESCE(
        ms.conversions,
        0
    ) AS conversions,

    --------------------------------------------------
    -- AUDIT
    --------------------------------------------------

    CURRENT_TIMESTAMP()
        AS loaded_at

FROM sales_summary ss

LEFT JOIN marketing_summary ms

    ON ss.report_month =
       ms.report_month

   AND ss.campaign_key =
       ms.campaign_key

   AND ss.channel_key =
       ms.channel_key

INNER JOIN {{ ref('dim_campaigns') }} dcmp

    ON ss.campaign_key =
       dcmp.campaign_key

INNER JOIN {{ ref('dim_channels') }} dch

    ON ss.channel_key =
       dch.channel_key