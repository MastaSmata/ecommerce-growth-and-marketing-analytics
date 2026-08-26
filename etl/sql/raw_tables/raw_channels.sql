CREATE TABLE IF NOT EXISTS raw_channels (
  channel_name VARCHAR(255) NOT NULL,
  channel_category VARCHAR(100),
  traffic_type VARCHAR(100),
  PRIMARY KEY (channel_name)
);
