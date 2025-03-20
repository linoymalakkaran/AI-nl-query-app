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

# Create template embeddings (called during initialization)
def get_template_descriptions():
    """Extract descriptions from templates"""
    return [template["description"] for template in query_templates]

def get_template_by_index(index):
    """Get a template by its index"""
    return query_templates[index]
