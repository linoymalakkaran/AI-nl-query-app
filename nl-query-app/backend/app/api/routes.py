from flask import Blueprint, request, jsonify
from app.database.schema import get_db_schema
from app.database.connection import execute_query
from app.nlp.extraction import generate_sql

# Create Blueprint
api_bp = Blueprint('api', __name__, url_prefix='/api')

def format_results(results, nl_query, sql_query):
    """Format query results for API response"""
    if not results or len(results) == 0:
        return {
            "question": nl_query,
            "sql": sql_query,
            "message": "No information available for your query.",
            "data": []
        }
    
    return {
        "question": nl_query,
        "sql": sql_query,
        "data": results
    }

@api_bp.route('/query', methods=['POST'])
def process_query():
    """Process natural language query and return results"""
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
    response = format_results(results, nl_query, sql)
    return jsonify(response)
