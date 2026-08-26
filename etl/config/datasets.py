DATASETS = {
    "customers": {
            "source": "dim_customers",
            "target": "raw_customers",
            "load_type": "full",
            "watermark_column": "acquisition_date",
            "schema": "customers"
            
        },
  
    "sales": {
        "source": "fact_sales",
        "target": "raw_sales",
        "load_type": "incremental",
        "watermark_column": "order_date",
        "schema": "sales"
        
    },
    
    
    "products": {
        "source": "dim_products",
        "target": "raw_products",
        "load_type": "full",
        "schema": "products",
        
    },
    "campaigns": {
        "source": "dim_campaign",
        "target": "raw_campaigns",
        "load_type": "full",
        "schema": "campaigns",
        
    },
    "channels": {
        "source": "dim_channel",
        "target": "raw_channels",
        "load_type": "full",
        "schema": "channels",
        
    },
    
    "marketing": {
        "source": "fact_marketing",
        "target": "raw_marketing",
        "load_type": "incremental",
        "watermark_column": "date",
        "schema": "marketing",
        
    }
}
