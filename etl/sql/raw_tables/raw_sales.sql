CREATE TABLE IF NOT EXISTS raw_sales (
    order_id VARCHAR(50) NOT NULL,
    customer_id VARCHAR(50),
    customer_status VARCHAR(50),
    product_id VARCHAR(50),
    product_name VARCHAR(255),
    category VARCHAR(255),
    ship_mode VARCHAR(100),
    quantity INT,
    discount DECIMAL(12,2),
    unit_cost DECIMAL(12,2),
    price DECIMAL(12,2),
    refund_status VARCHAR(100),
    revenue DECIMAL(12,2),
    order_date DATE,
    channel VARCHAR(100),
    campaign_id VARCHAR(50),

    PRIMARY KEY (order_id)
);