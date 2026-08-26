{{ config(

    materialized='table',

) }}

WITH sales AS (

    SELECT *

    FROM {{ ref('stg_sales') }}

),

date_dimension AS (

    SELECT
        date_key

    FROM {{ ref('dim_date') }}

),

customer_dimension AS (

    SELECT
        customer_key,
        customer_id

    FROM {{ ref('dim_customers') }}

),

product_dimension AS (

    SELECT
        product_key,
        product_id

    FROM {{ ref('dim_products') }}

),

channel_dimension AS (

    SELECT
        channel_key,
        channel_name

    FROM {{ ref('dim_channels') }}

),

campaign_dimension AS (

    SELECT
        campaign_key,
        campaign_id

    FROM {{ ref('dim_campaigns') }}

)

SELECT

    --------------------------------------------------
    -- FACT SURROGATE KEY
    --------------------------------------------------

    {{ dbt_utils.generate_surrogate_key([
        'sales.order_id',
        'sales.product_id'
    ]) }} AS sales_key,

    --------------------------------------------------
    -- BUSINESS IDENTIFIER
    --------------------------------------------------

    sales.order_id,

    --------------------------------------------------
    -- STAR SCHEMA KEYS
    -- date/customer/product are coalesced to each dimension's "unknown"
    -- member for orphaned values (see audit P1.8). channel/campaign use
    -- a CASE below that distinguishes "unattributed" (legitimately no
    -- value — organic/direct) from "unknown" (a value that didn't match
    -- anything — a data-quality problem) 
    --------------------------------------------------

    COALESCE(
        date_dimension.date_key,
        DATE('1900-01-01')
    ) AS date_key,

    COALESCE(
        customer_dimension.customer_key,
        {{ dbt_utils.generate_surrogate_key(["'unknown'"]) }}
    ) AS customer_key,

    COALESCE(
        product_dimension.product_key,
        {{ dbt_utils.generate_surrogate_key(["'unknown'"]) }}
    ) AS product_key,

    -- Distinguishes two different cases instead of collapsing them into
    -- one bucket: "unattributed" = the order genuinely has no channel/
    -- campaign (organic/direct — a normal outcome), "unknown" = a
    -- channel/campaign value was present but didn't match anything in
    -- the dimension (a data-quality problem worth investigating).
    CASE
        WHEN sales.channel IS NULL
            OR sales.channel = ''
            THEN {{ dbt_utils.generate_surrogate_key(["'unattributed'"]) }}
        WHEN channel_dimension.channel_key IS NULL
            THEN {{ dbt_utils.generate_surrogate_key(["'unknown'"]) }}
        ELSE channel_dimension.channel_key
    END AS channel_key,

    CASE
        WHEN sales.campaign_id IS NULL
            OR sales.campaign_id = ''
            THEN {{ dbt_utils.generate_surrogate_key(["'unattributed'"]) }}
        WHEN campaign_dimension.campaign_key IS NULL
            THEN {{ dbt_utils.generate_surrogate_key(["'unknown'"]) }}
        ELSE campaign_dimension.campaign_key
    END AS campaign_key,

    --------------------------------------------------
    -- TRANSACTION ATTRIBUTES
    --------------------------------------------------

    sales.ship_mode,

    LOWER(TRIM(sales.refund_status))
        AS refund_status,

    -- Passed through from the source system as-is. NOT the same as
    -- dim_customers.customer_status, which is derived from order counts
    -- (prospect/new/returning). Renamed to avoid the two being picked up
    -- interchangeably in Power BI 
    sales.customer_status AS source_customer_status,

    --------------------------------------------------
    -- SALES MEASURES
    --------------------------------------------------

    sales.quantity,

    sales.price,

    sales.unit_cost,

    sales.discount,

    sales.revenue AS net_sales,

    --------------------------------------------------
    -- ROW-LEVEL FINANCIAL METRICS
    --------------------------------------------------

    sales.quantity * sales.price
        AS gross_sales,

    sales.quantity * sales.unit_cost
        AS total_cost,

    sales.quantity
        * sales.price
        * sales.discount
        AS discount_amount,

    sales.revenue
        - (sales.quantity * sales.unit_cost)
        AS gross_profit,

    sales.price
        - sales.unit_cost
        AS unit_margin,

    --------------------------------------------------
    -- FLAGS
    --------------------------------------------------

    LOWER(TRIM(sales.refund_status)) = 'refunded'
        AS is_refunded,

    --------------------------------------------------
    -- AUDIT
    --------------------------------------------------

    CURRENT_TIMESTAMP()
        AS loaded_at

FROM sales

LEFT JOIN date_dimension

    ON DATE(sales.order_date)
       = date_dimension.date_key

LEFT JOIN customer_dimension

    ON sales.customer_id
       = customer_dimension.customer_id

LEFT JOIN product_dimension

    ON sales.product_id
       = product_dimension.product_id

LEFT JOIN channel_dimension

    ON LOWER(TRIM(sales.channel))
       = channel_dimension.channel_name

LEFT JOIN campaign_dimension

    ON sales.campaign_id
       = campaign_dimension.campaign_id