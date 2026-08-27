{{ config(

    materialized = 'table'

) }}

--------------------------------------------------
-- SALES SUMMARY
--------------------------------------------------

WITH sales_summary AS (

    SELECT

        fs.date_key,

        fs.channel_key,

        fs.campaign_key,

        dc.region,

        --------------------------------------------------
        -- CUSTOMER FACTS
        --------------------------------------------------
        -- Standardized on first_purchase_date per KPI dictionary §6.1
        -- (was previously acquisition_date, which is a marketing date,
        -- not a purchase date — see audit P1.13). returning_customers is
        -- defined as the complement of new_customers so the two always
        -- sum to total_customers.

        COUNT(DISTINCT fs.customer_key)
            AS total_customers,

        COUNT(DISTINCT CASE

            WHEN dc.first_purchase_date = fs.date_key

            THEN fs.customer_key

        END) AS new_customers,

        COUNT(DISTINCT CASE

            WHEN dc.first_purchase_date != fs.date_key

            THEN fs.customer_key

        END) AS returning_customers,

        --------------------------------------------------
        -- SALES FACTS
        --------------------------------------------------
        -- Refunded orders are excluded from revenue and profit — see
        -- audit P1.10. is_refunded is derived in fact_sales from
        -- refund_status = 'refunded'.

        COUNT(DISTINCT fs.order_id)
            AS total_orders,

        SUM(CASE WHEN NOT fs.is_refunded THEN fs.net_sales END)
            AS total_revenue,

        SUM(CASE WHEN NOT fs.is_refunded THEN fs.gross_profit END)
            AS gross_profit

    FROM {{ ref('fact_sales') }} fs

    JOIN {{ ref('dim_customers') }} dc

        ON fs.customer_key =
           dc.customer_key

    GROUP BY

        fs.date_key,

        fs.channel_key,

        fs.campaign_key,

        dc.region

),

--------------------------------------------------
-- MARKETING SUMMARY
--------------------------------------------------

marketing_summary AS (

    SELECT

        date_key,

        channel_key,

        campaign_key,

        --------------------------------------------------
        -- MARKETING FACTS
        --------------------------------------------------

        SUM(ad_spend)
            AS total_ad_spend,

        SUM(

            CASE

                WHEN LOWER(campaign_objective)
                    = 'acquisition'

                THEN ad_spend

                ELSE 0

            END

        ) AS acquisition_cost

    FROM {{ ref('fact_marketing') }}

    GROUP BY

        date_key,

        channel_key,

        campaign_key

)

--------------------------------------------------
-- FINAL TABLE
--------------------------------------------------

SELECT

    --------------------------------------------------
    -- REPORTING DIMENSIONS
    -- Coalesced so a channel/campaign/day with ad spend
    -- but no sales still gets a row instead of disappearing.
    --------------------------------------------------

    COALESCE(
        ss.date_key,
        ms.date_key
    ) AS report_date,

    dch.channel_name,

    dcmp.campaign_id,

    dcmp.campaign_name,

    dcmp.campaign_type,

    -- Region only exists on the sales side (via dim_customers) — a
    -- marketing-only row (spend with no sales) has no customer to
    -- derive a region from, so it falls back to 'unknown' like other
    -- unattributed dimension values.
    COALESCE(
        ss.region,
        'unknown'
    ) AS region,

    --------------------------------------------------
    -- CUSTOMER FACTS
    --------------------------------------------------

    COALESCE(
        ss.total_customers,
        0
    ) AS total_customers,

    COALESCE(
        ss.new_customers,
        0
    ) AS new_customers,

    COALESCE(
        ss.returning_customers,
        0
    ) AS returning_customers,

    --------------------------------------------------
    -- SALES FACTS
    --------------------------------------------------

    COALESCE(
        ss.total_orders,
        0
    ) AS total_orders,

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

        ms.acquisition_cost,

        0

    ) AS acquisition_cost,

    COALESCE(

        ms.total_ad_spend,

        0

    ) AS total_ad_spend,

    --------------------------------------------------
    -- AUDIT
    --------------------------------------------------

    CURRENT_TIMESTAMP()

        AS loaded_at

FROM sales_summary ss

-- FULL OUTER JOIN (was LEFT JOIN): a channel/campaign/day with ad
-- spend but zero sales previously had no row here at all — its spend
-- just vanished from this table. See audit finding on marketing-only
-- activity being dropped.
FULL OUTER JOIN marketing_summary ms

    ON ss.date_key = ms.date_key

   AND ss.channel_key = ms.channel_key

   AND ss.campaign_key = ms.campaign_key

JOIN {{ ref('dim_channels') }} dch

    ON COALESCE(
           ss.channel_key,
           ms.channel_key
       ) = dch.channel_key

JOIN {{ ref('dim_campaigns') }} dcmp

    ON COALESCE(
           ss.campaign_key,
           ms.campaign_key
       ) = dcmp.campaign_key