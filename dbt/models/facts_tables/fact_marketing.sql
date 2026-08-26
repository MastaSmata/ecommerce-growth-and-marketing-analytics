{{ config(

    materialized='table'

) }}

WITH marketing AS (

    SELECT *

    FROM {{ ref('stg_marketing') }}

),

date_dimension AS (

    SELECT
        date_key

    FROM {{ ref('dim_date') }}

),

campaign_dimension AS (

    SELECT
        campaign_key,
        campaign_id,

    FROM {{ ref('dim_campaigns') }}

),

channel_dimension AS (

    SELECT
        channel_key,
        channel_name

    FROM {{ ref('dim_channels') }}

)

SELECT

    --------------------------------------------------
    -- FACT SURROGATE KEY
    --------------------------------------------------

    {{ dbt_utils.generate_surrogate_key([
        'marketing.ads_id'
    ]) }} AS marketing_key,

    --------------------------------------------------
    -- FOREIGN KEYS
    -- Coalesced to each dimension's "unknown" member so orphaned ad
    -- rows stay in the fact instead of being silently dropped by an
    -- INNER JOIN 
    --------------------------------------------------

    COALESCE(
        date_dimension.date_key,
        DATE('1900-01-01')
    ) AS date_key,

    COALESCE(
        campaign_dimension.campaign_key,
        {{ dbt_utils.generate_surrogate_key(["'unknown'"]) }}
    ) AS campaign_key,

    COALESCE(
        channel_dimension.channel_key,
        {{ dbt_utils.generate_surrogate_key(["'unknown'"]) }}
    ) AS channel_key,

    --------------------------------------------------
    -- BUSINESS IDENTIFIER
    --------------------------------------------------

    marketing.ads_id,

    --------------------------------------------------
    -- MARKETING METRICS
    --------------------------------------------------

    marketing.ad_spend,

    marketing.impressions,

    marketing.clicks,

    marketing.conversions,

    marketing.campaign_objective,

    --------------------------------------------------
    -- DERIVED METRICS
    --------------------------------------------------

    SAFE_DIVIDE(
        marketing.clicks,
        marketing.impressions
    ) AS click_through_rate,

    SAFE_DIVIDE(
        marketing.conversions,
        marketing.clicks
    ) AS conversion_rate,

    SAFE_DIVIDE(
        marketing.ad_spend,
        marketing.clicks
    ) AS cost_per_click,

    SAFE_DIVIDE(
        marketing.ad_spend,
        marketing.impressions
    ) * 1000 AS cost_per_thousand_impressions,

    SAFE_DIVIDE(
        marketing.ad_spend,
        marketing.conversions
    ) AS cost_per_conversion,

    --------------------------------------------------
    -- AUDIT
    --------------------------------------------------

    CURRENT_TIMESTAMP() AS loaded_at

FROM marketing

LEFT JOIN date_dimension

    ON marketing.date = date_dimension.date_key

LEFT JOIN campaign_dimension

    ON marketing.campaign_id = campaign_dimension.campaign_id

LEFT JOIN channel_dimension

    ON LOWER(TRIM(marketing.channel_name))
       = channel_dimension.channel_name