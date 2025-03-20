#!/bin/bash

# Script to build and run the Natural Language Query Application in Docker

echo "Building and running the Natural Language Query Application..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Error: Docker is not running. Please start Docker Desktop and try again."
  exit 1
fi

# Navigate to the application directory
# Replace this path with your actual application directory path
APP_DIR="nl-query-app"
cd "$APP_DIR" || { echo "Cannot find application directory. Please update the APP_DIR variable in the script."; exit 1; }

# Build and start the Docker containers
echo "Building Docker containers..."
docker-compose build

echo "Starting Docker containers..."
docker-compose up -d

# Wait for containers to be ready
echo "Waiting for application to start..."
sleep 10

# Print access information
echo ""
echo "===== APPLICATION ACCESS INFORMATION ====="
echo "Web Interface: http://localhost"
echo "Backend API: http://localhost:5000/api/query"
echo ""
echo "Example API call:"
echo 'curl -X POST http://localhost:5000/api/query -H "Content-Type: application/json" -d "{\"query\":\"Show all pending orders\"}"'
echo ""
echo "Sample Queries to Try:"
echo "- Show all pending orders"
echo "- Find orders for customer Smith"
echo "- What's the inventory status of laptops?"
echo "- List products that cost more than $200"
echo "- Show me all products in the Electronics category"
echo ""
echo "To stop the application:"
echo "docker-compose down"
echo "====================================="