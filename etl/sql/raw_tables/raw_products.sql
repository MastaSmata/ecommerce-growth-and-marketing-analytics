CREATE TABLE IF NOT EXISTS raw_products (
  product_id VARCHAR(50) NOT NULL,
  product_name VARCHAR(255),
  price DECIMAL(12,2),
  sub_category VARCHAR(100),
  category VARCHAR(100),
  brand VARCHAR(100),
  supplier_id VARCHAR(50),
  unit_cost DECIMAL(12,2),
  PRIMARY KEY (product_id)
);
