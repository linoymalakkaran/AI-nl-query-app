import re
import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from app.nlp.embeddings import encode_text, calculate_similarity, get_best_match
from app.nlp.templates import get_template_descriptions, get_template_by_index
from flask import current_app

# Cache for template embeddings
template_embeddings = None

def initialize_template_embeddings(model):
    """Initialize template embeddings"""
    global template_embeddings
    template_descriptions = get_template_descriptions()
    template_embeddings = model.encode(template_descriptions)
    return template_embeddings

def get_template_embeddings():
    """Get template embeddings, initializing if needed"""
    global template_embeddings
    if template_embeddings is None:
        from app.nlp.embeddings import get_model
        model = get_model()
        initialize_template_embeddings(model)
    return template_embeddings

def extract_parameters(query, schema):
    """Extract parameters from a natural language query"""
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

def find_matching_template(query, params):
    """Find the best matching template for a query"""
    # Encode user query
    query_embedding = encode_text(query)
    
    # Get template embeddings
    embeddings = get_template_embeddings()
    
    # Calculate similarity with templates
    similarities = calculate_similarity(query_embedding, embeddings)
    
    # Get best match
    best_match_idx, best_match_score = get_best_match(similarities)
    
    # Check if similarity is high enough
    threshold = current_app.config.get('EMBEDDING_SIMILARITY_THRESHOLD', 0.5)
    if best_match_score > threshold:
        template = get_template_by_index(best_match_idx)
        
        # Check for missing parameters
        missing_params = []
        for param in template["parameters"]:
            if param not in params:
                missing_params.append(param)
        
        if missing_params:
            return None, f"Missing parameters: {', '.join(missing_params)}"
        
        return template, None
    
    return None, "Could not match your query to any known patterns."

def build_keyword_query(processed_query, params, schema):
    """Build a query based on keywords when no template matches"""
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

def generate_sql(nl_query, db_schema):
    """Generate SQL from natural language query"""
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
