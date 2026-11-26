USE olist_dw;

-- 1. Verify exact row counts across all 9 loaded tables
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'geolocation', COUNT(*) FROM geolocation
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation;

-- 2. Add Indexes on high-traffic Join Keys so queries run instantaneously
CREATE INDEX idx_orders_order_id ON orders(order_id(50));
CREATE INDEX idx_orders_customer_id ON orders(customer_id(50));
CREATE INDEX idx_items_order_id ON order_items(order_id(50));
CREATE INDEX idx_items_product_id ON order_items(product_id(50));
CREATE INDEX idx_items_seller_id ON order_items(seller_id(50));
CREATE INDEX idx_payments_order_id ON order_payments(order_id(50));
CREATE INDEX idx_reviews_order_id ON order_reviews(order_id(50));
CREATE INDEX idx_customers_customer_id ON customers(customer_id(50));
CREATE INDEX idx_customers_unique_id ON customers(customer_unique_id(50));