
SELECT
    LOWER(TRIM(channel_name)) AS channel_name,
    LOWER(TRIM(channel_category)) AS channel_category,
    LOWER(TRIM(traffic_type)) AS traffic_type

FROM {{ source('raw', 'raw_channels') }}