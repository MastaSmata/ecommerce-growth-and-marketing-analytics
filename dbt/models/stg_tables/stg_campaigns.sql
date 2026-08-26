
SELECT
    TRIM(campaign_id) AS campaign_id,
    LOWER(TRIM(campaign_type)) AS campaign_type,
    LOWER(TRIM(campaign_objective)) AS campaign_objective,
    LOWER(TRIM(channel)) AS channel,
    SAFE_CAST(start_date AS DATE) AS start_date,
    SAFE_CAST(end_date AS DATE) AS end_date,
    SAFE_CAST(total_revenue AS NUMERIC) AS total_revenue,
    LOWER(TRIM(campaign_name)) AS campaign_name,
    SAFE_CAST(budget AS NUMERIC) AS budget

FROM {{ source('raw', 'raw_campaigns') }}