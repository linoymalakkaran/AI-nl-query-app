# Natural Language Database Query Application

## Overview

This application allows users to query a database using natural language. It translates English queries into SQL commands and returns formatted results in a user-friendly interface.

## Architecture

The application consists of three main components:

1. **Frontend**: A React web interface for entering queries and viewing results
2. **Backend**: A Flask API that processes natural language and executes database queries
3. **Database**: A PostgreSQL database with sample retail data (customers, products, orders, inventory)

## How It Works

The application follows this workflow:

1. User enters a natural language query in the web interface (e.g., "Show me all pending orders")
2. The frontend sends this query to the backend API
3. The backend identifies the intent and transforms it into a SQL query
4. The SQL query is executed against the PostgreSQL database
5. Results are formatted and returned to the frontend
6. The frontend displays the results in a clean, tabular format

## Key Components

### Frontend (React)
- Simple, intuitive interface with a single input field
- Displays query results in a formatted table
- Handles loading states and error messages

### Backend (Flask)
- REST API that accepts natural language queries
- Pattern matching to identify query intent
- Database connection management
- Error handling and response formatting

### Database (PostgreSQL)
- Contains tables for customers, products, orders, inventory
- Pre-populated with sample retail data
- Structured for common retail operations queries

## Example Queries

The application supports queries like:

- "Show all pending orders"
- "Find orders for customer Smith"
- "List products above $200"
- "Show all products in the Electronics category"
- "Check inventory status"

## Technical Implementation

### Query Processing

The backend uses a simple but effective approach to process natural language:

1. The query is normalized (lowercase, stripped of extra spaces)
2. The application checks if the query matches or contains any predefined patterns
3. If a match is found, it uses the corresponding SQL template
4. If no match is found, it falls back to a default query

This pattern-matching approach works well for demonstration purposes and common query types.

### Database Schema

The database contains these main tables:

- **customers**: Customer information (name, contact details)
- **products**: Product catalog (name, description, price, category)
- **inventory**: Stock information (product, quantity, warehouse)
- **orders**: Order headers (customer, date, status, total)
- **order_items**: Order line items (order, product, quantity, price)

## Endpoints

- **Frontend**: http://localhost
- **Backend API**: http://localhost:5000/api/query
  - Method: POST
  - Content-Type: application/json
  - Body: `{"query": "your natural language query here"}`

## Future Enhancements

This demonstration application could be extended in several ways:

1. **Advanced NLP**: Integrate more sophisticated natural language processing using embeddings or LLMs
2. **Query Builder**: Create a visual query builder alongside the natural language interface
3. **Authentication**: Add user authentication and personalized query history
4. **Export Options**: Allow exporting results in CSV, Excel, or PDF formats
5. **Query Templates**: Save and reuse common queries

## Troubleshooting

If you encounter issues:

- Ensure Docker is running before starting the application
- Check container logs: `docker-compose logs backend`
- Verify database connectivity: `docker-compose exec db psql -U postgres -d retail_db`
- If the backend container fails to build due to network issues, consider using the simplified version with fewer dependencies

## Conclusion

This application demonstrates how natural language interfaces can make databases more accessible to non-technical users. While the current implementation uses a simple pattern-matching approach, it provides a foundation that could be enhanced with more sophisticated NLP techniques.