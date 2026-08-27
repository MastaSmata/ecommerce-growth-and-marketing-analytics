{{ config(

    materialized = 'table'

) }}

--------------------------------------------------
-- MAX REPORTING MONTH
--------------------------------------------------

WITH max_reporting_month AS (

    SELECT

        DATE_TRUNC(
            MAX(date_key),
            MONTH
        ) AS latest_month

    FROM {{ ref('fact_sales') }}

),

--------------------------------------------------
-- MONTH INDEX (0 - 11)
--------------------------------------------------

month_index AS (

    SELECT month_number

    FROM UNNEST(GENERATE_ARRAY(0,11)) AS month_number

),

--------------------------------------------------
-- CUSTOMER COHORTS
--------------------------------------------------

customer_cohorts AS (

    SELECT

        customer_key,

        region,

        DATE_TRUNC(
            first_purchase_date,
            MONTH
        ) AS cohort_month

    FROM {{ ref('dim_customers') }}

    WHERE first_purchase_date IS NOT NULL

),

--------------------------------------------------
-- CUSTOMER MONTHLY ACTIVITY
-- ONE ROW PER CUSTOMER PER MONTH
--------------------------------------------------

customer_monthly_activity AS (

    SELECT

        customer_key,

        DATE_TRUNC(
            date_key,
            MONTH
        ) AS activity_month

    FROM {{ ref('fact_sales') }}

    GROUP BY

        customer_key,

        activity_month

),

customer_activity AS (

    SELECT

        cc.customer_key,

        cc.region,

        cc.cohort_month,

        cma.activity_month,

        DATE_DIFF(

            cma.activity_month,

            cc.cohort_month,

            MONTH

        ) AS months_since_acquisition

    FROM customer_cohorts cc

    INNER JOIN customer_monthly_activity cma

        ON cc.customer_key =
           cma.customer_key

    WHERE

        cma.activity_month >= cc.cohort_month

        AND DATE_DIFF(

            cma.activity_month,

            cc.cohort_month,

            MONTH

        ) BETWEEN 0 AND 11

),

--------------------------------------------------
-- COHORT SIZE
--------------------------------------------------

cohort_size AS (

    SELECT

        cohort_month,

        region,

        COUNT(DISTINCT customer_key)
            AS cohort_size

    FROM customer_cohorts

    GROUP BY

        cohort_month,

        region

),

--------------------------------------------------
-- ACTIVE CUSTOMERS
--------------------------------------------------

active_customers AS (

    SELECT

        cohort_month,

        region,

        months_since_acquisition,

        COUNT(DISTINCT customer_key)
            AS active_customers

    FROM customer_activity

    GROUP BY

        cohort_month,

        region,

        months_since_acquisition

),

--------------------------------------------------
-- COMPLETE COHORT CALENDAR
-- Full 0-11 month window per cohort, regardless of
-- calendar year. IMPORTANT: the Power BI report's
-- "Cohort Month" field/axis must be bound to the
-- actual cohort_month DATE value (which includes
-- year), not a month-name-only or month-number-only
-- field. Binding to month name/number alone will
-- blend different years' cohorts together in the
-- matrix once more than one year of data exists —
-- that was the root cause of the original Power BI
-- display bug, and it is a report-layer fix, not
-- something this model can enforce.
--------------------------------------------------

cohort_calendar AS (

    SELECT

        cs.cohort_month,

        cs.region,

        mi.month_number
            AS months_since_acquisition,

        DATE_ADD(

            cs.cohort_month,

            INTERVAL mi.month_number MONTH

        ) AS activity_month,

        cs.cohort_size

    FROM cohort_size cs

    CROSS JOIN month_index mi

    CROSS JOIN max_reporting_month rm

    WHERE

        DATE_ADD(

            cs.cohort_month,

            INTERVAL mi.month_number MONTH

        ) <= rm.latest_month

)

--------------------------------------------------
-- FINAL TABLE
--------------------------------------------------

SELECT

    --------------------------------------------------
    -- REPORTING DIMENSIONS
    --------------------------------------------------

    cc.cohort_month,

    cc.activity_month,

    cc.months_since_acquisition,

    cc.region,

    --------------------------------------------------
    -- COHORT FACTS
    --------------------------------------------------

    cc.cohort_size,

    COALESCE(

        ac.active_customers,

        0

    ) AS active_customers,

    --------------------------------------------------
    -- RETENTION RATE
    --------------------------------------------------

    ROUND(

        SAFE_DIVIDE(

            COALESCE(
                ac.active_customers,
                0
            ),

            cc.cohort_size

        ) * 100,

        2

    ) AS retention_rate,

    --------------------------------------------------
    -- AUDIT
    --------------------------------------------------

    CURRENT_TIMESTAMP()

        AS loaded_at

FROM cohort_calendar cc

LEFT JOIN active_customers ac

    ON cc.cohort_month =
       ac.cohort_month

   AND cc.region =
       ac.region

   AND cc.months_since_acquisition =
       ac.months_since_acquisition

ORDER BY

    cc.cohort_month,

    cc.region,

    cc.months_since_acquisition