# Growth & Marketing Analytics — KPI Dictionary & Data Model

## 1. Purpose

This document is the single KPI reference for the **Growth & Marketing Analytics**.

It defines:

- the business meaning of each KPI;
- the source data required;
- the analytical grain;
- whether the metric belongs in **SQL/dbt** or **Power BI/DAX**;
- the aggregate table responsible for the metric;
- the dimensions that should filter the metric.

The project follows this architecture:

```text
Source Data
    ↓
Python ETL
    ↓
BigQuery Raw / Fact Tables
    ↓
dbt Transformation Layer
    ↓
Aggregate Tables
    ↓
Power BI Semantic Model
    ↓
DAX Measures
    ↓
Dashboard
```

The core principle is:

> **SQL/dbt stores reliable additive facts and reporting dimensions. Power BI/DAX calculates analytical ratios and context-dependent KPIs.**

This avoids duplicating business logic between the warehouse and Power BI.

---

# 2. Project Scope

The dashboard is focused on **e-commerce growth, marketing performance, customer retention and customer segmentation**.

The active analytical domains are:

1. Sales & Revenue
2. Customer Growth & Retention
3. Marketing & Campaign Performance
4. Channel & Conversion Funnel
5. Customer Segmentation

The following domains are **outside the current project scope** and are therefore excluded from this KPI dictionary:

- Inventory & Supply Chain
- Order Fulfillment & Logistics
- Delivery Performance
- Customer Sentiment / Reviews
- Website Behaviour Analytics
- Competitor Pricing Intelligence
- Email/SMS lifecycle performance
- Returns & Product Quality

These require source fields/tables that are not part of the current dashboard model.

---

# 3. Core Data Model

## Dimension Tables

### `dim_date`

Purpose:

- common calendar dimension;
- year/month filtering;
- time intelligence;
- consistent date filtering across aggregate tables.

Important columns:

- `date_key`
- `year`
- `month`
- `month_name`
- `month_start`
- `quarter`

Power BI should use `dim_date` as the model's marked Date Table.

---

### `dim_customers`

Customer-level attributes.

Important columns:

- `customer_key`
- `customer_id`
- `acquisition_date`
- `first_purchase_date`
- `region`
- `gender`
- `age`
- `age_band`
- `customer_status`

Used by:

- customer acquisition;
- new vs returning customers;
- cohorts;
- regional analysis;
- customer segmentation.

---

### `dim_campaigns`

Important columns:

- `campaign_key`
- `campaign_id`
- `campaign_name`
- `campaign_type`
- `campaign_objective`
- `start_date`
- `end_date`

`campaign_type` is important for distinguishing campaign behaviour such as:

- Acquisition
- Retargeting

`campaign_objective` is used specifically for determining acquisition advertising spend.

---

### `dim_channels`

Important columns:

- `channel_key`
- `channel_name`
- channel attributes available in the source model.

---

### `dim_products`

Important columns:

- `product_key`
- `product_id`
- `product_name`
- `category`
- `sub_category`
- `brand`

---

# 4. Fact Tables

## `fact_sales`

### Grain

One row per sales transaction / sales line according to the implemented source grain.

Core fields include:

- `order_id`
- `customer_key`
- `product_key`
- `date_key`
- `campaign_key`
- `channel_key`
- `quantity`
- `price`
- `net_sales`
- `gross_profit`
- discount-related fields where available.

---

## `fact_marketing`

### Grain

Marketing activity by date/campaign/channel.

Core fields:

- `date_key`
- `campaign_key`
- `channel_key`
- `ad_spend`
- `impressions`
- `clicks`
- `conversions`
- `campaign_objective`

---

# 5. Domain 1 — Sales & Revenue

## Business Question

**How much are we selling, where is revenue coming from, and how profitable are those sales?**

### Primary Aggregate

`agg_sales_daily`

### Grain

```text
date × category × sub_category × region × channel × campaign_type
```

Where the implemented project requires a different grain, the actual dbt model grain takes precedence.

### Store in SQL/dbt

These are additive/base facts:

- `total_revenue`
- `total_orders`
- `total_units`
- `total_discount`
- `gross_profit`

### Calculate in Power BI

These are context-dependent metrics:

- Revenue
- Orders
- AOV
- Gross Margin %
- Average Selling Price
- Revenue per Customer
- Orders per Customer
- Discount Rate / Discount Frequency

### Core DAX KPIs

#### Revenue

```text
SUM(total_revenue)
```

#### Orders

```text
SUM(total_orders)
```

#### AOV

```text
Revenue / Orders
```

#### Gross Margin %

```text
Gross Profit / Revenue
```

---

# 6. Domain 2 — Customer Growth & Retention

## Business Question

**Are we acquiring customers and turning them into repeat customers?**

Primary aggregate tables:

- `agg_growth_daily`
- `agg_customer_cohort`
- `agg_customer_segment`

---

## 6.1 New Customers

### Definition

Number of unique customers whose first purchase occurred within the reporting period.

Implemented using:

```text
dim_customers.first_purchase_date
```

and the sales reporting date.

### SQL

New-customer counts can be stored in an aggregate where the required grain is stable.

### Power BI

For broad-period analysis, the final KPI should be calculated with DAX where appropriate rather than summing incompatible pre-aggregated ratios.

---

## 6.2 Returning Customers

### Definition

Customers who have purchased previously and purchase again during the reporting period.

---

## 6.3 Repeat Purchase Rate

### Definition

```text
Returning Customers / Total Customers
```

### Power BI

This should be a DAX measure.

---

# 7. Domain 3 — Customer Cohort Retention

## Business Question

**Do customers acquired in a given period continue purchasing in subsequent months?**

### Primary Aggregate

`agg_customer_cohort`

### Required Grain

```text
cohort_month
× activity_month
× months_since_acquisition
× region
```

The table should also retain:

```text
customer_key
```

where required for customer-level validation and correct cohort analysis.

---

## Required Columns

- `customer_key`
- `cohort_month`
- `activity_month`
- `months_since_acquisition`
- `region`
- `cohort_size`
- `active_customers`

---

## Cohort Definition

A customer's cohort is based on:

```text
first_purchase_date
```

truncated to month.

---

## Month 0

Month 0 represents the acquisition cohort itself.

Therefore:

```text
Retention at Month 0 = 100%
```

for a valid cohort.

---

## Month Index

The project uses an 11-month analytical horizon:

```text
0 → 11
```

Future months that have not yet occurred must not be treated as zero activity.

The cohort calendar should only create months that are actually available based on the maximum reporting month.

---

## Retention Rate

Preferred DAX calculation:

```text
Active Customers / Cohort Size
```

The denominator must remain the **original cohort size**, not the previous month's active customers.

---

## Missing Activity

If a valid month exists within the reporting horizon and no customers are active:

```text
active_customers = 0
```

This produces:

```text
retention_rate = 0%
```

For future/unavailable months, the row should not be created.

---

# 8. Domain 4 — Customer Segmentation

## Business Question

**Which customer segments generate the most value?**

### Primary Aggregate

`agg_customer_segment`

### Grain

```text
date × region × gender × age_band × customer_status
```

where the implemented project requires the date dimension.

### Stored Facts

- `total_customers`
- `repeat_customers`
- `total_orders`
- `total_revenue`

### Do NOT store as SQL KPIs

The following were deliberately removed from the aggregate because they are better calculated dynamically in Power BI:

- Average Lifetime Revenue
- Segment Revenue Share
- Purchase Frequency
- Average Gross Profit
- Average Orders Per Customer
- Revenue Per Customer
- Average Customer Revenue
- Average Order Value
- Repeat Purchase Rate
- Gross Profit per Customer

---

## Power BI Metrics

### Average Customer Revenue

```text
Total Revenue / Total Customers
```

### Purchase Frequency

```text
Total Orders / Total Customers
```

### Average Orders Per Customer

Same mathematical concept as purchase frequency for the selected customer population.

Do not maintain two measures with identical definitions.

### Segment Revenue Share

```text
Segment Revenue / Total Revenue
```

The denominator must respect the intended filter context.

### Average Lifetime Revenue

This should only be called **lifetime revenue** if the underlying customer-level revenue represents the customer's complete historical purchasing period.

If the table is filtered by reporting date, use a name such as:

```text
Average Customer Revenue
```

instead of incorrectly calling it lifetime revenue.

---

# 9. Domain 5 — Marketing & Campaign Performance

## Business Question

**Which campaigns generate customers and revenue efficiently, and where should marketing budget move?**

### Primary Aggregate

`agg_campaign_performance`

### Grain

```text
report_month
× campaign
× channel
× region
```

The exact implemented grain must be maintained consistently.

---

## Stored Marketing Facts

- `total_ad_spend`
- `acquisition_cost`
- `impressions`
- `clicks`
- `conversions`

---

## Stored Sales Facts

- `total_orders`
- `total_customers`
- `new_customers`
- `total_revenue`
- `gross_profit`

---

# 10. Acquisition Cost

## Definition

Only advertising spend associated with acquisition campaigns counts toward acquisition cost.

Conceptually:

```text
Acquisition Cost
=
SUM(ad_spend)
WHERE campaign_objective = 'Acquisition'
```

Use normalized matching where necessary:

```sql
LOWER(TRIM(campaign_objective)) = 'acquisition'
```

---

# 11. Customer Acquisition Cost (CAC)

## Definition

```text
CAC
=
Acquisition Cost
/
New Customers
```

Important:

**Total marketing spend must NOT be used as CAC cost when the spend also supports returning customers.**

Retargeting spend should not automatically be classified as acquisition spend.

---

# 12. Campaign Type vs Campaign Objective

These fields serve different analytical purposes.

## `campaign_type`

Describes campaign classification, such as:

```text
Acquisition
Retargeting
```

Use it for:

- campaign performance segmentation;
- comparing acquisition vs retargeting campaigns;
- dashboard filtering.

## `campaign_objective`

Describes the marketing purpose used to classify spend.

Use it to determine:

```text
acquisition_cost
```

These fields should not be treated as interchangeable.

---

# 13. Campaign Revenue

## Definition

Revenue generated by sales attributed to the campaign.

At the implemented project grain:

```text
SUM(fact_sales.net_sales)
```

grouped by:

- campaign;
- month;
- channel;
- region where required.

Campaign revenue is an additive fact.

---

# 14. ROAS

## Definition

```text
ROAS
=
Campaign Revenue
/
Advertising Spend
```

### Power BI

Calculate as a DAX measure.

Do not store a pre-calculated ROAS column in the aggregate.

---

# 15. Profit ROAS

Optional analytical KPI.

```text
Profit ROAS
=
Gross Profit
/
Advertising Spend
```

Only use this KPI if the dashboard specifically needs profitability of advertising spend.

It should not be confused with standard ROAS.

---

# 16. Domain 6 — Channel & Conversion Funnel

## Business Question

**Which channels generate traffic, engagement and conversions?**

### Primary Aggregate

`agg_channel_funnel_daily`

### Grain

```text
date × channel
```

---

## Stored Facts

- `impressions`
- `clicks`
- `conversions`
- `ad_spend`
- channel-attributed revenue where supported

---

## Power BI Metrics

### Click Through Rate

```text
Clicks / Impressions
```

### Conversion Rate

```text
Conversions / Clicks
```

### Cost Per Conversion

```text
Ad Spend / Conversions
```

These should be DAX measures.

---

# 17. Paid Traffic Definition

The current source data contains:

```text
impressions
clicks
conversions
```

Therefore the dashboard can measure **paid marketing funnel volume**.

It does NOT have sufficient data to claim:

- website sessions;
- page views;
- bounce rate;
- cart abandonment;
- checkout completion;
- product-view-to-purchase rate.

Those KPIs are excluded.

---

# 18. Channel Performance

Relevant metrics:

- Revenue
- Orders
- Customers
- Ad Spend
- Impressions
- Clicks
- Conversions
- ROAS
- Conversion Rate
- CAC where acquisition attribution is valid

Channel analysis should use `dim_channels` so that the same channel filter can propagate consistently across facts.

---

# 19. Executive KPI Layer

A separate `agg_executive_summary` table is **not required for the current project**.

The executive page should use:

- `agg_growth_daily`
- `agg_campaign_performance`
- `agg_customer_cohort`
- `agg_customer_segment`
- `agg_channel_funnel_daily`

through the Power BI semantic model.

This avoids creating another aggregate layer that duplicates existing facts.

---

# 20. Executive Overview KPIs

The Growth Executive Overview should focus on:

### Commercial

- Revenue
- Orders
- AOV
- Gross Profit
- Gross Margin %

### Customer

- New Customers
- Returning Customers
- Repeat Purchase Rate
- Retention Rate

### Marketing

- Acquisition Cost
- CAC
- Ad Spend
- ROAS

### Funnel

- Impressions
- Clicks
- Conversions
- Conversion Rate

---

# 21. KPIs Removed From This Project

The following were removed from the active KPI dictionary because the current source model does not support them reliably or they are outside the current project scope.

## Inventory

- Inventory Turnover
- Stockout Rate
- Overstock Rate
- Dead Stock
- Fast/Slow Moving Inventory
- Reorder Frequency
- Stockout Risk

## Logistics

- Delivery Time
- On-Time Delivery Rate
- Failed Delivery Rate
- Fulfillment Bottlenecks
- Order Processing Time

## Website Behaviour

- Website Sessions
- Bounce Rate
- Cart Abandonment
- Checkout Completion
- Product View → Purchase Rate

## Customer Sentiment

- Average Rating
- Review Volume
- Sentiment Score
- Complaint Categories

## Competitor Intelligence

- Price Competitiveness
- Competitor Price Index

These require additional source datasets.

---

# 22. KPI Ownership Matrix

| KPI | Primary Table | Layer |
|---|---|---|
| Revenue | `agg_growth_daily` / sales aggregate | DAX |
| Orders | `agg_growth_daily` | DAX |
| AOV | `agg_growth_daily` | DAX |
| Gross Profit | `agg_growth_daily` | DAX |
| Gross Margin % | `agg_growth_daily` | DAX |
| New Customers | `agg_growth_daily` / `agg_campaign_performance` | SQL fact + DAX aggregation |
| Returning Customers | `agg_growth_daily` | DAX |
| Repeat Purchase Rate | `agg_growth_daily` | DAX |
| Retention Rate | `agg_customer_cohort` | DAX |
| Cohort Size | `agg_customer_cohort` | SQL |
| Active Customers | `agg_customer_cohort` | SQL |
| Purchase Frequency | `agg_customer_segment` | DAX |
| Average Customer Revenue | `agg_customer_segment` | DAX |
| Segment Revenue Share | `agg_customer_segment` | DAX |
| Total Ad Spend | `agg_campaign_performance` | SQL fact |
| Acquisition Cost | `agg_campaign_performance` | SQL |
| CAC | `agg_campaign_performance` | DAX |
| Campaign Revenue | `agg_campaign_performance` | SQL fact |
| ROAS | `agg_campaign_performance` | DAX |
| Impressions | `agg_campaign_performance` / funnel | SQL fact |
| Clicks | `agg_campaign_performance` / funnel | SQL fact |
| Conversions | `agg_campaign_performance` / funnel | SQL fact |
| CTR | `agg_channel_funnel_daily` | DAX |
| Conversion Rate | `agg_channel_funnel_daily` | DAX |
| Cost Per Conversion | `agg_channel_funnel_daily` | DAX |

---

# 23. SQL vs DAX Rule

## SQL/dbt should handle

- joins;
- cleansing;
- deduplication;
- grain definition;
- additive aggregations;
- customer classification where required;
- cohort construction;
- acquisition-cost classification;
- dimensional enrichment;
- reporting-period construction.

## Power BI/DAX should handle

- ratios;
- percentages;
- averages;
- rates;
- shares;
- CAC;
- ROAS;
- AOV;
- purchase frequency;
- retention rate;
- segment revenue share;
- context-sensitive comparisons;
- time-intelligence calculations.

---

# 24. Data Grain Rules

Every aggregate table must have an explicitly defined grain.

### `agg_growth_daily`

Daily growth reporting by the implemented reporting dimensions.

### `agg_campaign_performance`

Monthly:

```text
month × campaign × channel × region
```

### `agg_customer_cohort`

```text
cohort_month × activity_month × months_since_acquisition × region
```

with customer-level activity retained where required for validation.

### `agg_customer_segment`

Reporting date ×:

```text
region × gender × age_band × customer_status
```

### `agg_channel_funnel_daily`

```text
date × channel
```

Never join aggregate tables directly merely because they share a date.

Different grains must be respected.

---

# 25. Power BI Relationship Principles

Use shared dimensions.

Preferred structure:

```text
                 dim_date
                    │
        ┌───────────┼────────────┐
        │           │            │
        ▼           ▼            ▼
agg_growth   agg_campaign   agg_channel
   daily      performance      funnel
        │
        │
        ▼
 customer / campaign / channel dimensions
```

Use:

- `dim_date`
- `dim_customers`
- `dim_campaigns`
- `dim_channels`
- `dim_products`

as dimensions rather than connecting aggregate tables directly to one another.

---

# 26. Metric Validation Rules

Before publishing a KPI:

### CAC

Verify:

```text
Acquisition Cost > 0
New Customers > 0
```

### Retention

Verify:

```text
Month 0 = 100%
```

and that future months are not represented as zero.

### AOV

Verify:

```text
AOV = Revenue / Orders
```

### ROAS

Verify:

```text
ROAS = Campaign Revenue / Ad Spend
```

### Purchase Frequency

Verify:

```text
Purchase Frequency = Orders / Customers
```

### Segment Revenue Share

Verify that, under the intended filter context:

```text
sum(segment shares) ≈ 100%
```

---

# 27. Final Active KPI Set

The project's core KPI set is therefore:

## Sales

- Revenue
- Orders
- AOV
- Gross Profit
- Gross Margin %

## Customer

- New Customers
- Returning Customers
- Repeat Purchase Rate
- Retention Rate
- Cohort Size
- Active Customers
- Purchase Frequency
- Average Customer Revenue
- Segment Revenue Share

## Marketing

- Ad Spend
- Acquisition Cost
- CAC
- Campaign Revenue
- ROAS
- Profit ROAS where required

## Funnel

- Impressions
- Clicks
- Conversions
- CTR
- Conversion Rate
- Cost Per Conversion

## Dimensions

- Date
- Region
- Gender
- Age Band
- Customer Status
- Campaign
- Campaign Type
- Campaign Objective
- Channel
- Product
- Category
- Sub-category
- Brand

---

# 28. Design Principle

The dashboard should answer four commercial questions:

```text
1. Are we growing?
        ↓
Revenue + Orders + AOV + Profitability

2. Are we acquiring customers efficiently?
        ↓
Acquisition Cost + New Customers + CAC + ROAS

3. Are acquired customers returning?
        ↓
Retention + Repeat Purchase + Cohorts

4. Where is performance concentrated?
        ↓
Region + Channel + Campaign + Customer Segment
```

This is the final analytical scope for the current E-commerce Operations Dashboard.
