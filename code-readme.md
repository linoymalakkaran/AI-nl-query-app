# Backend Python Application Code Explanation

This document explains the backend Python application code for the Natural Language Database Query System, breaking down each section to understand its purpose and functionality.

## Core Imports and Setup

```python
from flask import Flask, request, jsonify
from flask_cors import CORS
import psycopg2
import psycopg2.extras
import os
import re
```

- **Flask**: Web framework for creating the API endpoints
- **CORS**: Enables cross-origin resource sharing for frontend access
- **psycopg2**: PostgreSQL adapter for Python
- **os**: Used for environment variable access
- **re**: Regular expressions module for text processing

```python
app = Flask(__name__)
CORS(app)
```
Sets up the Flask application instance and enables CORS for all routes.

## Database Connection Function

```python
def get_db_connection():
    conn = psycopg2.connect(
        host=os.getenv('DB_HOST', 'db'),
        database=os.getenv('DB_NAME', 'retail_db'),
        user=os.getenv('DB_USER', 'postgres'),
        password=os.getenv('DB_PASSWORD', 'postgres')
    )
    return conn
```

This function establishes a connection to the PostgreSQL database:
- Uses environment variables with fallback values
- The Docker service name 'db' is used as the default hostname
- Returns a database connection object

## Query Execution Function

```python
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
```

This function:
1. Creates a connection to the database
2. Executes the provided SQL query
3. Converts results to a list of dictionaries for JSON serialization
4. Handles errors gracefully, returning an error message if needed
5. Ensures connections are properly closed regardless of success or failure

## Results Formatting Function

```python
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
```

This function:
1. Takes the database results and original natural language query
2. Formats them into a consistent response structure
3. Handles the case when no results are found
4. Returns a dictionary that will be converted to JSON

## Main API Endpoint

```python
@app.route('/api/query', methods=['POST'])
def process_query():
    data = request.json
    nl_query = data.get('query', '')
    
    if not nl_query:
        return jsonify({"error": "No query provided"}), 400
```

This section:
1. Defines a POST endpoint at '/api/query'
2. Extracts the natural language query from the JSON request body
3. Returns an error if no query is provided

## Query Mapping and Processing

```python
    # Simple query mapping - for demonstration
    query_map = {
        "show all pending orders": "SELECT o.order_id, c.first_name, c.last_name, o.order_date, o.total_amount FROM orders o JOIN customers c ON o.customer_id = c.customer_id WHERE o.status = 'pending'",
        "find orders for customer smith": "SELECT o.order_id, o.order_date, o.status, o.total_amount FROM orders o JOIN customers c ON o.customer_id = c.customer_id WHERE c.last_name = 'Smith'",
        "list products above 200": "SELECT name, price, category FROM products WHERE price > 200",
        "show all products in electronics category": "SELECT name, price, sku FROM products WHERE category = 'Electronics'",
        "show inventory": "SELECT p.name, i.quantity, i.warehouse FROM products p JOIN inventory i ON p.product_id = i.product_id"
    }
    
    # Simplified query handling
    processed_query = nl_query.lower().strip()
    sql = None
    
    for key, query_sql in query_map.items():
        if key in processed_query or processed_query in key:
            sql = query_sql
            break
    
    if not sql:
        sql = "SELECT * FROM products LIMIT 10"  # Default fallback
```

This section:
1. Defines a dictionary mapping natural language patterns to SQL queries
2. Normalizes the input query (lowercase and trim whitespace)
3. Checks if the processed query matches or contains any of the predefined patterns
4. Selects the corresponding SQL if a match is found
5. Provides a default fallback query if no match is found

## Query Execution and Response

```python
    # Execute the SQL query
    results, error = execute_query(sql)
    if error:
        return jsonify({"error": error}), 400
    
    # Format and return results
    response = format_results(results, nl_query)
    return jsonify(response)
```

This final section:
1. Executes the selected SQL query against the database
2. Returns an error response if the execution fails
3. Formats the results using the format_results function
4. Returns the formatted results as a JSON response

## Application Entry Point

```python
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

This line:
1. Ensures the Flask application only runs when the script is executed directly
2. Binds the server to all network interfaces (0.0.0.0)
3. Sets the port to 5000

## Flow of Execution

When a request comes in:
1. The API endpoint receives a natural language query
2. The query is matched against known patterns
3. The matching SQL query is selected (or a default is used)
4. The SQL is executed against the PostgreSQL database
5. Results are formatted and returned to the client

This simplified implementation demonstrates the core concept of translating natural language to SQL queries without requiring complex NLP models.