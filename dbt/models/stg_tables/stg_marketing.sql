WITH deduped AS (
    SELECT
        TRIM(ads_id) AS ads_id,
        TRIM(campaign_id) AS campaign_id,

        LOWER(TRIM(channel_name)) AS channel_name,
        LOWER(TRIM(campaign_objective)) AS campaign_objective,

        SAFE_CAST(date AS DATE) AS date,

        SAFE_CAST(ad_spend AS NUMERIC) AS ad_spend,
        SAFE_CAST(impressions AS INT64) AS impressions,
        SAFE_CAST(clicks AS INT64) AS clicks,
        SAFE_CAST(conversions AS INT64) AS conversions,

        LOWER(TRIM(campaign_type)) AS campaign_type,

        -- Incremental loads use WRITE_APPEND, so a retried or rerun batch
        -- can insert the same ad row twice. Keep only the most recently
        -- ingested copy of each ads_id 
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(ads_id)
            ORDER BY _ingested_at DESC
        ) AS _row_num

    FROM {{ source('raw', 'raw_marketing') }}
)

SELECT
    ads_id,
    campaign_id,
    channel_name,
    campaign_objective,
    date,
    ad_spend,
    impressions,
    clicks,
    conversions,
    campaign_type

FROM deduped
WHERE _row_num = 1