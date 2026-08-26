SELECT
    {{ dbt_utils.generate_surrogate_key([
        'channel_name'
    ]) }} AS channel_key,

    LOWER(TRIM(channel_name)) AS channel_name,
    LOWER(TRIM(channel_category)) AS channel_category,
    LOWER(TRIM(traffic_type)) AS traffic_type


FROM {{ ref('stg_channels') }}

UNION ALL

-- Unattributed channel member is used for sales orders
-- that legitimately have no channel at all (organic/direct), so
-- INNER JOINs in the aggregate layer don't silently drop that revenue.
SELECT
    {{ dbt_utils.generate_surrogate_key(["'unattributed'"]) }} AS channel_key,
    'unattributed' AS channel_name,
    'unattributed' AS channel_category,
    'unattributed' AS traffic_type

UNION ALL

-- Unknown channel member is used for orphaned
-- channel values with no match here (a data-quality problem, not a
-- legitimate no-channel case), so the row stays in the fact instead of
-- being silently dropped by an INNER JOIN.
SELECT
    {{ dbt_utils.generate_surrogate_key(["'unknown'"]) }} AS channel_key,
    'unknown' AS channel_name,
    'unknown' AS channel_category,
    'unknown' AS traffic_type