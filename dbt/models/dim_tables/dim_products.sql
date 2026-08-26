SELECT
{{ dbt_utils.generate_surrogate_key([
        'product_id'
    ]) }} AS product_key,
    product_id,
    LOWER(TRIM(product_name)) AS product_name,
    price,
    unit_cost,
    LOWER(TRIM(sub_category)) AS sub_category,
    LOWER(TRIM(category)) AS category,
    LOWER(TRIM(brand)) AS brand,
    supplier_id,

    -------------------------------------------------
    -- BUSINESS DERIVED METRICS
    -------------------------------------------------
    (price - unit_cost) AS unit_margin

FROM {{ ref('stg_products') }}

UNION ALL

-- Unknown product member — used when a sales row's
-- product_id has no match in this dimension, so the order can still be
-- joined and counted instead of silently dropped by an INNER JOIN.
SELECT
    {{ dbt_utils.generate_surrogate_key(["'unknown'"]) }} AS product_key,
    'unknown' AS product_id,
    'unknown' AS product_name,
    CAST(0 AS NUMERIC) AS price,
    CAST(0 AS NUMERIC) AS unit_cost,
    'unknown' AS sub_category,
    'unknown' AS category,
    'unknown' AS brand,
    CAST(NULL AS STRING) AS supplier_id,
    CAST(0 AS NUMERIC) AS unit_margin