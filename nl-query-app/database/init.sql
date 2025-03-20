-- Create tables
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    category VARCHAR(50),
    sku VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE inventory (
    inventory_id SERIAL PRIMARY KEY,
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL,
    warehouse VARCHAR(50)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')) DEFAULT 'pending',
    total_amount DECIMAL(12, 2)
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id),
    product_id INTEGER REFERENCES products(product_id),
    quantity INTEGER NOT NULL,
    price_per_unit DECIMAL(10, 2) NOT NULL
);

-- Insert sample data
-- Customers
INSERT INTO customers (first_name, last_name, email, phone, address) VALUES
('John', 'Smith', 'john.smith@example.com', '555-123-4567', '123 Main St, Anytown, USA'),
('Emily', 'Johnson', 'emily.johnson@example.com', '555-234-5678', '456 Oak Ave, Somewhere, USA'),
('Michael', 'Williams', 'michael.williams@example.com', '555-345-6789', '789 Pine Rd, Nowhere, USA'),
('Sarah', 'Brown', 'sarah.brown@example.com', '555-456-7890', '101 Maple Dr, Anywhere, USA'),
('David', 'Jones', 'david.jones@example.com', '555-567-8901', '202 Cedar Ln, Everywhere, USA');

-- Products
INSERT INTO products (name, description, price, category, sku) VALUES
('Laptop Pro', '15-inch professional laptop with 16GB RAM', 1299.99, 'Electronics', 'LAP-PRO-001'),
('Smartphone X', 'Latest smartphone with 128GB storage', 899.99, 'Electronics', 'PHN-X-001'),
('Wireless Headphones', 'Noise-cancelling wireless headphones', 249.99, 'Audio', 'AUDIO-WH-001'),
('Coffee Maker', 'Programmable coffee maker with thermal carafe', 79.99, 'Kitchen', 'KTCH-CM-001'),
('Running Shoes', 'Lightweight running shoes with cushioned soles', 129.99, 'Footwear', 'SHOE-RUN-001'),
('Office Chair', 'Ergonomic office chair with lumbar support', 199.99, 'Furniture', 'FURN-CHR-001'),
('Tablet Mini', '8-inch tablet with 64GB storage', 349.99, 'Electronics', 'TAB-MINI-001'),
('External Hard Drive', '2TB external hard drive', 89.99, 'Electronics', 'STOR-HDD-001');

-- Inventory
INSERT INTO inventory (product_id, quantity, warehouse) VALUES
(1, 50, 'North'),
(2, 75, 'North'),
(3, 100, 'East'),
(4, 30, 'West'),
(5, 60, 'South'),
(6, 25, 'West'),
(7, 45, 'North'),
(8, 80, 'East');

-- Orders
INSERT INTO orders (customer_id, order_date, status, total_amount) VALUES
(1, CURRENT_TIMESTAMP - INTERVAL '10 day', 'delivered', 1299.99),
(2, CURRENT_TIMESTAMP - INTERVAL '7 day', 'shipped', 1149.98),
(3, CURRENT_TIMESTAMP - INTERVAL '5 day', 'processing', 329.98),
(4, CURRENT_TIMESTAMP - INTERVAL '2 day', 'pending', 199.99),
(5, CURRENT_TIMESTAMP - INTERVAL '1 day', 'pending', 349.99),
(1, CURRENT_TIMESTAMP - INTERVAL '1 day', 'pending', 89.99);

-- Order Items
INSERT INTO order_items (order_id, product_id, quantity, price_per_unit) VALUES
(1, 1, 1, 1299.99),
(2, 2, 1, 899.99),
(2, 3, 1, 249.99),
(3, 4, 1, 79.99),
(3, 8, 1, 89.99),
(4, 6, 1, 199.99),
(5, 7, 1, 349.99),
(6, 8, 1, 89.99);