CREATE TABLE IF NOT EXISTS raw_campaigns (
    campaign_id VARCHAR(50) NOT NULL,
    campaign_type VARCHAR(100),
    channel VARCHAR(100),
    start_date DATE,
    end_date DATE,
    total_revenue DECIMAL(12,2),
    campaign_name VARCHAR(255),
    budget DECIMAL(12,2),

    PRIMARY KEY (campaign_id)
);