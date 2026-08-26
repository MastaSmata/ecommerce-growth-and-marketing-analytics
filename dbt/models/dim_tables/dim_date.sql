{{ config(
    materialized='table'
) }}

WITH date_series AS (

    SELECT
        calendar_date AS date_key

    FROM UNNEST(

        GENERATE_DATE_ARRAY(

            DATE('2020-01-01'),
            DATE('2035-12-31'),
            INTERVAL 1 DAY

        )

    ) AS calendar_date

    UNION ALL

    -- Unknown/unattributed date member — used when a
    -- fact row's date falls outside 2020-2035, so the row can still be
    -- joined and counted instead of silently dropped by an INNER JOIN.
    SELECT DATE('1900-01-01') AS date_key

)

SELECT

    --------------------------------------------------
    -- PRIMARY KEY
    --------------------------------------------------

    date_key,

    FORMAT_DATE('%Y%m%d', date_key)
        AS date_id,

    --------------------------------------------------
    -- DAY
    --------------------------------------------------

    EXTRACT(DAY FROM date_key)
        AS day_of_month,

    EXTRACT(DAYOFWEEK FROM date_key)
        AS day_of_week,

    FORMAT_DATE('%A', date_key)
        AS day_name,

    FORMAT_DATE('%a', date_key)
        AS day_name_short,

    EXTRACT(DAYOFYEAR FROM date_key)
        AS day_of_year,

    --------------------------------------------------
    -- WEEK
    --------------------------------------------------

    EXTRACT(ISOWEEK FROM date_key)
        AS week_of_year,

    DATE_TRUNC(
        date_key,
        WEEK(MONDAY)
    ) AS week_start_date,

    DATE_ADD(

        DATE_TRUNC(
            date_key,
            WEEK(MONDAY)
        ),

        INTERVAL 6 DAY

    ) AS week_end_date,

    CONCAT(

        CAST(EXTRACT(YEAR FROM date_key) AS STRING),

        '-W',

        LPAD(
            CAST(EXTRACT(ISOWEEK FROM date_key) AS STRING),
            2,
            '0'
        )

    ) AS year_week,

    --------------------------------------------------
    -- MONTH
    --------------------------------------------------

    EXTRACT(MONTH FROM date_key)
        AS month_number,

    FORMAT_DATE('%B', date_key)
        AS month_name,

    FORMAT_DATE('%b', date_key)
        AS month_name_short,

    DATE_TRUNC(
        date_key,
        MONTH
    ) AS month_start_date,

    LAST_DAY(
        date_key,
        MONTH
    ) AS month_end_date,

    FORMAT_DATE('%Y-%m', date_key)
        AS year_month_key,

    FORMAT_DATE('%b %Y', date_key)
        AS year_month,

    --------------------------------------------------
    -- QUARTER
    --------------------------------------------------

    EXTRACT(QUARTER FROM date_key)
        AS quarter_number,

    CONCAT(

        'Q',

        CAST(
            EXTRACT(QUARTER FROM date_key)
            AS STRING
        )

    ) AS quarter_name,

    DATE_TRUNC(
        date_key,
        QUARTER
    ) AS quarter_start_date,

    LAST_DAY(
        DATE_TRUNC(
            date_key,
            QUARTER
        ),
        QUARTER
    ) AS quarter_end_date,

    CONCAT(

        CAST(EXTRACT(YEAR FROM date_key) AS STRING),

        ' Q',

        CAST(EXTRACT(QUARTER FROM date_key) AS STRING)

    ) AS year_quarter,

    --------------------------------------------------
    -- YEAR
    --------------------------------------------------

    EXTRACT(YEAR FROM date_key)
        AS year_value,

    DATE_TRUNC(
        date_key,
        YEAR
    ) AS year_start_date,

    LAST_DAY(
        date_key,
        YEAR
    ) AS year_end_date,

    --------------------------------------------------
    -- FLAGS
    --------------------------------------------------

    EXTRACT(DAYOFWEEK FROM date_key)
        IN (1,7)

        AS is_weekend,

    date_key = CURRENT_DATE()

        AS is_today,

    date_key = DATE_SUB(
        CURRENT_DATE(),
        INTERVAL 1 DAY
    )

        AS is_yesterday,

    --------------------------------------------------
    -- POWER BI SORT COLUMNS
    --------------------------------------------------

    EXTRACT(MONTH FROM date_key)
        AS month_sort,

    EXTRACT(QUARTER FROM date_key)
        AS quarter_sort,

    EXTRACT(YEAR FROM date_key) * 100
        + EXTRACT(MONTH FROM date_key)

        AS year_month_sort,

    EXTRACT(YEAR FROM date_key) * 10
        + EXTRACT(QUARTER FROM date_key)

        AS year_quarter_sort,

    --------------------------------------------------
    -- AUDIT
    --------------------------------------------------

    CURRENT_TIMESTAMP()

        AS loaded_at

FROM date_series