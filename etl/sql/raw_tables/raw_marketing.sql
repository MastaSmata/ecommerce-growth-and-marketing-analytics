CREATE TABLE IF NOT EXISTS raw_marketing (
    ads_id VARCHAR(50) NOT NULL,
    campaign_id VARCHAR(50) NOT NULL,
    channel_name VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    ad_spend DECIMAL(12,2),
    impressions INT,
    clicks INT,
    conversions INT,
    campaign_type VARCHAR(100),

    PRIMARY KEY (ads_id)
);