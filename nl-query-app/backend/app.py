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
