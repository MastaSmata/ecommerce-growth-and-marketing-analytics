
SELECT
    TRIM(product_id) AS product_id,
    LOWER(TRIM(product_name)) AS product_name,
    SAFE_CAST(price AS NUMERIC) AS price,
    LOWER(TRIM(sub_category)) AS sub_category,
    LOWER(TRIM(category)) AS category,
    LOWER(TRIM(brand)) AS brand,
    TRIM(supplier_id) AS supplier_id,
    SAFE_CAST(unit_cost AS NUMERIC) AS unit_cost

FROM {{ source('raw', 'raw_products') }}