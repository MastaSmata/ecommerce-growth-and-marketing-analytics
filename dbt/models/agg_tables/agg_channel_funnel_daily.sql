{{ config(

    materialized='table'

) }}

--------------------------------------------------
-- DAILY CHANNEL FUNNEL
--------------------------------------------------

SELECT

    --------------------------------------------------
    -- REPORTING GRAIN
    --------------------------------------------------

    fact_marketing.date_key,

    --------------------------------------------------
    -- CHANNEL
    --------------------------------------------------

    dim_channels.channel_name,

    dim_channels.channel_category,

    dim_channels.traffic_type,

    --------------------------------------------------
    -- MARKETING ACTIVITY
    --------------------------------------------------

    SUM(fact_marketing.ad_spend)
        AS total_ad_spend,

    SUM(fact_marketing.impressions)
        AS total_impressions,

    SUM(fact_marketing.clicks)
        AS total_clicks,

    SUM(fact_marketing.conversions)
        AS total_conversions,

    
    --------------------------------------------------
    -- AUDIT
    --------------------------------------------------

    CURRENT_TIMESTAMP()

        AS loaded_at

FROM {{ ref('fact_marketing') }} fact_marketing

JOIN {{ ref('dim_channels') }} dim_channels

    ON fact_marketing.channel_key =
       dim_channels.channel_key

GROUP BY

    fact_marketing.date_key,

    dim_channels.channel_name,

    dim_channels.channel_category,

    dim_channels.traffic_type