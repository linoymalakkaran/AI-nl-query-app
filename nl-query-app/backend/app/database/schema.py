from app.database.connection import get_db_connection

def get_db_schema():
    """Get database schema information"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    schema = {}
    try:
        # Get all tables
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
        """)
        tables = cursor.fetchall()
        
        # Get columns for each table
        for table in tables:
            table_name = table[0]
            cursor.execute(f"""
                SELECT column_name, data_type
                FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = '{table_name}'
            """)
            columns = cursor.fetchall()
            schema[table_name] = {col[0]: col[1] for col in columns}
    finally:
        cursor.close()
        conn.close()
    
    return schema
