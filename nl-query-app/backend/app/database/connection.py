import psycopg2
import psycopg2.extras
from flask import current_app

def get_db_connection():
    """Create and return a database connection"""
    conn = psycopg2.connect(
        host=current_app.config['DB_HOST'],
        database=current_app.config['DB_NAME'],
        user=current_app.config['DB_USER'],
        password=current_app.config['DB_PASSWORD']
    )
    return conn

def execute_query(sql):
    """Execute SQL query and return results"""
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
