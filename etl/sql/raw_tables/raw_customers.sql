CREATE TABLE IF NOT EXISTS raw_customers (
    customer_id VARCHAR(50) NOT NULL,
    gender VARCHAR(100),
    age INT,
    country VARCHAR(100),
    region VARCHAR(100),
    city VARCHAR(100),
    acquisition_date DATE,
    acquisition_channel VARCHAR(250),
    acquisition_campaign VARCHAR(100),

    PRIMARY KEY (customer_id)
);