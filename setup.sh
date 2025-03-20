#!/bin/bash

# Setup script to generate Natural Language Database Query Application
# This script creates all folders and files for the application

echo "Creating Natural Language Database Query Application..."

# Create project directory
mkdir -p nl-query-app
cd nl-query-app

# Create directory structure
mkdir -p frontend/public frontend/src
mkdir -p backend
mkdir -p database

# Create frontend files
cat > frontend/package.json << 'EOF'
{
  "name": "nl-query-frontend",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  }
}
EOF

cat > frontend/public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Natural Language Query App</title>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
EOF

cat > frontend/src/index.js << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

cat > frontend/src/index.css << 'EOF'
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background-color: #f5f7fa;
}
EOF

cat > frontend/src/App.js << 'EOF'
import React, { useState } from 'react';
import './App.css';

function App() {
  const [query, setQuery] = useState('');
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    
    try {
      const response = await fetch('http://localhost:5000/api/query', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ query }),
      });
      
      const data = await response.json();
      setResult(data);
    } catch (error) {
      console.error('Error:', error);
      setResult({ error: 'Failed to process your query. Please try again.' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Database Query Assistant</h1>
        <p>Ask questions about orders and inventory in plain English</p>
      </header>
      
      <main>
        <form onSubmit={handleSubmit}>
          <div className="query-input">
            <input
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Example: Show me all pending orders for customer Smith"
              required
            />
            <button type="submit" disabled={loading}>
              {loading ? 'Processing...' : 'Search'}
            </button>
          </div>
        </form>
        
        {result && (
          <div className="result-container">
            {result.error ? (
              <div className="error-message">{result.error}</div>
            ) : result.message ? (
              <div className="info-message">{result.message}</div>
            ) : (
              <>
                <h2>{result.question}</h2>
                <div className="result-data">
                  {result.data && result.data.length > 0 ? (
                    <table>
                      <thead>
                        <tr>
                          {Object.keys(result.data[0]).map(key => (
                            <th key={key}>{key}</th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {result.data.map((item, index) => (
                          <tr key={index}>
                            {Object.values(item).map((value, i) => (
                              <td key={i}>{value !== null ? value : 'N/A'}</td>
                            ))}
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  ) : (
                    <p>No data found matching your query.</p>
                  )}
                </div>
              </>
            )}
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
EOF

cat > frontend/src/App.css << 'EOF'
.App {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.App-header {
  text-align: center;
  margin-bottom: 2rem;
}

.App-header h1 {
  color: #2c3e50;
  margin-bottom: 0.5rem;
}

.App-header p {
  color: #7f8c8d;
  font-size: 1.1rem;
}

.query-input {
  display: flex;
  margin-bottom: 2rem;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  border-radius: 8px;
  overflow: hidden;
}

.query-input input {
  flex: 1;
  padding: 1rem;
  font-size: 1rem;
  border: none;
  outline: none;
}

.query-input button {
  padding: 1rem 2rem;
  background-color: #3498db;
  color: white;
  border: none;
  cursor: pointer;
  font-size: 1rem;
  transition: background-color 0.3s;
}

.query-input button:hover {
  background-color: #2980b9;
}

.result-container {
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 15px rgba(0, 0, 0, 0.1);
  padding: 2rem;
}

table {
  width: 100%;
  border-collapse: collapse;
}

th, td {
  padding: 0.75rem 1rem;
  border-bottom: 1px solid #ecf0f1;
  text-align: left;
}

th {
  background-color: #f8f9fa;
  font-weight: 600;
}
EOF

cat > frontend/Dockerfile << 'EOF'
FROM node:18-alpine as build

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

cat > frontend/nginx.conf << 'EOF'
server {
    listen 80;
    
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://backend:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Create backend files
cat > backend/app.py << 'EOF'
from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
import psycopg2.extras
import os
import re
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords

app = Flask(__name__)
CORS(app)

# Download NLTK resources on startup
nltk.download('punkt', quiet=True)
nltk.download('stopwords', quiet=True)

# Load sentence transformer model
print("Loading language model...")
model = SentenceTransformer('all-MiniLM-L6-v2')
print("Model loaded successfully!")

# Database connection function
def get_db_connection():
    conn = psycopg2.connect(
        host=os.getenv('DB_HOST', 'db'),
        database=os.getenv('DB_NAME', 'retail_db'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'postgres')
    )
    return conn

# Get database schema information
def get_db_schema():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    schema = {}
    cursor.execute("""
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
    """)
    tables = cursor.fetchall()
    
    for table in tables:
        table_name = table[0]
        cursor.execute(f"""
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = '{table_name}'
        """)
        columns = cursor.fetchall()
        schema[table_name] = {col[0]: col[1] for col in columns}
    
    cursor.close()
    conn.close()
    
    return schema

# Predefined query templates with natural language descriptions
query_templates = [
    {
        "description": "Show all pending orders",
        "sql": "SELECT o.order_id, c.first_name, c.last_name, o.order_date, o.total_amount FROM orders o JOIN customers c ON o.customer_id = c.customer_id WHERE o.status = 'pending'",
        "parameters": []
    },
    {
        "description": "Find orders for a specific customer by last name",
        "sql": "SELECT o.order_id, o.order_date, o.status, o.total_amount FROM orders o JOIN customers c ON o.customer_id = c.customer_id WHERE c.last_name = '{customer_last_name}'",
        "parameters": ["customer_last_name"]
    },
    {
        "description": "Check inventory for a product by name",
        "sql": "SELECT p.name, i.quantity, i.warehouse FROM products p JOIN inventory i ON p.product_id = i.product_id WHERE p.name LIKE '%{product_name}%'",
        "parameters": ["product_name"]
    },
    {
        "description": "List products above a certain price",
        "sql": "SELECT name, price, category FROM products WHERE price > {min_price}",
        "parameters": ["min_price"]
    },
    {
        "description": "Show all products in a category",
        "sql": "SELECT name, price, sku FROM products WHERE category = '{category}'",
        "parameters": ["category"]
    },
    {
        "description": "Show low stock items (less than certain quantity)",
        "sql": "SELECT p.name, i.quantity, i.warehouse FROM products p JOIN inventory i ON p.product_id = i.product_id WHERE i.quantity < {threshold}",
        "parameters": ["threshold"]
    },
    {
        "description": "List all customers",
        "sql": "SELECT customer_id, first_name, last_name, email FROM customers",
        "parameters": []
    }
]

# Create embeddings for all query templates
template_descriptions = [template["description"] for template in query_templates]
template_embeddings = model.encode(template_descriptions)

# Extract parameters from user query
def extract_parameters(query, schema):
    # Simple preprocessing
    processed = query.lower()
    processed = re.sub(r'[^\w\s]', ' ', processed)
    
    params = {}
    
    # Extract customer last name
    name_match = re.search(r'customer (\w+)', processed)
    if name_match:
        params["customer_last_name"] = name_match.group(1).title()
    
    # Extract product name
    product_match = re.search(r'product (\w+)', processed)
    if product_match:
        params["product_name"] = product_match.group(1)
    
    # Extract price thresholds
    price_match = re.search(r'(\d+\.?\d*)', processed)
    if price_match and ('price' in processed or 'cost' in processed):
        params["min_price"] = float(price_match.group(1))
    
    # Extract quantity thresholds
    quantity_match = re.search(r'(\d+) (item|product|stock)', processed)
    if quantity_match:
        params["threshold"] = int(quantity_match.group(1))
    
    # Extract categories
    category_pattern = r'\b(Electronics|Audio|Kitchen|Footwear|Furniture)\b'
    category_match = re.search(category_pattern, query, re.IGNORECASE)
    if category_match:
        params["category"] = category_match.group(1)
    
    return processed, params

# Find matching template using embeddings
def find_matching_template(query, params):
    # Encode user query
    query_embedding = model.encode([query])
    
    # Calculate similarity with templates
    similarities = cosine_similarity(query_embedding, template_embeddings)[0]
    
    # Get best match
    best_match_idx = np.argmax(similarities)
    best_match_score = similarities[best_match_idx]
    
    # Check if similarity is high enough
    if best_match_score > 0.5:
        template = query_templates[best_match_idx]
        
        # Check for missing parameters
        missing_params = []
        for param in template["parameters"]:
            if param not in params:
                missing_params.append(param)
        
        if missing_params:
            return None, f"Missing parameters: {', '.join(missing_params)}"
        
        return template, None
    
    return None, "Could not match your query to any known patterns."

# Fallback: Keyword-based query builder
def build_keyword_query(processed_query, params, schema):
    # Extract keywords
    stop_words = set(stopwords.words('english'))
    tokens = word_tokenize(processed_query)
    keywords = [word for word in tokens if word.lower() not in stop_words]
    
    # Determine which tables to query
    tables_to_query = []
    for table in schema.keys():
        table_singular = table[:-1] if table.endswith('s') else table
        if table_singular in keywords or table in keywords:
            tables_to_query.append(table)
    
    # If no tables found, guess based on keywords
    if not tables_to_query:
        if any(word in keywords for word in ['order', 'purchase']):
            tables_to_query.append('orders')
        elif any(word in keywords for word in ['item', 'product']):
            tables_to_query.append('products')
        elif any(word in keywords for word in ['stock', 'inventory']):
            tables_to_query.append('inventory')
        elif any(word in keywords for word in ['customer', 'client']):
            tables_to_query.append('customers')
    
    # Default to products if still no tables
    if not tables_to_query:
        tables_to_query.append('products')
    
    # Build query
    table = tables_to_query[0]
    sql = f"SELECT * FROM {table} LIMIT 100"
    
    return sql

# Generate SQL from natural language
def generate_sql(nl_query, db_schema):
    # Process query and extract parameters
    processed_query, params = extract_parameters(nl_query, db_schema)
    
    # Try to match a template
    template, error = find_matching_template(processed_query, params)
    
    if template:
        # Fill template with parameters
        sql = template["sql"]
        for param in template["parameters"]:
            placeholder = '{' + param + '}'
            if param in params:
                sql = sql.replace(placeholder, str(params[param]))
        return sql, None
    
    # Fallback to keyword approach
    try:
        sql = build_keyword_query(processed_query, params, db_schema)
        return sql, None
    except Exception as e:
        return None, f"Could not generate SQL: {str(e)}"

# Execute SQL query
def execute_query(sql):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    
    try:
        cursor.execute(sql)
        results = [dict(row) for row in cursor.fetchall()]
        return results, None
    except Exception as e:
        return None, f"Error executing query: {str(e)}"
    finally:
        cursor.close()
        conn.close()

# Format results
def format_results(results, nl_query):
    if not results or len(results) == 0:
        return {
            "question": nl_query,
            "message": "No information available for your query.",
            "data": []
        }
    
    return {
        "question": nl_query,
        "data": results
    }

@app.route('/api/query', methods=['POST'])
def process_query():
    data = request.json
    nl_query = data.get('query', '')
    
    if not nl_query:
        return jsonify({"error": "No query provided"}), 400
    
    # Get database schema
    db_schema = get_db_schema()
    
    # Generate SQL query
    sql, error = generate_sql(nl_query, db_schema)
    if error:
        return jsonify({"error": error}), 400
    
    # Execute SQL query
    results, error = execute_query(sql)
    if error:
        return jsonify({"error": error}), 400
    
    # Format and return results
    response = format_results(results, nl_query)
    return jsonify(response)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

cat > backend/requirements.txt << 'EOF'
flask==2.2.3
flask-cors==3.0.10
psycopg2-binary==2.9.5
sentence-transformers==2.2.2
scikit-learn==1.1.2
nltk==3.7
numpy==1.23.3
EOF

cat > backend/Dockerfile << 'EOF'
FROM python:3.9

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
EOF

# Create database files
cat > database/init.sql << 'EOF'
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
EOF

cat > database/Dockerfile << 'EOF'
FROM postgres:13

COPY init.sql /docker-entrypoint-initdb.d/
ENV POSTGRES_DB=retail_db
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
EOF

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  frontend:
    build: ./frontend
    ports:
      - "80:80"
    depends_on:
      - backend
    networks:
      - app-network

  backend:
    build: ./backend
    ports:
      - "5000:5000"
    depends_on:
      - db
    environment:
      - DB_HOST=db
      - DB_NAME=retail_db
      - DB_USER=postgres
      - DB_PASSWORD=postgres
    networks:
      - app-network

  db:
    build: ./database
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - app-network

networks:
  app-network:
    driver: bridge

volumes:
  postgres_data:
EOF

# Create a README.md file
cat > README.md << 'EOF'
# Natural Language Database Query Application

This application allows users to query a database using natural language. It translates English queries into SQL and returns formatted results.

## Running the Application

1. Run the following command:
2. Access the application at: http://localhost

3. Example queries to try:
- "Show all pending orders"
- "Find orders for customer Smith"
- "What's the inventory status of laptops?"
- "List products that cost more than $200"
- "Show me all products in the Electronics category"
EOF

echo "Application files created successfully in nl-query-app directory."
echo "To run the application: cd nl-query-app && docker-compose up --build"