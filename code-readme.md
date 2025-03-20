# Line-by-Line Explanation of Natural Language Database Query Application

This code creates a web application that can translate natural language questions into SQL queries and execute them against a database. Here's a detailed breakdown of each major component:

## Setup and Imports

```python
# Import the monkey patch before anything else
import monkey_patch
```
This imports a custom module that modifies SSL behavior. A monkey patch means modifying the behavior of existing code at runtime. In this case, it disables SSL verification for all network requests, which can be helpful when dealing with certificate issues.

```python
# Now import all your other modules
from flask import Flask, request, jsonify
from flask_cors import CORS
```
These lines import Flask (a Python web framework) and related components:
- `Flask`: The core framework for creating web applications
- `request`: Handles HTTP requests
- `jsonify`: Converts Python objects to JSON responses
- `CORS`: Cross-Origin Resource Sharing, allows web requests from different domains

```python
import psycopg2
import psycopg2.extras
```
These import PostgreSQL database adapter for Python. `psycopg2.extras` provides additional features like returning results as dictionaries.

```python
import os
import re
```
Standard Python modules:
- `os`: Provides operating system functionality, used for environment variables
- `re`: For regular expression pattern matching, used when parsing queries

```python
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
```
Machine learning and NLP libraries:
- `numpy`: Scientific computing library for numerical operations
- `SentenceTransformer`: Creates high-quality vector embeddings of text
- `cosine_similarity`: Measures similarity between vectors

```python
import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
```
Natural Language Toolkit (NLTK) for text processing:
- `word_tokenize`: Splits text into individual words
- `stopwords`: Common words to filter out (e.g., "the", "and")

## NLTK Setup

```python
# Try to download NLTK data with SSL verification disabled
try:
    nltk.download('punkt', quiet=True)
    nltk.download('stopwords', quiet=True)
except:
    print("NLTK download failed, but continuing...")
```
Downloads necessary NLTK resources:
- `punkt`: For tokenizing text into words
- `stopwords`: A collection of common words in English
The try/except ensures the program continues even if downloads fail.

## Flask App Initialization

```python
# Create Flask app with correct __name__ variable (double underscores)
app = Flask(__name__)
```
Creates a new Flask web application. The `__name__` variable tells Flask where to look for templates, static files, etc.

## JSON Encoder for Database Types

```python
# Import necessary modules
from decimal import Decimal
import json
import datetime
import uuid
```
These imports are for handling special data types that need custom JSON serialization.

```python
# Create a comprehensive custom JSON encoder
class CustomJSONEncoder(json.JSONEncoder):
    def default(self, obj):
        # Handle Decimal (money, numeric values)
        if isinstance(obj, Decimal):
            return float(obj)
        
        # Handle datetime and date objects
        elif isinstance(obj, datetime.datetime):
            return obj.isoformat()
        elif isinstance(obj, datetime.date):
            return obj.isoformat()
        elif isinstance(obj, datetime.time):
            return obj.isoformat()
        
        # Handle UUID objects (often used for IDs)
        elif isinstance(obj, uuid.UUID):
            return str(obj)
            
        # Handle bytes or bytearrays (binary data)
        elif isinstance(obj, (bytes, bytearray)):
            return obj.decode('utf-8', errors='replace')
            
        # Handle sets by converting to lists
        elif isinstance(obj, set):
            return list(obj)

        # Handle any other custom objects that might implement a to_json method
        elif hasattr(obj, 'to_json'):
            return obj.to_json()
            
        return super().default(obj)
```
This custom JSON encoder converts database-specific data types to formats that can be serialized to JSON:
- `Decimal` → float (for money values)
- Dates and times → ISO format strings
- `UUID` → string
- Binary data → UTF-8 string
- Sets → lists

```python
# Set the custom encoder on the Flask app
app.json_encoder = CustomJSONEncoder
```
Registers the custom encoder with Flask so it's used for all JSON responses.

```python
CORS(app)
```
Enables Cross-Origin Resource Sharing for all routes, allowing the frontend to make requests to the backend even if they're on different domains.

## Language Model Initialization

```python
# Load sentence transformer model
print("Loading language model...")
model = SentenceTransformer('all-MiniLM-L6-v2')
print("Model loaded successfully!")
```
Loads the sentence transformer model that will convert natural language to numeric vectors. `all-MiniLM-L6-v2` is a lightweight, high-quality model from Hugging Face that creates semantic embeddings of text.

Further reading: https://www.sbert.net/docs/pretrained_models.html

## Database Connection Functions

```python
# Database connection function
def get_db_connection():
    conn = psycopg2.connect(
        host=os.getenv('DB_HOST', 'db'),
        database=os.getenv('DB_NAME', 'retail_db'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'postgres')
    )
    return conn
```
Creates a connection to the PostgreSQL database using environment variables with fallbacks.

```python
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
```
This function introspects the database structure:
1. Connects to the database
2. Gets a list of all tables in the public schema
3. For each table, gets a list of columns and their data types
4. Returns a nested dictionary of table and column information

## Query Templates

```python
# Predefined query templates with natural language descriptions
query_templates = [
    {
        "description": "Show all pending orders",
        "sql": "SELECT o.order_id, c.first_name, c.last_name, o.order_date, o.total_amount FROM orders o JOIN customers c ON o.customer_id = c.customer_id WHERE o.status = 'pending'",
        "parameters": []
    },
    # Additional templates...
]
```
This is a list of query templates, each containing:
- A description in natural language
- The corresponding SQL query
- List of parameters that need to be filled in

These templates are the foundation of the natural language understanding system, allowing the app to match user queries to predefined patterns.

```python
# Create embeddings for all query templates
template_descriptions = [template["description"] for template in query_templates]
template_embeddings = model.encode(template_descriptions)
```
Converts each template description into a numeric vector using the sentence transformer. These embeddings capture the semantic meaning of each template.

## Parameter Extraction

```python
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
```
This function uses regular expressions to extract parameters from the user's query:
1. Normalizes the text (lowercase, remove punctuation)
2. Looks for specific patterns like customer names, product names, prices, etc.
3. Returns the processed query and a dictionary of extracted parameters

## Template Matching

```python
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
```
This function finds the most similar template to the user's query:
1. Converts the user's query to a vector embedding
2. Calculates the similarity between the query and all templates
3. Finds the most similar template
4. If similarity is high enough (>0.5), checks if all required parameters are present
5. Returns the matched template or an error message

Further reading on semantic similarity: https://www.sbert.net/docs/usage/semantic_textual_similarity.html

## Fallback Query Building

```python
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
```
If no template matches, this fallback function builds a simple query:
1. Removes common words ("stopwords")
2. Tries to identify which table the query is about
3. If it can't determine a table, makes an educated guess
4. Builds a simple "SELECT * FROM table" query

## Natural Language to SQL Generation

```python
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
```
This function orchestrates the entire SQL generation process:
1. Extracts parameters from the query
2. Tries to match the query to a template
3. If a match is found, fills in the template with the extracted parameters
4. If no match is found, falls back to the keyword-based approach
5. Returns the generated SQL or an error message

## SQL Execution

```python
# Execute SQL query
def execute_query(sql):
    conn = get_db_connection()
    cursor = conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    
    try:
        print(f"Executing SQL: {sql}")  # Print SQL query for debugging
        cursor.execute(sql)
        results = []
        for row in cursor.fetchall():
            row_dict = dict(row)
            results.append(row_dict)
        return results, None
    except Exception as e:
        return None, f"Error executing query: {str(e)}"
    finally:
        cursor.close()
        conn.close()
```
This function executes the generated SQL:
1. Opens a database connection
2. Executes the query
3. Converts each row to a dictionary
4. Returns the results or an error message
5. Ensures the connection is closed properly with `finally`

## Result Formatting

```python
# Then modify the format_results function to include SQL
def format_results(results, nl_query, sql_query):
    if not results or len(results) == 0:
        return {
            "question": nl_query,
            "sql": sql_query,  # Include SQL query
            "message": "No information available for your query.",
            "data": []
        }
    
    return {
        "question": nl_query,
        "sql": sql_query,  # Include SQL query
        "data": results
    }
```
Formats the query results into a consistent structure that includes:
- The original natural language question
- The generated SQL query (for transparency)
- The query results or a message if no results were found

## API Endpoint

```python
# And in your process_query route, pass the SQL to format_results:
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
    
    # Format and return results - now including SQL
    response = format_results(results, nl_query, sql)
    return jsonify(response)
```
This defines the main API endpoint:
1. Receives a POST request with a JSON body containing a `query` field
2. Validates that a query was provided
3. Gets the database schema
4. Generates SQL from the natural language query
5. Executes the SQL query
6. Formats the results
7. Returns a JSON response

## Application Entry Point

```python
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```
When run directly (not imported), this starts the Flask web server:
- Listens on all network interfaces (`0.0.0.0`)
- Uses port 5000
- In development mode (not for production use)

## Further Reading

1. **Flask Web Framework**: https://flask.palletsprojects.com/
2. **Sentence Transformers**: https://www.sbert.net/
3. **PostgreSQL Python (psycopg2)**: https://www.psycopg.org/docs/
4. **Natural Language Toolkit (NLTK)**: https://www.nltk.org/
5. **Embeddings in NLP**: https://huggingface.co/blog/getting-started-with-embeddings
6. **Cosine Similarity**: https://en.wikipedia.org/wiki/Cosine_similarity

This application demonstrates a powerful technique for creating natural language interfaces to databases, combining template matching with embeddings-based semantic similarity to understand user intent.