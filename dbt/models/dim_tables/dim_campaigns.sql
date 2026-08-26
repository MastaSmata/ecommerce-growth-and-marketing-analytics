{{ config(
    materialized='table'
) }}

WITH channel_dimension AS (

    SELECT
        channel_key,
        channel_name

    FROM {{ ref('dim_channels') }}

)

SELECT

    --------------------------------------------------
    -- SURROGATE KEY
    --------------------------------------------------

    {{ dbt_utils.generate_surrogate_key([
        'campaign_id'
    ]) }} AS campaign_key,

    --------------------------------------------------
    -- BUSINESS KEY
    --------------------------------------------------

    campaign_id,

    --------------------------------------------------
    -- DIMENSION KEYS
    --------------------------------------------------

    channel_dimension.channel_key,

    --------------------------------------------------
    -- CAMPAIGN ATTRIBUTES
    --------------------------------------------------

    LOWER(TRIM(campaign_name))
        AS campaign_name,

    LOWER(TRIM(campaign_type))
        AS campaign_type,

    LOWER(TRIM(campaign_objective))
        AS campaign_objective,

    start_date,

    end_date,

    budget,

    --------------------------------------------------
    -- AUDIT
    --------------------------------------------------

    CURRENT_TIMESTAMP()
        AS loaded_at

FROM {{ ref('stg_campaigns') }} AS campaigns

LEFT JOIN channel_dimension

    ON LOWER(TRIM(campaigns.channel))
       = channel_dimension.channel_name

UNION ALL

-- Unattributed campaign member (see audit P1.17) — used for sales
-- orders that legitimately have no campaign at all (organic/direct), so
-- INNER JOINs in the aggregate layer don't silently drop that revenue.
SELECT

    {{ dbt_utils.generate_surrogate_key(["'unattributed'"]) }} AS campaign_key,
    'unattributed' AS campaign_id,
    {{ dbt_utils.generate_surrogate_key(["'unattributed'"]) }} AS channel_key,
    'unattributed' AS campaign_name,
    'unattributed' AS campaign_type,
    'unattributed' AS campaign_objective,
    CAST(NULL AS DATE) AS start_date,
    CAST(NULL AS DATE) AS end_date,
    CAST(0 AS NUMERIC) AS budget,
    CURRENT_TIMESTAMP() AS loaded_at

UNION ALL

-- Unknown campaign member is used for orphaned
-- campaign_ids with no match here (a data-quality problem, not a
-- legitimate no-campaign case — every ad-spend record should reference
-- a real campaign), so the row stays in the fact instead of being
-- silently dropped by an INNER JOIN.
SELECT

    {{ dbt_utils.generate_surrogate_key(["'unknown'"]) }} AS campaign_key,
    'unknown' AS campaign_id,
    {{ dbt_utils.generate_surrogate_key(["'unknown'"]) }} AS channel_key,
    'unknown' AS campaign_name,
    'unknown' AS campaign_type,
    'unknown' AS campaign_objective,
    CAST(NULL AS DATE) AS start_date,
    CAST(NULL AS DATE) AS end_date,
    CAST(0 AS NUMERIC) AS budget,
    CURRENT_TIMESTAMP() AS loaded_at