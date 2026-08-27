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

        -- Refunded orders excluded from revenue/profit — see audit P1.10
        SUM(CASE WHEN NOT fs.is_refunded THEN fs.net_sales END)
            AS total_revenue,

        SUM(CASE WHEN NOT fs.is_refunded THEN fs.gross_profit END)
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
    -- Coalesced so a campaign/channel/month with ad spend
    -- but no sales still gets a row instead of disappearing.
    --------------------------------------------------

    COALESCE(
        ss.report_month,
        ms.report_month
    ) AS report_month,

    dcmp.campaign_id,

    dcmp.campaign_name,

    dcmp.campaign_type,

    dch.channel_name,

    -- Region only exists on the sales side (via dim_customers) — a
    -- marketing-only row (spend with no sales) has no customer to
    -- derive a region from, so it falls back to 'unknown' like other
    -- unattributed dimension values.
    COALESCE(
        ss.region,
        'unknown'
    ) AS region,

    --------------------------------------------------
    -- SALES FACTS
    --------------------------------------------------

    COALESCE(
        ss.total_orders,
        0
    ) AS total_orders,

    COALESCE(
        ss.total_customers,
        0
    ) AS total_customers,

    COALESCE(
        ss.new_customers,
        0
    ) AS new_customers,

    COALESCE(
        ss.total_revenue,
        0
    ) AS total_revenue,

    COALESCE(
        ss.gross_profit,
        0
    ) AS gross_profit,

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

-- FULL OUTER JOIN (was LEFT JOIN): a campaign/channel/month with ad
-- spend but zero sales previously had no row here at all — its spend
-- just vanished from this table. See audit finding on marketing-only
-- activity being dropped.
FULL OUTER JOIN marketing_summary ms

    ON ss.report_month =
       ms.report_month

   AND ss.campaign_key =
       ms.campaign_key

   AND ss.channel_key =
       ms.channel_key

INNER JOIN {{ ref('dim_campaigns') }} dcmp

    ON COALESCE(
           ss.campaign_key,
           ms.campaign_key
       ) = dcmp.campaign_key

INNER JOIN {{ ref('dim_channels') }} dch

    ON COALESCE(
           ss.channel_key,
           ms.channel_key
       ) = dch.channel_key