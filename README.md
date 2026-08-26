# E-Commerce Growth & Marketing Analytics

## End-to-end Business Intelligence & Analytics Engineering Project

### Table of Contents

1. [Project Overview](#1-project-overview)
2. [Featuring](#2-featuring)
3. [Tech Stack](#3-tech-stack)
4. [Data &amp; Analytics Architecture](#4-data--analytics-architecture)
5. [Power BI Dashboard](#5-power-bi-dashboard)
6. [Stakeholder Requirement Elicitation &amp; Scope of Work](#6-stakeholder-requirement-elicitation--scope-of-work)
7. [Data Warehouse Check &amp; KPI Dictionary](#7-data-warehouse-check--kpi-dictionary)
8. [ETL &amp; dbt Logic](#8-etl--dbt-logic)
9. [Automated Pipeline &amp; Power BI Refresh](#9-automated-pipeline--power-bi-refresh)

---

## 1. Project Overview

### Business Problem

An **eCommerce company’s Growth and Marketing department** was scaling across multiple digital channels, including paid search, paid social, email marketing, and affiliate campaigns. However, there was no unified way to evaluate whether this growth was **profitable, efficient, and sustainable**.

Marketing performance was primarily assessed using top-line revenue and platform-level metrics, which made it difficult for the Growth team to understand:

- Whether customer acquisition was cost-efficient across channels
- Whether new customers were generating long-term value or only one-time purchases
- How discounting and promotions were impacting true profitability
- Which marketing channels were driving high-quality vs low-quality customers

As a result, the Growth and Marketing teams lacked a consolidated, data-driven view of **customer acquisition efficiency, retention behaviour, and revenue quality**.

### Business Goals

The project aimed to build a centralized analytics system for the **Growth and Marketing department** to enable better decision-making across acquisition and retention and growth strategies. The system was designed to help the team:

- Evaluate the efficiency of customer acquisition across marketing channels (paid search, paid social, email, affiliate).
- Understand customer retention, repeat purchase behaviour, and cohort performance.
- Connect acquisition sources with long-term customer value (LTV) and profitability.
- Monitor revenue quality, including the impact of discounts and promotions.
- Provide a consistent, single source of truth for marketing and growth performance.

### Business Questions

The solution was designed to help the Growth and Marketing team answer three core questions:

1. **Are we acquiring customers profitably across each marketing channel?**
2. **Do acquired customers return and generate sustainable long-term value?**
3. **Is revenue growth driven by efficient acquisition, or inflated by discounts and low-quality traffic?**

### Project Outcome

The project transforms fragmented eCommerce data (marketing, sales, and customer data) into a **centralized analytics and Power BI reporting system** for the Growth and Marketing department. This enables the team to clearly understand acquisition efficiency, customer quality, and revenue sustainability, and make more informed decisions on marketing investment and strategy.

---

## 2. Featuring

* Stakeholder Management
* KPI Selection & Engineering
* Python ETL Pipeline
* SQL Data Warehouse
* dbt Transformations
* Power BI Dashboard
* Automated Refreshing
* Customer Cohort Analysis
* Campaign Performance Analysis
* Customer Segmentation

---

## 3. Tech Stack

* Python
* SQL
* dbt
* Google BigQuery
* Power BI
* GitHub Actions

---

## 4. Data & Analytics Architecture

### Data Pipeline

```text
Source Data
(Aiven PostgreSQL Database)

    ↓
Python ETL

    ↓
BigQuery Raw Tables

    ↓
dbt Transformation Layer

    ↓
Fact Tables

    ↓
Aggregate Tables

    ↓
Power BI Semantic Model

    ↓
DAX Measures

    ↓
Dashboard
```

### Automation Layer

```text
GitHub Actions
        ↓
Automated Pipeline Execution
        ↓
BigQuery Data Refresh
        ↓
Power BI Auto Refresh
```

---

## 5. Power BI Dashboard

The dashboard is a  **modern, dark-themed analytical workspace designed for exploration, diagnosis, and optimization** . Rather than focusing primarily on high-level executive reporting, it provides a deeper level of analytical detail for users who need to explore performance, understand its underlying drivers, diagnose performance gaps, and identify opportunities for improvement. It is specifically designed for **marketing, growth, and CRM teams** to monitor key performance metrics, analyze customer and campaign behavior, and support data-driven growth decisions.

### Dashboard Page 1 — Growth Performance Overview

<img src="https://github.com/MastaSmata/ecommerce-marketing-performance-analytics/blob/main/dashboard/screenshots/page%201.png" width="100%" />

Provides a consolidated view of revenue growth, customer acquisition efficiency, order performance, and retention. The page is designed for monthly  review, helping leadership assess whether growth is being driven by efficient customer acquisition and repeat purchasing.

### Dashboard Page 2 — Channel & Campaign Performance

<img src="https://github.com/MastaSmata/ecommerce-marketing-performance-analytics/blob/main/dashboard/screenshots/page%202.png" width="100%" />

Evaluates marketing spend, revenue, ROAS, campaign profitability, and acquisition efficiency across channels and campaigns. It helps growth and performance-marketing teams identify high-performing campaigns, investigate inefficient spend, and determine where marketing budget should be increased, reduced, or reallocated.

### Dashboard Page 3 — Customer Retention & Cohorts

<img src="https://github.com/MastaSmata/ecommerce-marketing-performance-analytics/blob/main/dashboard/screenshots/page%203.png" width="100%" />

Analyzes customer retention, repeat purchasing, and cohort behavior over time. The page helps CRM teams determine whether newly acquired customers are developing into repeat customers and identify changes in retention performance across acquisition cohorts.

### Dashboard Page 4 — Customer Segmentation & Regional Analysis

<img src="https://github.com/MastaSmata/ecommerce-marketing-performance-analytics/blob/main/dashboard/screenshots/page%204.png" width="100%" />

Examines customer value, purchasing behavior, customer segments, and regional revenue performance. It helps identify the customer groups and geographic markets contributing the most value, supporting targeted CRM strategies and prioritization of high-value customer segments.

---

## 6. Stakeholder Requirement Elicitation & Scope of Work

The project scope was developed through a structured **stakeholder engagement and requirements-gathering process** with the business stakeholders responsible for growth, marketing, customer performance, and commercial decision-making.

Stakeholder discussions were used to understand the business objectives, identify the key performance challenges, define the decisions the dashboard needed to support, and translate those requirements into measurable KPIs and analytical outputs.

The agreed requirements were then consolidated into a formal **Statement of Work (SOW)**, which defined the project's:

- Business objectives
- Analytical requirements
- KPI requirements
- Data requirements
- Dashboard and reporting requirements
- Technical deliverables
- Automation and refresh requirements
- Project scope and boundaries

The SOW served as the primary reference throughout development, ensuring that the technical implementation remained aligned with the original business requirements.

📄 **[View the Full Scope of Work →](https://github.com/MastaSmata/ecommerce-marketing-performance-analytics/blob/main/docs/Scope_of_Work.docx)**

The detailed SOW provides the complete specification of the project, including the agreed deliverables, analytical scope, KPI requirements, and implementation expectations.

---

## 7. Data Warehouse Check & KPI Dictionary

Before development began, the available datasets were assessed against the **data and KPI requirements established during the stakeholder discovery and SOW phases**.

The assessment focused on whether the available source tables contained the required fields, relationships, dates, and business attributes needed to calculate the proposed KPIs reliably. Where a KPI could not be supported by the available data, it was identified and removed from scope rather than being estimated or artificially derived.

Following the data assessment, a **KPI Dictionary** was developed to establish a consistent definition for every approved KPI. Each KPI was mapped to its business purpose, required data elements, calculation logic, and analytical source, providing a single reference point for subsequent SQL, dbt, and Power BI development.

This ensured that the final warehouse and reporting layer were built around **validated business requirements and measurable data**, rather than assumptions.

📄 **[View the KPI Dictionary →](https://github.com/MastaSmata/ecommerce-marketing-performance-analytics/blob/main/docs/kpi_dictionary.md)**

---

## 8. ETL & dbt Logic

### 1. ETL Principles

The ETL pipeline extracts and prepares data from the **Aiven PostgreSQL database** using consistent data engineering principles:

- 🔌 **ETL Process** — Connect to the source database to extract operational data, clean and validate it, apply necessary transformations, and load it into the SQL warehouse while preserving structure and relationships.
- 🧭 **Incremental Loading (Watermarking)** — Introduced watermarking to support efficient incremental data loads by tracking the latest processed timestamp or key value, ensuring only new or updated records are extracted and processed in subsequent ETL runs.

### 2. dbt Transformation & KPI Logic

dbt is used to transform the warehouse data into **analytical marts and aggregate tables**, with a deliberate separation between **SQL-engineered metrics** and **Power BI/DAX metrics**.

- **Staging Layer** — One `stg_*` model per source table (`stg_customers`, `stg_products`, `stg_campaigns`, `stg_channels`, `stg_sales`, `stg_marketing`), applying consistent cleaning (trimming, casing, type-safe casts) and deduplication.
- **Dimension Layer** — Five conformed dimensions: `dim_customers`, `dim_products`, `dim_campaigns`, `dim_channels`, `dim_date`, each with a generated surrogate key and an "unknown"/"unattributed" member so orphan or unattributed fact rows are never silently dropped.
- **Fact Layer** — Two grain-preserving fact tables: `fact_sales` (one row per order line) and `fact_marketing` (one row per ad-spend record).
- **Aggregate Layer** — Six pre-calculated aggregate tables at their appropriate grain: `agg_growth_daily`, `agg_channel_funnel_daily`, `agg_campaign_performance`, `agg_channel_performance`, `agg_customer_segment`, and `agg_customer_cohort`.
- **SQL Metrics** — Metrics that form part of the warehouse's analytical layer are calculated in dbt, including revenue, gross profit, CAC inputs, retention inputs, and conversion-funnel inputs.
- **DAX Metrics** — Power BI is reserved for measures that require interactive filter context, aggregation across the prepared tables, or presentation-layer calculations (e.g. repeat purchase rate, ROAS).

**Principle:** SQL/dbt handles **data preparation and reusable business logic**, while DAX handles **Power BI semantic-layer calculations and interactive analysis**.

---

## 9. Automated Pipeline & Power BI Refresh

The project includes an automated CI/CD pipeline using **GitHub Actions** to move the analytics workflow from manual execution to a scheduled, production-style process.

### Automation Architecture

```text
GitHub Actions
      │
      ▼
OIDC Authentication
      │
      ▼
Google Cloud Workload Identity Federation
      │
      ▼
Service Account
      │
      ▼
Python ETL
      │
      ▼
BigQuery
      │
      ▼
dbt Transformations
      │
      ▼
Power BI Semantic Model Refresh (Daily Refresh — 6:00 AM)
```

---

### GitHub Actions

The workflow automates the complete analytics pipeline:

1. Checks out the repository.
2. Authenticates to Google Cloud using **Workload Identity Federation (OIDC)**.
3. Sets up Python and installs project dependencies.
4. Executes the Python ETL pipeline.
5. Loads and updates warehouse data in **BigQuery**.
6. Installs and executes **dbt**.
7. Runs `dbt deps`, `dbt run`, and `dbt test`.
8. Executes the Power BI refresh script.
9. Reports successful pipeline completion.

The workflow uses **GitHub repository secrets** for external credentials and configuration values.

No `.env` files or Google service-account JSON keys are committed to the repository.

---

### Google Cloud Authentication

Authentication between GitHub Actions and Google Cloud is implemented using **Workload Identity Federation** rather than long-lived service-account keys.

GitHub Actions authenticates using GitHub's **OIDC identity token**, which Google Cloud validates before allowing the workflow to impersonate the designated service account.

This provides:

- **Keyless authentication**
- **Short-lived credentials**
- **Repository-level access restrictions**
- **No service-account JSON keys stored in GitHub**

This approach reduces credential-management risk while maintaining controlled access to Google Cloud resources.

---

### Power BI Automated Refresh

The final stage of the analytics pipeline is handled by **Power BI Service’s built-in scheduled refresh**.

The semantic model is configured to refresh **daily at 6:00 AM**, after the upstream data pipeline has completed:

This ensures that Power BI regularly consumes the latest successfully processed data from the BigQuery/dbt warehouse rather than relying on manual report refreshes.
